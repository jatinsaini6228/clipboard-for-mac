import Foundation
import Combine

/// Manages thread-safe persistence and querying of clipboard history items.
public class ClipboardStorage: ObservableObject {
    public static let shared = ClipboardStorage()
    
    @Published public private(set) var items: [ClipItem] = []
    
    private let queue = DispatchQueue(label: "com.clipboard.storage.queue", qos: .userInitiated)
    private let fileURL: URL
    public var maxItems: Int = 200
    
    public init(fileURL: URL? = nil) {
        if let customURL = fileURL {
            self.fileURL = customURL
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let dir = appSupport.appendingPathComponent("Clipboard", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.fileURL = dir.appendingPathComponent("history.json")
        }
        load()
    }
    
    /// Loads history from disk.
    public func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoded = try JSONDecoder().decode([ClipItem].self, from: data)
            if Thread.isMainThread {
                self.items = decoded
            } else {
                DispatchQueue.main.sync {
                    self.items = decoded
                }
            }
        } catch {
            print("⚠️ [ClipboardStorage] Failed to decode history: \(error)")
        }
    }
    
    /// Saves current history to disk.
    public func save(synchronous: Bool = false) {
        let currentItems = self.items
        let writeBlock = {
            do {
                let data = try JSONEncoder().encode(currentItems)
                try data.write(to: self.fileURL, options: [.atomic])
            } catch {
                print("⚠️ [ClipboardStorage] Failed to persist history: \(error)")
            }
        }
        
        if synchronous {
            queue.sync(execute: writeBlock)
        } else {
            queue.async(execute: writeBlock)
        }
    }
    
    /// Adds a new item to history. If an unpinned item with the exact same content already exists, it is moved to the top.
    public func addItem(_ item: ClipItem) {
        DispatchQueue.main.async {
            // Deduplicate: if an unpinned item with the same text exists, remove the older occurrence
            if let existingIndex = self.items.firstIndex(where: { $0.text == item.text && !$0.isPinned }) {
                self.items.remove(at: existingIndex)
            }
            
            // Insert at the front
            self.items.insert(item, at: 0)
            
            // Prune unpinned items exceeding maxItems
            self.prune()
            self.save()
        }
    }
    
    /// Prunes excess unpinned items to respect `maxItems`.
    private func prune() {
        guard maxItems > 0 && items.count > maxItems else { return }
        
        var pinnedList: [ClipItem] = []
        var unpinnedList: [ClipItem] = []
        
        for item in items {
            if item.isPinned {
                pinnedList.append(item)
            } else {
                unpinnedList.append(item)
            }
        }
        
        let allowedUnpinned = max(0, maxItems - pinnedList.count)
        let trimmedUnpinned = Array(unpinnedList.prefix(allowedUnpinned))
        
        // Reassemble in timestamp order
        self.items = (pinnedList + trimmedUnpinned).sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    /// Toggles the pinned state of an item.
    public func togglePin(id: UUID) {
        DispatchQueue.main.async {
            if let index = self.items.firstIndex(where: { $0.id == id }) {
                self.items[index].isPinned.toggle()
                self.save()
            }
        }
    }
    
    /// Removes an item by ID.
    public func removeItem(id: UUID) {
        DispatchQueue.main.async {
            self.items.removeAll(where: { $0.id == id })
            self.save()
        }
    }
    
    /// Clears all unpinned history items.
    public func clearHistory(preservePinned: Bool = true) {
        DispatchQueue.main.async {
            if preservePinned {
                self.items.removeAll(where: { !$0.isPinned })
            } else {
                self.items.removeAll()
            }
            self.save()
        }
    }
    
    /// Searches and filters history items.
    public func search(query: String, filter: ClipType) -> [ClipItem] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        return items.filter { item in
            // Filter by type
            let matchesType: Bool
            switch filter {
            case .all:
                matchesType = true
            case .pinned:
                matchesType = item.isPinned
            default:
                matchesType = (item.type == filter)
            }
            
            guard matchesType else { return false }
            
            // Search query matching
            if trimmedQuery.isEmpty {
                return true
            }
            
            if item.text.lowercased().contains(trimmedQuery) {
                return true
            }
            if let lang = item.detectedLanguage, lang.lowercased().contains(trimmedQuery) {
                return true
            }
            if let color = item.hexColor, color.lowercased().contains(trimmedQuery) {
                return true
            }
            if let app = item.sourceAppName, app.lowercased().contains(trimmedQuery) {
                return true
            }
            
            return false
        }
    }
}
