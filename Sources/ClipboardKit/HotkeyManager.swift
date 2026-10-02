import Foundation
import AppKit
import Carbon

/// Registers and handles system-wide global hotkeys using the Carbon Event Manager.
public class HotkeyManager {
    public static let shared = HotkeyManager()
    
    public var onHotkeyPressed: (() -> Void)?
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    
    public init() {}
    
    /// Registers the default shortcut: Cmd + Shift + V (Keycode 0x09).
    public func registerDefaultHotkey() {
        registerHotkey(keyCode: UInt32(kVK_ANSI_V), carbonModifiers: UInt32(cmdKey | shiftKey))
    }
    
    /// Registers a custom hotkey using Carbon API.
    public func registerHotkey(keyCode: UInt32, carbonModifiers: UInt32) {
        unregisterHotkey()
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x434C4950) // 'CLIP'
        hotKeyID.id = 1
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let handlerBlock: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let event = event, let userData = userData else { return noErr }
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if status == noErr && hotKeyID.id == 1 {
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.onHotkeyPressed?()
                }
            }
            return noErr
        }
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let installStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            handlerBlock,
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )
        
        if installStatus != noErr {
            print("⚠️ [HotkeyManager] Failed to install Carbon event handler: \(installStatus)")
            return
        }
        
        let registerStatus = RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if registerStatus != noErr {
            print("⚠️ [HotkeyManager] Failed to register global hotkey (Status: \(registerStatus))")
        } else {
            print("✅ [HotkeyManager] Global hotkey registered successfully (Cmd + Shift + V)")
        }
    }
    
    /// Unregisters the active hotkey.
    public func unregisterHotkey() {
        if let hotKey = hotKeyRef {
            UnregisterEventHotKey(hotKey)
            hotKeyRef = nil
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
            eventHandlerRef = nil
        }
    }
    
    deinit {
        unregisterHotkey()
    }
}
