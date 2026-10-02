import Foundation
import AppKit
import Combine
import SwiftUI
import ServiceManagement

/// Central observable state coordinator for the application.
public class AppState: ObservableObject {
    public static let shared = AppState()
    
    // Core Services
    public let storage: ClipboardStorage
    public let monitor: PasteboardMonitor
    public let screenshotMonitor: ScreenshotMonitor
    public let hotkeyManager: HotkeyManager
    public let pasteService: PasteService
    
    // UI State
    @Published public var searchQuery: String = ""
    @Published public var selectedFilter: ClipType = .all
    @Published public var selectedClipId: UUID?
    @Published public var hoveredClipId: UUID?
    @Published public var isTrafficHovered: Bool = false
    @Published public var isHUDVisible: Bool = false
    @Published public var isPreferencesVisible: Bool = false
    @Published public var selectedPreferencesTab: Int = 0
    @Published public var isAccessibilityGranted: Bool = PasteService.isAccessibilityTrusted
    @Published public var isWindowExpanded: Bool = false
    
    // User Preferences
    @AppStorage("directPasteEnabled") public var directPasteEnabled: Bool = true
    @AppStorage("isAccessibilityBannerDismissed") public var isAccessibilityBannerDismissed: Bool = false
    @AppStorage("autoCaptureScreenshots") public var autoCaptureScreenshots: Bool = true {
        didSet { screenshotMonitor.isEnabled = autoCaptureScreenshots }
    }
    @AppStorage("soundEnabled") public var soundEnabled: Bool = true {
        didSet { SoundManager.isSoundEnabled = soundEnabled }
    }
    @AppStorage("maxHistoryCount") public var maxHistoryCount: Int = 200 {
        didSet { storage.maxItems = maxHistoryCount }
    }
    @AppStorage("launchAtLogin") public var launchAtLogin: Bool = false {
        didSet { updateLaunchAtLoginStatus() }
    }
    
    public func updateLaunchAtLoginStatus() {
        if #available(macOS 13.0, *) {
            do {
                if launchAtLogin {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("⚠️ [AppState] SMAppService update failed: \(error)")
            }
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        storage: ClipboardStorage = .shared,
        monitor: PasteboardMonitor = .shared,
        screenshotMonitor: ScreenshotMonitor = .shared,
        hotkeyManager: HotkeyManager = .shared,
        pasteService: PasteService = .shared
    ) {
        self.storage = storage
        self.monitor = monitor
        self.screenshotMonitor = screenshotMonitor
        self.hotkeyManager = hotkeyManager
        self.pasteService = pasteService
        
        self.storage.maxItems = maxHistoryCount
        self.screenshotMonitor.isEnabled = autoCaptureScreenshots
        SoundManager.isSoundEnabled = soundEnabled
        
        // Connect monitor and storage
        monitor.start()
        screenshotMonitor.start()
        
        // Listen to storage changes to maintain selected clip
        storage.$items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self = self else { return }
                if self.selectedClipId == nil || !items.contains(where: { $0.id == self.selectedClipId }) {
                    self.selectedClipId = items.first?.id
                }
            }
            .store(in: &cancellables)
            
        // Automatically re-query Accessibility whenever the app gains focus
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshAccessibilityStatus()
        }
    }
    
    /// Filtered items computed based on search query and category filter.
    public var filteredClips: [ClipItem] {
        storage.search(query: searchQuery, filter: selectedFilter)
    }
    
    public var selectedClip: ClipItem? {
        guard let id = selectedClipId else {
            return filteredClips.first
        }
        return filteredClips.first(where: { $0.id == id }) ?? filteredClips.first
    }
    
    // MARK: - Actions
    
    public func selectNext() {
        let clips = filteredClips
        guard !clips.isEmpty else { return }
        
        if let currentId = selectedClipId, let currentIndex = clips.firstIndex(where: { $0.id == currentId }) {
            let nextIndex = min(currentIndex + 1, clips.count - 1)
            selectedClipId = clips[nextIndex].id
        } else {
            selectedClipId = clips.first?.id
        }
    }
    
    public func selectPrevious() {
        let clips = filteredClips
        guard !clips.isEmpty else { return }
        
        if let currentId = selectedClipId, let currentIndex = clips.firstIndex(where: { $0.id == currentId }) {
            let prevIndex = max(currentIndex - 1, 0)
            selectedClipId = clips[prevIndex].id
        } else {
            selectedClipId = clips.first?.id
        }
    }
    
    public func pasteSelected() {
        guard let clip = selectedClip else { return }
        pasteClip(clip)
    }
    
    public func pasteClip(_ clip: ClipItem) {
        SoundManager.playPasteSound()
        hideHUD()
        pasteService.paste(item: clip, directPaste: directPasteEnabled)
    }
    
    public func pasteSelectedImageURL() {
        guard let clip = selectedClip else { return }
        SoundManager.playPasteSound()
        hideHUD()
        pasteService.pasteImageURL(item: clip, directPaste: directPasteEnabled)
    }
    
    public func copySelectedImageURL() {
        guard let clip = selectedClip else { return }
        SoundManager.playCopySound()
        pasteService.pasteImageURL(item: clip, directPaste: false)
        hideHUD()
    }
    
    public func copySelectedWithoutPaste() {
        guard let clip = selectedClip else { return }
        SoundManager.playCopySound()
        pasteService.paste(item: clip, directPaste: false)
        hideHUD()
    }
    
    public func togglePin(id: UUID) {
        SoundManager.playPinSound()
        storage.togglePin(id: id)
    }
    
    public func removeSelected() {
        guard let clip = selectedClip else { return }
        let clips = filteredClips
        if let idx = clips.firstIndex(where: { $0.id == clip.id }) {
            let nextIdx = min(idx + 1, clips.count - 1)
            let fallbackId = (nextIdx != idx && nextIdx < clips.count) ? clips[nextIdx].id : nil
            storage.removeItem(id: clip.id)
            selectedClipId = fallbackId
        } else {
            storage.removeItem(id: clip.id)
        }
    }
    
    public func clearAllHistory() {
        storage.clearHistory(preservePinned: true)
        selectedClipId = nil
    }
    
    public func refreshAccessibilityStatus() {
        let trusted = PasteService.isAccessibilityTrusted
        if isAccessibilityGranted != trusted {
            if Thread.isMainThread {
                self.isAccessibilityGranted = trusted
            } else {
                DispatchQueue.main.async {
                    self.isAccessibilityGranted = trusted
                }
            }
        }
    }
    
    public func showHUD() {
        FloatingHUDWindowController.shared.showWindow()
    }
    
    public func hideHUD() {
        guard isHUDVisible else { return }
        isHUDVisible = false
        searchQuery = ""
        FloatingHUDWindowController.shared.hideWindow()
    }
    
    public func toggleHUD() {
        if isHUDVisible {
            hideHUD()
        } else {
            showHUD()
        }
    }
}
