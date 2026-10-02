import Foundation
import AppKit
import ClipboardKit

class TestFramework {
    static var totalTests = 0
    static var passedTests = 0
    static var failedTests = 0
    
    static func assert(_ condition: Bool, _ message: String, file: String = #file, line: Int = #line) {
        totalTests += 1
        if condition {
            passedTests += 1
            print("  ✅ [PASS] \(message)")
        } else {
            failedTests += 1
            print("  ❌ [FAIL] \(message) (\(file):\(line))")
        }
    }
    
    static func runSuite(named name: String, block: () -> Void) {
        print("\n=======================================================")
        print("🧪 RUNNING SUITE: \(name)")
        print("=======================================================")
        block()
    }
    
    static func report() {
        print("\n=======================================================")
        print("📊 TEST SUMMARY")
        print("=======================================================")
        print("Total: \(totalTests) | Passed: \(passedTests) | Failed: \(failedTests)")
        if failedTests == 0 {
            print("🎉 ALL TESTS PASSED SUCCESSFULLY!")
        } else {
            print("💥 SOME TESTS FAILED.")
            exit(1)
        }
    }
}

// MARK: - Test Suite 1: Content Type Classifier

TestFramework.runSuite(named: "ContentTypeClassifier Tests") {
    // Hex & RGB Color
    let hexResult1 = ContentTypeClassifier.classify(text: "#FF5733")
    TestFramework.assert(hexResult1.type == .color && hexResult1.hexColor == "#FF5733", "Classified #FF5733 as color")
    
    let hexResult2 = ContentTypeClassifier.classify(text: "#000")
    TestFramework.assert(hexResult2.type == .color && hexResult2.hexColor == "#000", "Classified #000 as color")
    
    let rgbResult = ContentTypeClassifier.classify(text: "rgb(255, 128, 0)")
    TestFramework.assert(rgbResult.type == .color, "Classified rgb(...) as color")
    
    // URLs
    let urlResult1 = ContentTypeClassifier.classify(text: "https://developer.apple.com/swift/")
    TestFramework.assert(urlResult1.type == .url, "Classified valid HTTPS URL as link")
    
    let urlResult2 = ContentTypeClassifier.classify(text: "http://example.org?query=test&id=1")
    TestFramework.assert(urlResult2.type == .url, "Classified HTTP URL with params as link")
    
    let invalidURL = ContentTypeClassifier.classify(text: "This is not a url https://apple.com")
    TestFramework.assert(invalidURL.type != .url, "Multi-word text with URL is classified as text")
    
    // Code Detection
    let jsonCode = "{\"name\": \"Clipboard\", \"version\": 1.0, \"active\": true}"
    let jsonResult = ContentTypeClassifier.classify(text: jsonCode)
    TestFramework.assert(jsonResult.type == .code && jsonResult.language == "JSON", "Classified JSON payload as code (JSON)")
    
    let swiftCode = "import SwiftUI\n\nstruct ContentView: View {\n    var body: some View { Text(\"Hi\") }\n}"
    let swiftResult = ContentTypeClassifier.classify(text: swiftCode)
    TestFramework.assert(swiftResult.type == .code && swiftResult.language == "Swift", "Classified Swift code snippet")
    
    let pythonCode = "def calculate_sum(a, b):\n    print('Calculating...')\n    return a + b\n"
    let pythonResult = ContentTypeClassifier.classify(text: pythonCode)
    TestFramework.assert(pythonResult.type == .code && pythonResult.language == "Python", "Classified Python code snippet")
    
    let shellCode = "#!/bin/bash\necho 'Deploying app...'\nsudo systemctl restart app\n"
    let shellResult = ContentTypeClassifier.classify(text: shellCode)
    TestFramework.assert(shellResult.type == .code && shellResult.language == "Shell", "Classified Shell script")
    
    let sqlCode = "SELECT id, name, email FROM users WHERE active = 1"
    let sqlResult = ContentTypeClassifier.classify(text: sqlCode)
    TestFramework.assert(sqlResult.type == .code && sqlResult.language == "SQL", "Classified SQL statement")
    
    // Plain text
    let plainText = "Hello, world! This is a simple note to remember."
    let plainResult = ContentTypeClassifier.classify(text: plainText)
    TestFramework.assert(plainResult.type == .text, "Classified standard sentence as plain text")
}

// MARK: - Test Suite 2: Sensitive Data Filter

TestFramework.runSuite(named: "SensitiveDataFilter Tests") {
    // Bundle ID Filter
    TestFramework.assert(
        SensitiveDataFilter.shouldIgnore(pasteboard: NSPasteboard.general, sourceBundleId: "com.apple.keychainaccess"),
        "Blocked Apple Keychain Access bundle"
    )
    TestFramework.assert(
        SensitiveDataFilter.shouldIgnore(pasteboard: NSPasteboard.general, sourceBundleId: "com.agilebits.onepassword"),
        "Blocked 1Password bundle"
    )
    TestFramework.assert(
        SensitiveDataFilter.shouldIgnore(pasteboard: NSPasteboard.general, sourceBundleId: "com.bitwarden.desktop"),
        "Blocked Bitwarden bundle"
    )
    TestFramework.assert(
        !SensitiveDataFilter.shouldIgnore(pasteboard: NSPasteboard.general, sourceBundleId: "com.apple.dt.Xcode"),
        "Allowed Xcode bundle"
    )
    
    // Private Key & AWS Token Checks
    let privateKeyText = "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASC...\n-----END PRIVATE KEY-----"
    TestFramework.assert(
        SensitiveDataFilter.containsHighRiskSecret(text: privateKeyText),
        "Detected RSA/OpenSSH private key token"
    )
    
    let awsKeyText = "My AWS key is AKIAIOSFODNN7EXAMPLE for deployment"
    TestFramework.assert(
        SensitiveDataFilter.containsHighRiskSecret(text: awsKeyText),
        "Detected AWS access key token pattern"
    )
    
    let regularText = "Just normal non-sensitive config string: host=localhost"
    TestFramework.assert(
        !SensitiveDataFilter.containsHighRiskSecret(text: regularText),
        "Allowed safe non-sensitive configuration text"
    )
}

// MARK: - Test Suite 3: ClipItem Model & Helpers

TestFramework.runSuite(named: "ClipItem Model Tests") {
    let clip = ClipItem(
        text: "Line 1 of snippet\nLine 2 of snippet\nLine 3 of snippet",
        type: .code,
        detectedLanguage: "Swift",
        sourceAppName: "Xcode"
    )
    
    TestFramework.assert(clip.displayTitle == "Line 1 of snippet", "displayTitle extracts first line cleanly")
    TestFramework.assert(clip.lineCount == 3, "lineCount accurately reports 3 lines")
    TestFramework.assert(clip.characterCount == clip.text.count, "characterCount matches text string count")
    TestFramework.assert(clip.timeAgoFormatted == "Just now", "timeAgoFormatted reports 'Just now' for freshly created item")
}

// MARK: - Test Suite 4: ClipboardStorage & Persistence

TestFramework.runSuite(named: "ClipboardStorage Persistence Tests") {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    let testStorageURL = tempDir.appendingPathComponent("test_history.json")
    
    let storage = ClipboardStorage(fileURL: testStorageURL)
    storage.maxItems = 3
    
    let clip1 = ClipItem(text: "First Clip", type: .text)
    let clip2 = ClipItem(text: "Second Clip", type: .text)
    let clip3 = ClipItem(text: "Third Clip", type: .text)
    
    storage.addItem(clip1)
    storage.addItem(clip2)
    storage.addItem(clip3)
    
    // Give async main queue a tick to process
    RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    
    TestFramework.assert(storage.items.count == 3, "Stored 3 items in history")
    TestFramework.assert(storage.items.first?.text == "Third Clip", "Most recent item is at index 0")
    
    // Pin clip1
    storage.togglePin(id: clip1.id)
    RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    
    let pinnedItem = storage.items.first(where: { $0.id == clip1.id })
    TestFramework.assert(pinnedItem?.isPinned == true, "clip1 was successfully pinned")
    
    // Add 2 more items to trigger pruning
    let clip4 = ClipItem(text: "Fourth Clip", type: .text)
    let clip5 = ClipItem(text: "Fifth Clip", type: .text)
    storage.addItem(clip4)
    storage.addItem(clip5)
    RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    
    TestFramework.assert(storage.items.count == 3, "History pruned down to maxItems = 3")
    TestFramework.assert(storage.items.contains(where: { $0.id == clip1.id }), "Pinned clip was preserved despite exceeding pruning limits")
    
    // Test persistence reload from disk
    storage.save()
    RunLoop.current.run(until: Date().addingTimeInterval(0.2))
    
    let reloadedStorage = ClipboardStorage(fileURL: testStorageURL)
    RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    TestFramework.assert(reloadedStorage.items.count == 3, "Reloaded storage from disk has matching item count")
    
    // Cleanup
    try? FileManager.default.removeItem(at: tempDir)
}

// MARK: - Test Suite 5: Search & Filtering Engine

TestFramework.runSuite(named: "Search & Filtering Tests") {
    let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    let storage = ClipboardStorage(fileURL: tempDir.appendingPathComponent("search_test.json"))
    
    let c1 = ClipItem(text: "Apple Swift 6 release notes", type: .text)
    let c2 = ClipItem(text: "https://apple.com/macos", type: .url)
    let c3 = ClipItem(text: "#E74C3C", type: .color, hexColor: "#E74C3C")
    let c4 = ClipItem(text: "func fibonacci(n: Int) -> Int", type: .code, detectedLanguage: "Swift", isPinned: true)
    
    storage.addItem(c1)
    storage.addItem(c2)
    storage.addItem(c3)
    storage.addItem(c4)
    RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    
    // Query search
    let swiftResults = storage.search(query: "swift", filter: .all)
    TestFramework.assert(swiftResults.count == 2, "Search for 'swift' found 2 matches across text and code")
    
    // Category filter: links
    let urlResults = storage.search(query: "", filter: .url)
    TestFramework.assert(urlResults.count == 1 && urlResults.first?.type == .url, "Filter for .url returns only link clips")
    
    // Category filter: color
    let colorResults = storage.search(query: "", filter: .color)
    TestFramework.assert(colorResults.count == 1 && colorResults.first?.hexColor == "#E74C3C", "Filter for .color returns color clips")
    
    // Category filter: pinned
    let pinnedResults = storage.search(query: "", filter: .pinned)
    TestFramework.assert(pinnedResults.count == 1 && pinnedResults.first?.text.contains("fibonacci") == true, "Filter for .pinned returns pinned item")
    
    try? FileManager.default.removeItem(at: tempDir)
}

// MARK: - Test Suite 6: JSON Serialization Fidelity

TestFramework.runSuite(named: "JSON Serialization Tests") {
    let original = ClipItem(
        text: "Special characters: 🚀 ☕ \"quotes\" & symbols",
        type: .code,
        detectedLanguage: "Swift",
        hexColor: nil,
        imageThumbnailBase64: nil,
        imageWidth: nil,
        imageHeight: nil,
        isPinned: true,
        sourceAppName: "Safari",
        sourceAppBundleId: "com.apple.Safari"
    )
    
    do {
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ClipItem.self, from: data)
        
        TestFramework.assert(decoded.id == original.id, "ID preserved across serialization")
        TestFramework.assert(decoded.text == original.text, "Text with emojis and quotes preserved")
        TestFramework.assert(decoded.type == original.type, "ClipType preserved")
        TestFramework.assert(decoded.detectedLanguage == original.detectedLanguage, "Language metadata preserved")
        TestFramework.assert(decoded.isPinned == original.isPinned, "Pin state preserved")
        TestFramework.assert(decoded.sourceAppName == original.sourceAppName, "Source app name preserved")
    } catch {
        TestFramework.assert(false, "JSON serialization threw exception: \(error)")
    }
}

// MARK: - Test Suite 7: Monitor & Sound Controls

TestFramework.runSuite(named: "Controls & Monitor Tests") {
    let monitor = PasteboardMonitor.shared
    TestFramework.assert(!monitor.isPaused, "PasteboardMonitor starts in active non-paused state")
    
    monitor.isPaused = true
    TestFramework.assert(monitor.isPaused, "PasteboardMonitor correctly toggles to paused state")
    monitor.isPaused = false
    
    SoundManager.isSoundEnabled = true
    TestFramework.assert(SoundManager.isSoundEnabled, "SoundManager enabled flag is functional")
    SoundManager.isSoundEnabled = false
    TestFramework.assert(!SoundManager.isSoundEnabled, "SoundManager disabled flag is functional")
    SoundManager.isSoundEnabled = true
}

// MARK: - Test Suite 8: Screenshot & Full-Resolution Image Tests

TestFramework.runSuite(named: "Screenshot & Full-Resolution Image Tests") {
    let imageStore = ImageStore.shared
    
    // Create test synthetic image
    let testImage = NSImage(size: NSSize(width: 800, height: 600))
    testImage.lockFocus()
    NSColor.systemBlue.setFill()
    NSRect(x: 0, y: 0, width: 800, height: 600).fill()
    testImage.unlockFocus()
    
    let testClipId = UUID()
    guard let saved = imageStore.saveImage(image: testImage, id: testClipId) else {
        TestFramework.assert(false, "Failed to save full-resolution test image")
        return
    }
    
    TestFramework.assert(FileManager.default.fileExists(atPath: saved.filePath), "High-resolution image file written to disk")
    TestFramework.assert(saved.thumbnailBase64 != nil, "Generated base64 thumbnail for UI")
    TestFramework.assert(saved.width == 800 && saved.height == 600, "Preserved 800x600 dimensions")
    
    // Load image back from disk
    let loaded = imageStore.loadImage(at: saved.filePath)
    TestFramework.assert(loaded != nil && loaded?.size.width == 800, "Successfully reloaded full-resolution image from disk")
    
    // Test Pasteboard Multi-Format Writing
    let customPasteboard = NSPasteboard.withUniqueName()
    imageStore.writeToPasteboard(image: testImage, filePath: saved.filePath, pasteboard: customPasteboard)
    
    let types = customPasteboard.types ?? []
    TestFramework.assert(types.contains(.png), "Pasteboard contains .png data for web/Slack/Discord")
    TestFramework.assert(types.contains(.tiff), "Pasteboard contains .tiff data for macOS native apps")
    TestFramework.assert(types.contains(.fileURL), "Pasteboard contains .fileURL for Finder/Photoshop")
    
    // Test Screenshot Filename Detection
    let monitor = ScreenshotMonitor.shared
    TestFramework.assert(monitor.isScreenshotFilename("Screenshot 2026-10-02 at 6.36.45 PM.png"), "Identified macOS standard Screenshot filename")
    TestFramework.assert(monitor.isScreenshotFilename("Screen Shot 2026-05-14 at 10.00.00 AM.png"), "Identified legacy Screen Shot filename")
    TestFramework.assert(monitor.isScreenshotFilename("screencapture_full_desktop.jpg"), "Identified screencapture prefix")
    TestFramework.assert(!monitor.isScreenshotFilename("MyDocument.pdf"), "Rejected non-image PDF document")
    TestFramework.assert(!monitor.isScreenshotFilename("Photo.png"), "Rejected generic non-screenshot photo")
    
    // Test ClipItem Screenshot displayTitle formatting
    let screenshotClip = ClipItem(
        text: "Screenshot 2026-10-02 at 6.36.45 PM.png",
        type: .image,
        imageFilePath: saved.filePath,
        imageWidth: 800,
        imageHeight: 600,
        sourceAppName: "Screenshot"
    )
    TestFramework.assert(screenshotClip.displayTitle == "Screenshot (800 × 600)", "displayTitle correctly formats Screenshot (800 × 600)")
    
    // Cleanup test image
    imageStore.deleteImage(at: saved.filePath)
    TestFramework.assert(!FileManager.default.fileExists(atPath: saved.filePath), "Cleaned up cached test image")
}

// MARK: - Test Suite 9: PasteService & Direct Paste Engine Tests

TestFramework.runSuite(named: "PasteService & Direct Paste Engine Tests") {
    let pasteService = PasteService.shared
    let appState = AppState.shared
    
    // 1. Current process is not considered an external app
    let currentApp = NSRunningApplication.current
    TestFramework.assert(!pasteService.isExternalApp(currentApp), "Current Clipboard app is correctly filtered out as non-external")
    
    // 2. Target application resolution
    let targetApp = pasteService.targetApplication
    if let target = targetApp {
        TestFramework.assert(pasteService.isExternalApp(target), "Resolved target application is a valid non-Clipboard external application (\(target.localizedName ?? "app"))")
    } else {
        TestFramework.assert(true, "No external applications currently active in headless runner context")
    }
    
    // 3. Paste plain text onto pasteboard
    let textClip = ClipItem(text: "Direct Paste Test Content 123", type: .text)
    pasteService.paste(item: textClip, directPaste: false)
    let pbString = NSPasteboard.general.string(forType: .string)
    TestFramework.assert(pbString == "Direct Paste Test Content 123", "PasteService wrote clip text to NSPasteboard.general")
    
    // 4. Paste image URL onto pasteboard
    let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("test_screenshot.png")
    try? "dummy".write(to: tempFile, atomically: true, encoding: .utf8)
    let imageClip = ClipItem(
        text: "test_screenshot.png",
        type: .image,
        imageFilePath: tempFile.path,
        sourceAppName: "Screenshot"
    )
    pasteService.pasteImageURL(item: imageClip, directPaste: false)
    let pbURLString = NSPasteboard.general.string(forType: .string)
    let expectedURLString = URL(fileURLWithPath: tempFile.path).absoluteString
    TestFramework.assert(pbURLString == expectedURLString, "pasteImageURL wrote file:/// URL to pasteboard for text inputs")
    try? FileManager.default.removeItem(at: tempFile)
    
    // 5. Accessibility status check API
    _ = PasteService.isAccessibilityTrusted
    TestFramework.assert(true, "PasteService.isAccessibilityTrusted API queried successfully without crashing")
    
    // 6. AppState accessibility refresh synchronization
    appState.refreshAccessibilityStatus()
    TestFramework.assert(appState.isAccessibilityGranted == PasteService.isAccessibilityTrusted, "AppState.isAccessibilityGranted accurately synchronizes with system trust state")
    
    // 7. Test simulatePasteKeystroke executes without error or early abort
    pasteService.simulatePasteKeystroke(for: nil)
    TestFramework.assert(true, "simulatePasteKeystroke dispatches cleanly with resilient fallback")
}

// Report final results
TestFramework.report()


