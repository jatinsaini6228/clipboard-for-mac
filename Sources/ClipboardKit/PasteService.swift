import Foundation
import AppKit
import Carbon

/// Handles copying clips back to the system pasteboard and synthesizing direct paste keystrokes into active background apps.
public class PasteService: NSObject {
    public static let shared = PasteService()
    
    /// Tracks the application that was active before the Clipboard HUD was presented.
    public var previousFrontmostApp: NSRunningApplication?
    
    /// The last non-Clipboard active application tracked via NSWorkspace notifications.
    public var lastActiveExternalApp: NSRunningApplication?
    
    public override init() {
        super.init()
        startTrackingActiveApplications()
    }
    
    /// Starts observing application activation across the system.
    private func startTrackingActiveApplications() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(workspaceDidActivateApplication(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        
        // Initial capture of active external application
        if let current = NSWorkspace.shared.frontmostApplication, isExternalApp(current) {
            lastActiveExternalApp = current
            previousFrontmostApp = current
        }
    }
    
    @objc private func workspaceDidActivateApplication(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        if isExternalApp(app) {
            lastActiveExternalApp = app
            previousFrontmostApp = app
        }
    }
    
    /// Determines whether an application is external (not Clipboard itself).
    public func isExternalApp(_ app: NSRunningApplication) -> Bool {
        guard !app.isTerminated else { return false }
        if let bundleId = app.bundleIdentifier, let myBundleId = Bundle.main.bundleIdentifier, bundleId == myBundleId {
            return false
        }
        if app.processIdentifier == NSRunningApplication.current.processIdentifier {
            return false
        }
        return true
    }
    
    /// Resolves the best target application to receive the paste keystroke.
    public var targetApplication: NSRunningApplication? {
        if let app = previousFrontmostApp, isExternalApp(app) {
            return app
        }
        if let app = lastActiveExternalApp, isExternalApp(app) {
            return app
        }
        // Fallback: Find the most recently active non-terminated regular application
        return NSWorkspace.shared.runningApplications.first(where: {
            $0.activationPolicy == .regular && self.isExternalApp($0)
        })
    }
    
    /// Copies the clip item to the general pasteboard and, if enabled & authorized, performs direct paste.
    public func paste(item: ClipItem, directPaste: Bool = true) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        if item.type == .image {
            var fullImage: NSImage?
            if let path = item.imageFilePath, let diskImage = ImageStore.shared.loadImage(at: path) {
                fullImage = diskImage
            } else if let base64 = item.imageThumbnailBase64, let data = Data(base64Encoded: base64) {
                fullImage = NSImage(data: data)
            }
            
            if let image = fullImage {
                ImageStore.shared.writeToPasteboard(image: image, filePath: item.imageFilePath, pasteboard: pasteboard)
            }
        } else {
            pasteboard.declareTypes([.string, PasteboardMonitor.internalPasteboardType], owner: nil)
            pasteboard.setString(item.text, forType: .string)
            pasteboard.setString("1", forType: PasteboardMonitor.internalPasteboardType)
            PasteboardMonitor.shared.markInternalPasteboardChange()
        }
        
        guard directPaste else { return }
        
        performDirectPaste()
    }
    
    /// Specifically pastes the file URL / path of an image clip directly into text inputs.
    public func pasteImageURL(item: ClipItem, directPaste: Bool = true) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        let urlStringToPaste: String
        if let path = item.imageFilePath {
            urlStringToPaste = URL(fileURLWithPath: path).absoluteString
        } else {
            urlStringToPaste = item.text
        }
        
        pasteboard.declareTypes([.string, PasteboardMonitor.internalPasteboardType], owner: nil)
        pasteboard.setString(urlStringToPaste, forType: .string)
        pasteboard.setString("1", forType: PasteboardMonitor.internalPasteboardType)
        PasteboardMonitor.shared.markInternalPasteboardChange()
        
        guard directPaste else { return }
        
        performDirectPaste()
    }
    
    /// Hides HUD, yields focus, activates target application, and dispatches Cmd + V.
    public func performDirectPaste() {
        let target = self.targetApplication
        
        // Hide HUD panel so background application can regain focus
        FloatingHUDWindowController.shared.hideWindow()
        NSApp.deactivate()
        
        if let targetApp = target {
            targetApp.activate(options: [.activateIgnoringOtherApps])
            
            // Allow macOS window server 180ms to switch focus to target application
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                self.simulatePasteKeystroke(for: targetApp)
            }
        } else {
            // No specific app reference found; yield focus and attempt session paste
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                self.simulatePasteKeystroke(for: nil)
            }
        }
    }
    
    /// Synthesizes a Command + V keystroke using Quartz CoreGraphics events or resilient AppleScript fallback.
    public func simulatePasteKeystroke(for targetApp: NSRunningApplication? = nil) {
        let isTrusted = PasteService.isAccessibilityTrusted
        var postedViaCGEvent = false
        
        if isTrusted {
            let vKeyCode: CGKeyCode = 0x09 // Virtual key code for 'V' (ANSI)
            if let source = CGEventSource(stateID: .combinedSessionState),
               let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
               let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) {
                keyDown.flags = .maskCommand
                keyUp.flags = .maskCommand
                keyDown.post(tap: .cgSessionEventTap)
                keyUp.post(tap: .cgSessionEventTap)
                postedViaCGEvent = true
            }
        }
        
        // If not trusted via Quartz Accessibility, or if CGEvent could not be dispatched,
        // execute AppleScript via System Events which can dispatch keystrokes reliably.
        if !postedViaCGEvent {
            DispatchQueue.global(qos: .userInitiated).async {
                let scriptSource: String
                if let app = targetApp, !app.isTerminated {
                    let pid = app.processIdentifier
                    scriptSource = """
                    tell application "System Events"
                        try
                            set frontmost of (first process whose unix id is \(pid)) to true
                        end try
                        keystroke "v" using command down
                    end tell
                    """
                } else {
                    scriptSource = """
                    tell application "System Events"
                        keystroke "v" using command down
                    end tell
                    """
                }
                
                if let script = NSAppleScript(source: scriptSource) {
                    var errorInfo: NSDictionary?
                    script.executeAndReturnError(&errorInfo)
                    if let err = errorInfo {
                        print("⚠️ [PasteService] AppleScript paste dispatch notice: \(err)")
                    }
                }
            }
        }
    }
    
    /// Checks if the process has macOS Accessibility permissions for synthetic keystrokes.
    public static var isAccessibilityTrusted: Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// Prompts the system Accessibility prompt if not currently trusted.
    public static func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    /// Opens the macOS System Settings directly to Privacy & Security -> Accessibility.
    public static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
