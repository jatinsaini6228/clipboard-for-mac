import Foundation
import AppKit

/// Represents the detected categorization of clipboard content.
public enum ClipType: String, Codable, CaseIterable {
    case all = "All"
    case text = "Text"
    case code = "Code"
    case url = "Links"
    case color = "Colors"
    case image = "Images"
    case pinned = "Pinned"
    
    public var iconName: String {
        switch self {
        case .all: return "tray.full"
        case .text: return "doc.text"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .url: return "link"
        case .color: return "paintpalette"
        case .image: return "photo"
        case .pinned: return "pin.fill"
        }
    }
}

/// Represents a single clipboard history entry.
public struct ClipItem: Identifiable, Codable, Hashable {
    public let id: UUID
    public var text: String
    public var type: ClipType
    public var detectedLanguage: String?
    public var hexColor: String?
    public var imageThumbnailBase64: String?
    public var imageFilePath: String?
    public var imageWidth: Double?
    public var imageHeight: Double?
    public let timestamp: Date
    public var isPinned: Bool
    public var sourceAppName: String?
    public var sourceAppBundleId: String?
    
    public init(
        id: UUID = UUID(),
        text: String,
        type: ClipType = .text,
        detectedLanguage: String? = nil,
        hexColor: String? = nil,
        imageThumbnailBase64: String? = nil,
        imageFilePath: String? = nil,
        imageWidth: Double? = nil,
        imageHeight: Double? = nil,
        timestamp: Date = Date(),
        isPinned: Bool = false,
        sourceAppName: String? = nil,
        sourceAppBundleId: String? = nil
    ) {
        self.id = id
        self.text = text
        self.type = type
        self.detectedLanguage = detectedLanguage
        self.hexColor = hexColor
        self.imageThumbnailBase64 = imageThumbnailBase64
        self.imageFilePath = imageFilePath
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.sourceAppName = sourceAppName
        self.sourceAppBundleId = sourceAppBundleId
    }
    
    public var characterCount: Int {
        return text.count
    }
    
    public var lineCount: Int {
        let lines = text.split(omittingEmptySubsequences: false, whereSeparator: { $0.isNewline })
        return max(1, lines.count)
    }
    
    public var displayTitle: String {
        if type == .image {
            let label = (sourceAppName?.lowercased().contains("screenshot") == true || text.lowercased().contains("screenshot")) ? "Screenshot" : "Image"
            if let w = imageWidth, let h = imageHeight {
                return "\(label) (\(Int(w)) × \(Int(h)))"
            }
            return "\(label) Asset"
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if let firstLine = trimmed.components(separatedBy: .newlines).first, !firstLine.isEmpty {
            return String(firstLine.prefix(80))
        }
        return "Empty Clip"
    }
    
    public var previewSnippet: String {
        if type == .image {
            return "Visual raster image data"
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let clean = trimmed.replacingOccurrences(of: "\n", with: " ")
        return String(clean.prefix(140))
    }
    
    public var timeAgoFormatted: String {
        let seconds = Int(Date().timeIntervalSince(timestamp))
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours)h ago"
        } else {
            let days = seconds / 86400
            return "\(days)d ago"
        }
    }
}
