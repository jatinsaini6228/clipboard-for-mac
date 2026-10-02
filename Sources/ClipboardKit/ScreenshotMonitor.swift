import Foundation
import AppKit

/// Monitors the filesystem for newly taken macOS screenshots, automatically copies them to the system clipboard, and adds them to history.
public class ScreenshotMonitor: ObservableObject {
    public static let shared = ScreenshotMonitor()
    
    @Published public var isEnabled: Bool = true
    
    private let storage: ClipboardStorage
    private let imageStore: ImageStore
    private var timer: Timer?
    private var processedFiles = Set<String>()
    private var monitorStartDate: Date = Date()
    
    public var onScreenshotCaptured: ((ClipItem) -> Void)?
    
    public init(storage: ClipboardStorage = .shared, imageStore: ImageStore = .shared) {
        self.storage = storage
        self.imageStore = imageStore
    }
    
    /// Returns the active macOS screenshot destination folder.
    public static var screenshotDirectory: URL {
        if let customLocation = UserDefaults.standard.persistentDomain(forName: "com.apple.screencapture")?["location"] as? String {
            let expanded = NSString(string: customLocation).expandingTildeInPath
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: expanded, isDirectory: &isDir), isDir.boolValue {
                return URL(fileURLWithPath: expanded, isDirectory: true)
            }
        }
        
        // Default to Desktop
        if let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            return desktop
        }
        
        // Fallback to Documents
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    /// Starts watching the screenshot directory for newly created screenshot files.
    public func start(pollingInterval: TimeInterval = 0.5) {
        stop()
        monitorStartDate = Date()
        
        // Pre-populate existing files so we don't re-ingest past screenshots on launch
        preloadExistingScreenshots()
        
        timer = Timer.scheduledTimer(withTimeInterval: pollingInterval, repeats: true) { [weak self] _ in
            self?.checkScreenshotDirectory()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    /// Stops watching the screenshot directory.
    public func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func preloadExistingScreenshots() {
        let dir = ScreenshotMonitor.screenshotDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return }
        for file in files {
            if isScreenshotFilename(file) {
                processedFiles.insert(file)
            }
        }
    }
    
    /// Checks the directory for any newly written screenshot files.
    public func checkScreenshotDirectory() {
        guard isEnabled else { return }
        
        let dir = ScreenshotMonitor.screenshotDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return }
        
        for file in files {
            guard isScreenshotFilename(file), !processedFiles.contains(file) else { continue }
            
            let fullURL = dir.appendingPathComponent(file)
            
            // Check file attributes (modification date and size)
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: fullURL.path),
                  let modDate = attrs[.modificationDate] as? Date,
                  let size = attrs[.size] as? UInt64,
                  size > 0 else {
                continue
            }
            
            // Ensure the file is not older than when monitoring started (allow 5 sec grace)
            guard modDate.timeIntervalSince(monitorStartDate) >= -5.0 else {
                processedFiles.insert(file)
                continue
            }
            
            // Attempt to load NSImage to verify write completion
            guard let image = NSImage(contentsOf: fullURL), image.size.width > 0 && image.size.height > 0 else {
                // File might still be flushing to disk; retry next tick
                continue
            }
            
            // Successfully verified new screenshot file!
            processedFiles.insert(file)
            ingestScreenshot(image: image, originalURL: fullURL, filename: file)
        }
    }
    
    /// Ingests a screenshot: copies it to the system clipboard and appends to history.
    public func ingestScreenshot(image: NSImage, originalURL: URL, filename: String) {
        let clipId = UUID()
        
        // 1. Save full-resolution image to Clipboard cache
        guard let saved = imageStore.saveImage(image: image, id: clipId) else {
            return
        }
        
        // 2. Immediately copy full high-resolution image to NSPasteboard.general across all formats
        imageStore.writeToPasteboard(image: image, filePath: saved.filePath, pasteboard: .general)
        
        // 3. Create rich ClipItem
        let clip = ClipItem(
            id: clipId,
            text: filename,
            type: .image,
            imageThumbnailBase64: saved.thumbnailBase64,
            imageFilePath: saved.filePath,
            imageWidth: saved.width,
            imageHeight: saved.height,
            sourceAppName: "Screenshot",
            sourceAppBundleId: "com.apple.screencapture"
        )
        
        // 4. Add to storage
        storage.addItem(clip)
        
        // 5. Auditory feedback
        SoundManager.playCopySound()
        
        print("📸 [ScreenshotMonitor] Ingested screenshot and copied to clipboard: \(filename) (\(Int(saved.width))×\(Int(saved.height)))")
        onScreenshotCaptured?(clip)
    }
    
    /// Heuristically identifies macOS screenshot filenames.
    public func isScreenshotFilename(_ filename: String) -> Bool {
        let lower = filename.lowercased()
        
        let validExtensions = [".png", ".jpg", ".jpeg", ".tiff", ".heic", ".webp"]
        guard validExtensions.contains(where: { lower.hasSuffix($0) }) else { return false }
        
        // Standard macOS default names:
        // "Screenshot 2026-10-02 at 6.36.45 PM.png"
        // "Screen Shot 2026-10-02 at 6.36.45 PM.png"
        // "screencapture_..."
        // "Capture d’écran..." (French)
        // "Captura de pantalla..." (Spanish)
        // "Bildschirmfoto..." (German)
        if lower.hasPrefix("screenshot") ||
           lower.hasPrefix("screen shot") ||
           lower.hasPrefix("screencapture") ||
           lower.hasPrefix("capture d’écran") ||
           lower.hasPrefix("captura de pantalla") ||
           lower.hasPrefix("bildschirmfoto") ||
           lower.hasPrefix("schermopname") {
            return true
        }
        
        return false
    }
}
