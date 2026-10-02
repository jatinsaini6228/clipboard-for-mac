# 🛠️ Developer Guide: Clipboard for macOS

## 1. Project Overview & Architectural Principles

**Clipboard for Mac** is a native, ultra-lightweight, privacy-first clipboard history manager for macOS Sonoma, Sequoia, and macOS 27+. It is built entirely in **Swift 6**, **SwiftUI**, and **AppKit** without external third-party dependencies, Electron runtimes, or webviews.

### 1.1 Core Engineering Principles
1. **Zero-Overhead Polling**: CPU consumption must stay strictly $<0.05\%$ during idle. We poll `NSPasteboard.general.changeCount` every 350ms without intrusive global event taps.
2. **Absolute Privacy by Default**: Zero network activity, zero analytics, and zero cloud sync. All data remains exclusively on local disk (`~/Library/Application Support/Clipboard/`).
3. **Concealed Credential Defense**: Passwords, OTP codes, and private keys from password managers (1Password, Bitwarden, KeePassXC, Apple Keychain) are intercepted and rejected before touching memory or disk.
4. **Instant Keyboard Response**: The floating HUD (`Cmd + Shift + V`) must summon in $<10\text{ ms}$, support complete arrow-key navigation, instant search, and one-tap auto-pasting (`Return`).
5. **Universal Image & Screenshot Pasting**: Screenshots and raster images are stored at original Retina resolution and written to the pasteboard across multiple standard representations (`.png`, `.tiff`, `.fileURL`), guaranteeing compatibility with all Mac software.

---

## 2. Directory Layout & Module Structure

```
projects/clipboard-for-mac/
├── Package.swift                             # Swift Package Manager definition
├── Resources/
│   ├── AppIcon.icns                          # macOS multi-scale icon bundle (16x16 to 1024x1024)
│   └── app_logo.png                          # High-resolution master visual asset
├── Sources/
│   ├── Clipboard/                            # Application entry executable
│   │   └── main.swift                        # Bootstrap, NSApplication activation policy, signal traps
│   ├── ClipboardKit/                         # Core library framework
│   │   ├── AppDelegate.swift                 # AppKit lifecycle, status bar & hotkey initialization
│   │   ├── AppState.swift                    # Central ObservableObject coordinator & user preferences
│   │   ├── ClipItem.swift                    # Data model, ClipType enum, formatting & time helpers
│   │   ├── ClipboardStorage.swift            # JSON file persistence, thread-safe queue, pruning, search
│   │   ├── ContentTypeClassifier.swift       # Semantic classifier (Code, Color, URL, Text)
│   │   ├── FloatingHUDWindowController.swift # Non-activating acrylic NSPanel window manager
│   │   ├── HotkeyManager.swift               # Carbon Event HotKey handler (Cmd + Shift + V)
│   │   ├── HUDView.swift                     # SwiftUI search bar, split-pane list & rich live preview
│   │   ├── ImageStore.swift                  # Full-resolution image cache & multi-type pasteboard writer
│   │   ├── PasteboardMonitor.swift           # NSPasteboard changeCount polling engine
│   │   ├── PasteService.swift                # Frontmost app focus restore & CGEvent keystroke synthesis
│   │   ├── PreferencesView.swift             # SwiftUI Preferences window (General, History, Privacy)
│   │   ├── ScreenshotMonitor.swift           # Filesystem observer for new macOS screenshot files
│   │   ├── SensitiveDataFilter.swift         # 1Password, Bitwarden & credential defense engine
│   │   ├── SoundManager.swift                # Subtle native system sound cues
│   │   └── StatusBarController.swift         # NSStatusItem menu bar icon & dynamic dropdown menu
│   └── ClipboardTestRunner/                  # Automated test suite executable
│       └── main.swift                        # 8 test suites, 57 automated assertion checks
├── docs/
│   ├── readme.md                             # Project overview & quick start
│   ├── developer_guid.md                     # This developer architecture guide
│   ├── tech.md                               # Deep technical specifications
│   ├── summary_about_project.md              # Executive project summary
│   ├── prd.md                                # Product Requirements Document
│   └── brd.md                                # Business Requirements Document
└── scripts/
    ├── build_app.sh                          # Release compilation, app packaging & code signing
    └── generate_icon.swift                   # Vector squircle icon generator using CoreGraphics
```

---

## 3. Subsystem Breakdown & Implementation Details

### 3.1 Pasteboard Monitoring Engine (`PasteboardMonitor.swift`)
Instead of installing global accessibility hooks or event taps that trigger macOS security prompts, `PasteboardMonitor` observes `NSPasteboard.general.changeCount`:
* The macOS kernel increments `changeCount` whenever any process copies data to the general pasteboard.
* A timer scheduled on `RunLoop.main` in `.common` mode polls `changeCount` every 350ms.
* If `changeCount` has not changed, the check exits immediately in $<0.001\text{ ms}$.
* If `changeCount` has changed:
  1. Identifies the active frontmost app via `NSWorkspace.shared.frontmostApplication`.
  2. Bypasses copies initiated by the app itself (`Bundle.main.bundleIdentifier`).
  3. Passes the pasteboard to `SensitiveDataFilter`.
  4. If textual, classifies via `ContentTypeClassifier` and adds to `ClipboardStorage`.
  5. If raster image, caches via `ImageStore` and adds to `ClipboardStorage`.

### 3.2 Screenshot Watcher (`ScreenshotMonitor.swift`)
Captures screenshots saved directly to files by macOS (`Cmd + Shift + 3`, `Cmd + Shift + 4`, `Cmd + Shift + 5`):
* Reads the destination directory from `defaults read com.apple.screencapture location` (falling back to `~/Desktop`).
* Scans for new files matching standard screenshot naming patterns:
  - `Screenshot YYYY-MM-DD at ... .png`
  - `Screen Shot YYYY-MM-DD at ... .png`
  - `screencapture_...`
  - Localized patterns (`Capture d’écran`, `Bildschirmfoto`, etc.)
* Verifies file write completion (`size > 0` and valid `NSImage(contentsOf:)`).
* Saves full-resolution image to `~/Library/Application Support/Clipboard/Images/<uuid>.png`.
* Generates a base64 thumbnail for instant UI display.
* **Immediately writes multi-representation image data to `NSPasteboard.general`** (`.png`, `.tiff`, `.fileURL`), so the user can paste it anywhere right away.

### 3.3 High-Resolution Image Storage (`ImageStore.swift`)
Provides dedicated disk storage and multi-type pasteboard serialization for images:
* **Storage Location**: `~/Library/Application Support/Clipboard/Images/`
* **Thumbnail Generation**: Downsamples images proportionally to a max dimension of 260px for smooth 60fps scrolling in SwiftUI.
* **Multi-Format Pasteboard Export**:
  ```swift
  var types: [NSPasteboard.PasteboardType] = [.png, .tiff]
  if let path = filePath { types.append(.fileURL) }
  pasteboard.declareTypes(types, owner: nil)
  pasteboard.setData(pngData, forType: .png)
  pasteboard.setData(tiffData, forType: .tiff)
  pasteboard.writeObjects([fileURL as NSURL, image])
  ```
  This guarantees that web browsers, Electron apps (Slack, Discord), native Apple apps (Notes, Pages), and graphic editors (Figma, Photoshop) all receive their native format.

### 3.4 Credential & Privacy Filter (`SensitiveDataFilter.swift`)
Ensures no sensitive passwords or tokens are stored:
* **Concealed Types**: Checks for `org.nspasteboard.ConcealedType`, `org.nspasteboard.AutoGeneratedType`, `org.nspasteboard.TransientType`, and `com.agilebits.onepassword`.
* **Ignored Bundles**: Drops all copies originating from:
  - `com.apple.keychainaccess`
  - `com.agilebits.onepassword` / `com.agilebits.onepassword7` / `com.agilebits.onepassword8`
  - `com.bitwarden.desktop`
  - `org.keepassxc.keepassxc`
  - `com.lastpass.LastPass`
  - `com.dashlane.Dashlane`
* **Pattern Scanner**: Scans for private certificates (`-----BEGIN PRIVATE KEY-----`) and AWS Access Keys (`AKIA[0-9A-Z]{16}`).

### 3.5 Global Shortcut Engine (`HotkeyManager.swift`)
* Uses Apple's native **Carbon Event Manager** (`RegisterEventHotKey`).
* Default shortcut: `Cmd + Shift + V` (Keycode `0x09`, modifiers `cmdKey | shiftKey`).
* Unlike Accessibility-based keyloggers, Carbon hotkeys require **zero Accessibility permissions** to summon the HUD!
* When pressed, dispatches to the main queue to toggle `FloatingHUDWindowController.shared.toggleWindow()`.

### 3.6 Direct Paste Keystroke Synthesis & Window Focus (`PasteService.swift`)
Allows one-tap pasting directly into the user's active document or input field:
1. Tracks active background applications in real time using `NSWorkspace.didActivateApplicationNotification`, guaranteeing that the real destination app is remembered even across window minimizes.
2. Marks pasteboard writes with `NSPasteboard.PasteboardType("com.clipboard.mac.internal")` so `PasteboardMonitor` recognizes self-initiated writes and never generates duplicate clips.
3. Yields HUD focus before keystroke synthesis:
   ```swift
   FloatingHUDWindowController.shared.hideWindow()
   NSApp.deactivate()
   targetApp.activate(options: [.activateIgnoringOtherApps])
   ```
4. Provides a 180ms settle delay allowing macOS window server to complete the focus transition, then synthesizes `Cmd + V` using Quartz CoreGraphics events targeted directly at `.cgSessionEventTap`:
   ```swift
   let source = CGEventSource(stateID: .combinedSessionState)
   let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
   keyDown?.flags = .maskCommand
   let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
   keyUp?.flags = .maskCommand
   keyDown?.post(tap: .cgSessionEventTap)
   keyUp?.post(tap: .cgSessionEventTap)
   ```
5. Supports dedicated "Paste Image URL" mode (`pasteImageURL`), which writes `file:///...` directly to the pasteboard to paste screenshot paths into terminal inputs, markdown editors, and chat search fields.
6. If macOS Accessibility permission is not yet granted, displays an inline warning banner with a one-click button to jump directly into macOS System Settings (`x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`).

### 3.7 Storage & Persistence (`ClipboardStorage.swift`)
* **File Location**: `~/Library/Application Support/Clipboard/history.json`
* **Concurrency**: Serial `DispatchQueue(label: "com.clipboard.storage.queue")` guarantees thread safety during atomic file writes.
* **Synchronous Load & Termination Save**: Synchronous decoding on app launch eliminates empty initial state races; synchronous atomic save (`save(synchronous: true)`) on termination (`SIGINT`, `SIGTERM`, `applicationWillTerminate`, and `quitApp`) prevents data loss.
* **Deduplication**: If duplicate text is copied, the older unpinned instance is removed and the new one is placed at index 0.
* **Pruning Logic**:
  - Respects user preference `maxHistoryCount` (default: 200).
  - **Pinned Protection**: Pinned clips (`isPinned: true`) are never pruned regardless of history size.
* **Search Engine**: Case-insensitive substring matching against text, detected language, hex color, and source app name.

---

## 4. Threading & Concurrency Model

```mermaid
sequenceDiagram
    participant OS as macOS Pasteboard / Filesystem
    participant Mon as Pasteboard & Screenshot Monitor
    participant Filter as SensitiveDataFilter
    participant Store as ClipboardStorage (Serial Queue)
    participant State as AppState (Main Thread)
    participant UI as SwiftUI HUDView (Main Thread)

    OS->>Mon: ChangeCount incremented or Screenshot file created
    Mon->>Filter: Verify types & bundle IDs
    Filter-->>Mon: Passed (Safe)
    Mon->>Store: addItem(clip)
    Store->>Store: Atomic JSON save on background serial queue
    Store->>State: Publish new @Published items on Main Thread
    State->>UI: Re-render list & live preview
```

---

## 5. Development Workflow & Commands

### 5.1 Compiling in Debug Mode
```bash
cd projects/clipboard-for-mac
swift build
```

### 5.2 Running the Application via CLI
```bash
swift run Clipboard
```

### 5.3 Executing Automated Test Suite
```bash
swift run ClipboardTestRunner
```
All 9 test suites run in-process (63 assertions):
1. `ContentTypeClassifier Tests`
2. `SensitiveDataFilter Tests`
3. `ClipItem Model Tests`
4. `ClipboardStorage Persistence Tests`
5. `Search & Filtering Tests`
6. `JSON Serialization Tests`
7. `Controls & Monitor Tests`
8. `Screenshot & Full-Resolution Image Tests`
9. `PasteService & Direct Paste Engine Tests`

### 5.4 Release Packaging
```bash
./scripts/build_app.sh
```
This compiles release binaries with optimizations (`-c release`), assembles `Clipboard.app`, generates `Info.plist` with `LSUIElement = true`, embeds `AppIcon.icns`, and applies an ad-hoc code signature (`codesign -s - --force --deep`).
