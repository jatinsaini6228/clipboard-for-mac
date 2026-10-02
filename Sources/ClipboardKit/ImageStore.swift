import Foundation
import AppKit

/// Manages full-resolution image caching, thumbnail generation, and pasteboard payload generation.
public class ImageStore {
    public static let shared = ImageStore()
    
    private let imagesDirectory: URL
    
    public init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Clipboard", isDirectory: true).appendingPathComponent("Images", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.imagesDirectory = dir
    }
    
    /// Saves high-resolution image data to the local image cache and returns the file path and thumbnail.
    public func saveImage(image: NSImage, id: UUID = UUID()) -> (filePath: String, thumbnailBase64: String?, width: Double, height: Double)? {
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        let filename = "\(id.uuidString).png"
        let fileURL = imagesDirectory.appendingPathComponent(filename)
        
        do {
            try pngData.write(to: fileURL, options: [.atomic])
        } catch {
            print("⚠️ [ImageStore] Failed to write image to disk: \(error)")
            return nil
        }
        
        let width = Double(image.size.width)
        let height = Double(image.size.height)
        let thumbnail = generateThumbnailBase64(image: image, maxDimension: 260)
        
        return (fileURL.path, thumbnail, width, height)
    }
    
    /// Generates a fast base64-encoded thumbnail for SwiftUI list rendering.
    public func generateThumbnailBase64(image: NSImage, maxDimension: CGFloat = 260) -> String? {
        let originalSize = image.size
        guard originalSize.width > 0 && originalSize.height > 0 else { return nil }
        
        let ratio = min(maxDimension / originalSize.width, maxDimension / originalSize.height, 1.0)
        let targetSize = NSSize(width: max(1, originalSize.width * ratio), height: max(1, originalSize.height * ratio))
        
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
    
    /// Loads a full-resolution NSImage from disk path.
    public func loadImage(at path: String) -> NSImage? {
        return NSImage(contentsOfFile: path)
    }
    
    /// Deletes the cached image file from disk.
    public func deleteImage(at path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
    
    /// Writes full-resolution image data to the system pasteboard across all standard formats (PNG, TIFF, File URL).
    public func writeToPasteboard(image: NSImage, filePath: String?, pasteboard: NSPasteboard = .general) {
        pasteboard.clearContents()
        
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            pasteboard.writeObjects([image])
            return
        }
        
        var types: [NSPasteboard.PasteboardType] = [.png, .tiff, .string, PasteboardMonitor.internalPasteboardType]
        if let path = filePath, FileManager.default.fileExists(atPath: path) {
            types.append(.fileURL)
        }
        
        pasteboard.declareTypes(types, owner: nil)
        pasteboard.setData(pngData, forType: .png)
        pasteboard.setData(tiffData, forType: .tiff)
        pasteboard.setString("1", forType: PasteboardMonitor.internalPasteboardType)
        
        if let path = filePath, FileManager.default.fileExists(atPath: path) {
            let fileURL = URL(fileURLWithPath: path)
            pasteboard.setString(fileURL.absoluteString, forType: .string)
            pasteboard.writeObjects([fileURL as NSURL, image])
        } else {
            pasteboard.setString("[Image Content]", forType: .string)
            pasteboard.writeObjects([image])
        }
        
        PasteboardMonitor.shared.markInternalPasteboardChange()
    }
    
    /// Reveals the cached image file in Finder.
    public func revealInFinder(at path: String) {
        guard FileManager.default.fileExists(atPath: path) else { return }
        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
    }
}
