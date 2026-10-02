import Foundation
import AppKit
import SwiftUI

/// Manages the macOS Menu Bar status item and its dynamic dropdown menu.
public class StatusBarController: NSObject, NSMenuDelegate {
    public static let shared = StatusBarController()
    
    private var statusItem: NSStatusItem?
    private var preferencesWindow: NSWindow?
    
    public override init() {
        super.init()
    }
    
    public func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem?.button else { return }
        
        // System SF Symbol for clipboard
        if let image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard History") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "📋"
        }
        
        let menu = NSMenu()
        menu.delegate = self
        statusItem?.menu = menu
    }
    
    // MARK: - NSMenuDelegate (Builds dynamic menu on click)
    
    public func menuWillOpen(_ menu: NSMenu) {
        if let current = NSWorkspace.shared.frontmostApplication, PasteService.shared.isExternalApp(current) {
            PasteService.shared.previousFrontmostApp = current
            PasteService.shared.lastActiveExternalApp = current
        }
        
        menu.removeAllItems()
        
        let appState = AppState.shared
        
        // App Title Item
        let titleItem = NSMenuItem(
            title: "Clipboard for Mac (\(appState.storage.items.count) clips)",
            action: nil,
            keyEquivalent: ""
        )
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        
        // Open HUD Item
        let openHUDItem = NSMenuItem(
            title: "Open Search HUD...",
            action: #selector(openHUD),
            keyEquivalent: "V"
        )
        openHUDItem.keyEquivalentModifierMask = [.command, .shift]
        openHUDItem.target = self
        menu.addItem(openHUDItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Recent Clips Submenu / List
        let recentClips = Array(appState.storage.items.prefix(8))
        if recentClips.isEmpty {
            let emptyItem = NSMenuItem(title: "No recent clips", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            let sectionHeader = NSMenuItem(title: "Recent Clips:", action: nil, keyEquivalent: "")
            sectionHeader.isEnabled = false
            menu.addItem(sectionHeader)
            
            for (idx, clip) in recentClips.enumerated() {
                let pinPrefix = clip.isPinned ? "📌 " : ""
                let title = "\(pinPrefix)\(clip.displayTitle)"
                let item = NSMenuItem(title: title, action: #selector(clipMenuItemClicked(_:)), keyEquivalent: idx < 9 ? "\(idx + 1)" : "")
                item.target = self
                item.representedObject = clip
                menu.addItem(item)
            }
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // Pause / Resume Recording
        let isPaused = appState.monitor.isPaused
        let pauseItem = NSMenuItem(
            title: isPaused ? "Resume Recording" : "Pause Recording",
            action: #selector(togglePauseMonitoring),
            keyEquivalent: ""
        )
        pauseItem.target = self
        menu.addItem(pauseItem)
        
        // Clear Unpinned Clips
        let clearItem = NSMenuItem(
            title: "Clear Unpinned History",
            action: #selector(clearHistory),
            keyEquivalent: ""
        )
        clearItem.target = self
        menu.addItem(clearItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Preferences
        let prefsItem = NSMenuItem(
            title: "Preferences...",
            action: #selector(openPreferences),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit Clipboard",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // MARK: - Actions
    
    @objc private func openHUD() {
        FloatingHUDWindowController.shared.showWindow()
    }
    
    @objc private func clipMenuItemClicked(_ sender: NSMenuItem) {
        if let clip = sender.representedObject as? ClipItem {
            AppState.shared.pasteClip(clip)
        }
    }
    
    @objc private func togglePauseMonitoring() {
        AppState.shared.monitor.isPaused.toggle()
    }
    
    @objc private func clearHistory() {
        AppState.shared.clearAllHistory()
    }
    
    @objc public func openPreferences() {
        if preferencesWindow == nil {
            let prefsView = PreferencesView()
            let hosting = NSHostingController(rootView: prefsView)
            
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 380),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window.title = "Clipboard Preferences"
            window.contentViewController = hosting
            window.center()
            window.isReleasedWhenClosed = false
            self.preferencesWindow = window
        }
        
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
