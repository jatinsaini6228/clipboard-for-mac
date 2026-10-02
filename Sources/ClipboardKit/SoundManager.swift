import Foundation
import AppKit

/// Plays subtle macOS system audio cues for user actions.
public struct SoundManager {
    public static var isSoundEnabled: Bool = true
    
    public static func playCopySound() {
        guard isSoundEnabled else { return }
        NSSound(named: "Tink")?.play()
    }
    
    public static func playPasteSound() {
        guard isSoundEnabled else { return }
        NSSound(named: "Pop")?.play()
    }
    
    public static func playPinSound() {
        guard isSoundEnabled else { return }
        NSSound(named: "Morse")?.play()
    }
}
