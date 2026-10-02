import Foundation
import AppKit

/// Monitors the macOS system pasteboard for changes with ultra-low CPU overhead.
public class PasteboardMonitor: ObservableObject {
    public static let shared = PasteboardMonitor()
    
    @Published public var isPaused: Bool = false
    
    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let storage: ClipboardStorage
    
    public static let internalPasteboardType = NSPasteboard.PasteboardType("com.clipboard.mac.internal")
    
    public var onNewClipCaptured: ((ClipItem) -> Void)?
    
    public init(storage: ClipboardStorage = .shared) {
        self.storage = storage
        self.lastChangeCount = pasteboard.changeCount
    }
    
    /// Advance the tracked changeCount so self-initiated pasteboard modifications are ignored.
    public func markInternalPasteboardChange() {
        lastChangeCount = pasteboard.changeCount
    }
    
    /// Starts background polling.
    public func start(interval: TimeInterval = 0.35) {
        stop()
        lastChangeCount = pasteboard.changeCount
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    /// Stops background polling.
    public func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    /// Polls the pasteboard and captures changes.
    public func checkPasteboard() {
        guard !isPaused else { return }
        
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount
        
        // 0. Ignore self-initiated pasteboard writes tagged with our internal marker
        if pasteboard.types?.contains(PasteboardMonitor.internalPasteboardType) == true {
            return
        }
        
        // Identify source frontmost application
        let frontApp = NSWorkspace.shared.frontmostApplication
        let sourceName = frontApp?.localizedName
        let sourceBundleId = frontApp?.bundleIdentifier
        
        // Exclude own app copies
        if let myId = Bundle.main.bundleIdentifier, sourceBundleId == myId {
            return
        }
        
        // 1. Sensitive Data Check
        if SensitiveDataFilter.shouldIgnore(pasteboard: pasteboard, sourceBundleId: sourceBundleId) {
            return
        }
        
        // 2. Check for Textual Content
        if let stringContent = pasteboard.string(forType: .string), !stringContent.isEmpty {
            if SensitiveDataFilter.containsHighRiskSecret(text: stringContent) {
                return
            }
            
            let classification = ContentTypeClassifier.classify(text: stringContent)
            
            let clip = ClipItem(
                text: stringContent,
                type: classification.type,
                detectedLanguage: classification.language,
                hexColor: classification.hexColor,
                sourceAppName: sourceName,
                sourceAppBundleId: sourceBundleId
            )
            
            storage.addItem(clip)
            onNewClipCaptured?(clip)
            return
        }
        
        // 3. Check for Image Content
        if let imageTypes = pasteboard.types, imageTypes.contains(.tiff) || imageTypes.contains(.png) {
            if let imageData = pasteboard.data(forType: .tiff) ?? pasteboard.data(forType: .png) {
                if let image = NSImage(data: imageData) {
                    let clipId = UUID()
                    let isScreenshot = (sourceBundleId == "com.apple.screencapture" || sourceName?.lowercased().contains("screenshot") == true)
                    let title = isScreenshot ? "Screenshot" : "Copied Image"
                    
                    if let saved = ImageStore.shared.saveImage(image: image, id: clipId) {
                        let clip = ClipItem(
                            id: clipId,
                            text: title,
                            type: .image,
                            imageThumbnailBase64: saved.thumbnailBase64,
                            imageFilePath: saved.filePath,
                            imageWidth: saved.width,
                            imageHeight: saved.height,
                            sourceAppName: isScreenshot ? "Screenshot" : sourceName,
                            sourceAppBundleId: sourceBundleId
                        )
                        
                        storage.addItem(clip)
                        onNewClipCaptured?(clip)
                        return
                    }
                }
            }
        }
    }
    
    private func generateThumbnailBase64(image: NSImage, maxDimension: CGFloat = 240) -> String? {
        let originalSize = image.size
        guard originalSize.width > 0 && originalSize.height > 0 else { return nil }
        
        let ratio = min(maxDimension / originalSize.width, maxDimension / originalSize.height, 1.0)
        let targetSize = NSSize(width: originalSize.width * ratio, height: originalSize.height * ratio)
        
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: targetSize),
                   from: NSRect(origin: .zero, size: originalSize),
                   operation: .copy,
                   fraction: 1.0)
        newImage.unlockFocus()
        
        guard let tiffData = newImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        return pngData.base64EncodedString()
    }
}
