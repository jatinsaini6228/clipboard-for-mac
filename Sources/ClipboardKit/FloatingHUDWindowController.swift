import Foundation
import AppKit
import SwiftUI

/// Manages the floating, non-activating HUD window panel.
public class FloatingHUDWindowController: NSObject, NSWindowDelegate {
    public static let shared = FloatingHUDWindowController()
    
    private var window: NSPanel?
    private var localEventMonitor: Any?
    
    public override init() {
        super.init()
    }
    
    public func showWindow() {
        if window == nil {
            setupWindow()
        }
        
        guard let panel = window else { return }
        
        // 1. Capture prior frontmost application BEFORE activating Clipboard
        let currentFront = NSWorkspace.shared.frontmostApplication
        if let current = currentFront, PasteService.shared.isExternalApp(current) {
            PasteService.shared.previousFrontmostApp = current
        } else if PasteService.shared.previousFrontmostApp == nil {
            PasteService.shared.previousFrontmostApp = PasteService.shared.lastActiveExternalApp
        }
        
        // 2. Synchronize AppState & Accessibility status
        AppState.shared.refreshAccessibilityStatus()
        AppState.shared.isHUDVisible = true
        
        // 3. Position panel at center of active mouse display
        positionWindowOnActiveScreen(panel)
        
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        installKeyboardMonitor()
    }
    
    public func hideWindow() {
        guard window?.isVisible == true else { return }
        window?.orderOut(nil)
        removeKeyboardMonitor()
        AppState.shared.hideHUD()
    }
    
    public func toggleWindow() {
        if window?.isVisible == true {
            hideWindow()
        } else {
            showWindow()
        }
    }
    
    public func minimizeWindow() {
        hideWindow()
    }
    
    public func toggleZoom() {
        guard let panel = window else { return }
        let currentSize = panel.frame.size
        let isExpanded = currentSize.width > 1050
        
        let targetWidth: CGFloat = isExpanded ? 980 : 1180
        let targetHeight: CGFloat = isExpanded ? 680 : 820
        
        let newOrigin = NSPoint(
            x: panel.frame.origin.x - ((targetWidth - currentSize.width) / 2),
            y: panel.frame.origin.y - ((targetHeight - currentSize.height) / 2)
        )
        
        let newFrame = NSRect(origin: newOrigin, size: NSSize(width: targetWidth, height: targetHeight))
        panel.setFrame(newFrame, display: true, animate: true)
        AppState.shared.isWindowExpanded = !isExpanded
        UserDefaults.standard.set(targetWidth, forKey: "savedHUDWidth")
        UserDefaults.standard.set(targetHeight, forKey: "savedHUDHeight")
    }
    
    public func quitApp() {
        AppState.shared.storage.save(synchronous: true)
        NSApp.terminate(nil)
    }
    
    private func setupWindow() {
        let hudView = HUDView()
        let hostingController = NSHostingController(rootView: hudView)
        
        let defaultWidth: CGFloat = 980
        let defaultHeight: CGFloat = 680
        let savedWidth = UserDefaults.standard.double(forKey: "savedHUDWidth")
        let savedHeight = UserDefaults.standard.double(forKey: "savedHUDHeight")
        let initialWidth: CGFloat = savedWidth >= 860 ? CGFloat(savedWidth) : defaultWidth
        let initialHeight: CGFloat = savedHeight >= 600 ? CGFloat(savedHeight) : defaultHeight
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: initialWidth, height: initialHeight),
            styleMask: [.borderless, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovable = true
        panel.isMovableByWindowBackground = true
        panel.showsResizeIndicator = true
        panel.minSize = NSSize(width: 860, height: 600)
        panel.maxSize = NSSize(width: 1440, height: 1000)
        panel.contentViewController = hostingController
        panel.delegate = self
        
        self.window = panel
    }
    
    private func positionWindowOnActiveScreen(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let screens = NSScreen.screens
        let activeScreen = screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main
        
        if let screen = activeScreen {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - (panel.frame.width / 2)
            let y = screenFrame.midY - (panel.frame.height / 2) + 40
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    private func installKeyboardMonitor() {
        removeKeyboardMonitor()
        
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            // Escape key -> Dismiss
            if event.keyCode == 53 { // ESC
                self.hideWindow()
                return nil
            }
            
            // Down Arrow
            if event.keyCode == 125 {
                AppState.shared.selectNext()
                return nil
            }
            
            // Up Arrow
            if event.keyCode == 126 {
                AppState.shared.selectPrevious()
                return nil
            }
            
            // Page Down -> Jump 5
            if event.keyCode == 121 {
                for _ in 0..<5 { AppState.shared.selectNext() }
                return nil
            }
            
            // Page Up -> Jump 5
            if event.keyCode == 116 {
                for _ in 0..<5 { AppState.shared.selectPrevious() }
                return nil
            }
            
            // Return / Enter -> Paste
            if event.keyCode == 36 {
                AppState.shared.pasteSelected()
                return nil
            }
            
            // Command key combos
            if event.modifierFlags.contains(.command) {
                if let chars = event.charactersIgnoringModifiers?.lowercased() {
                    switch chars {
                    case "1":
                        AppState.shared.selectedFilter = .all
                        return nil
                    case "2":
                        AppState.shared.selectedFilter = .text
                        return nil
                    case "3":
                        AppState.shared.selectedFilter = .code
                        return nil
                    case "4":
                        AppState.shared.selectedFilter = .url
                        return nil
                    case "5":
                        AppState.shared.selectedFilter = .color
                        return nil
                    case "6":
                        AppState.shared.selectedFilter = .image
                        return nil
                    case "7":
                        AppState.shared.selectedFilter = .pinned
                        return nil
                    case "p":
                        if let selected = AppState.shared.selectedClip {
                            AppState.shared.togglePin(id: selected.id)
                        }
                        return nil
                    case "c":
                        AppState.shared.copySelectedWithoutPaste()
                        return nil
                    default:
                        break
                    }
                }
                
                // Cmd + Backspace (51) or Forward Delete (117) -> Remove item
                if event.keyCode == 51 || event.keyCode == 117 {
                    AppState.shared.removeSelected()
                    return nil
                }
            }
            
            return event
        }
    }
    
    private func removeKeyboardMonitor() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }
    
    // NSWindowDelegate
    public func windowDidResize(_ notification: Notification) {
        guard let panel = window else { return }
        let size = panel.frame.size
        if size.width >= 860 && size.height >= 600 {
            UserDefaults.standard.set(size.width, forKey: "savedHUDWidth")
            UserDefaults.standard.set(size.height, forKey: "savedHUDHeight")
        }
    }
    
    public func windowDidBecomeKey(_ notification: Notification) {
        AppState.shared.refreshAccessibilityStatus()
    }
    
    public func windowDidResignKey(_ notification: Notification) {
        // Automatically hide when user clicks away
        hideWindow()
    }
}
