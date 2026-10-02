import Foundation
import AppKit

/// Standard AppKit application delegate for Clipboard.
public class AppDelegate: NSObject, NSApplicationDelegate {
    
    public override init() {
        super.init()
    }
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize AppState and dependencies
        _ = AppState.shared
        
        // Setup Menu Bar Status Item
        StatusBarController.shared.setupStatusBar()
        
        // Setup Global Hotkey (Cmd + Shift + V)
        HotkeyManager.shared.onHotkeyPressed = {
            FloatingHUDWindowController.shared.toggleWindow()
        }
        HotkeyManager.shared.registerDefaultHotkey()
        
        print("🚀 [Clipboard] Application initialized successfully.")
    }
    
    public func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.host == "open" || url.host == "toggle" || url.path.contains("open") || url.path.contains("toggle") {
                FloatingHUDWindowController.shared.showWindow()
            }
        }
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregisterHotkey()
        AppState.shared.monitor.stop()
        AppState.shared.screenshotMonitor.stop()
        AppState.shared.storage.save(synchronous: true)
        print("👋 [Clipboard] Application terminated cleanly.")
    }
}
