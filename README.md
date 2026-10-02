# 📋 Clipboard for macOS

A native, ultra-lightweight, privacy-first clipboard history manager for macOS Sonoma, Sequoia, and macOS 27+. Engineered with **Swift 6**, **SwiftUI**, and **AppKit**.

---

## ✨ Features

- **🎨 Modern Visual Identity & App Icon**:
  - High-resolution multi-scale `.icns` and master PNG asset featuring a dark squircle with glassmorphic layered documents and glowing cyan checkmark badge (`Resources/AppIcon.icns`).
- **🚀 Spotlight / Raycast-Inspired Floating Search HUD**:
  - Summon instantly with global hotkey: **`Cmd + Shift + V`**.
  - Acrylic blurred floating HUD window centered on your active display.
  - Real-time search across text, code snippets, URL domains, and color values.
  - Category pill tabs: **All**, **Text**, **Code**, **Links**, **Colors**, **Images**, **Pinned**.
  - Two-pane split layout: Fast navigational list on the left, live rich detail preview on the right.
- **🌈 Rich Semantic Classification & Previews**:
  - **Hex & RGB Colors**: Visual color swatch card preview with one-tap hex copying.
  - **Code Snippets**: Syntax language detection (Swift, Python, JS/TS, JSON, HTML, Shell, SQL) with line numbers and monospace display.
  - **URLs & Links**: Host domain parsing and quick "Open in Browser" button.
  - **Images**: High-efficiency thumbnail rendering with dimension metadata.
  - **Plain & Rich Text**: Character and line count statistics.
- **📸 Automatic Screenshot Capture & Universal Pasting**:
  - Automatically observes whenever a screenshot is taken (`Cmd + Shift + 3` / `Cmd + Shift + 4` / `Cmd + Shift + 5` or direct clipboard screenshots).
  - Immediately copies the full-resolution screenshot to the system clipboard so you can paste it everywhere instantly.
  - Automatically caches the full Retina resolution image to local storage (`~/Library/Application Support/Clipboard/Images/`).
  - Writes multi-format pasteboard payloads (`.png`, `.tiff`, and `.fileURL`) ensuring universal paste compatibility across Slack, Discord, Chrome, Safari, Figma, Apple Notes, Pages, Google Docs, Telegram, WhatsApp, and Terminal.
- **⚡ Direct Auto-Paste into Active Apps**:
  - Select any item and press **`Return`** (`↵`) to paste directly into your current active application via synthetic `CGEvent` keystrokes.
- **🔒 Privacy & Password Manager Defense**:
  - Automatically detects and drops confidential payloads marked with `org.nspasteboard.ConcealedType`.
  - Excludes password managers including **1Password**, **Bitwarden**, **KeePassXC**, and **Apple Keychain Access**.
  - Scans and blocks high-risk secrets (private keys, AWS tokens).
  - 100% offline, local-only storage (`~/Library/Application Support/Clipboard/`). Zero telemetry, zero analytics.
- **📌 Pinning & Smart Pruning**:
  - Pin important clips with **`Cmd + P`** or via the pin button.
  - Configurable history limit (50, 100, 200, 500, or 1,000 items).
  - Pinned items are permanently protected and never pruned.
- **MenuBar Status Utility**:
  - Clean status item in the macOS menu bar.
  - Quick dropdown menu with recent clips, pause/resume recording, and preferences.

---

## ⌨️ Keyboard Shortcuts (HUD)

| Shortcut | Action |
| :--- | :--- |
| **`Cmd + Shift + V`** | Summon or dismiss the Floating Search HUD (Global) |
| **`Cmd + 1 .. 7`** | Switch category filter pills (All, Text, Code, Links, Colors, Images, Pinned) |
| **`↑` / `↓`** | Navigate through clipboard items |
| **`PageUp` / `PageDown`** | Jump scroll through items in batches of 5 |
| **`Return` (`↵`)** | Paste selected clip directly into the previous active app |
| **`Cmd + C`** | Copy selected clip to clipboard without auto-pasting |
| **`Cmd + P`** | Toggle Pin status for selected clip |
| **`Cmd + Backspace`** | Delete selected clip from history |
| **`Escape` (`⎋`)** | Dismiss Search HUD |

---

## 🏗️ Architecture

```
projects/clipboard-for-mac/
├── Package.swift                         # Swift Package Manager manifest
├── Resources/
│   ├── AppIcon.icns                      # macOS multi-resolution icon bundle
│   └── app_logo.png                      # High-resolution PNG logo
├── Sources/
│   ├── Clipboard/                        # Executable application target
│   │   └── main.swift                    # App bootstrap & signal handlers
│   ├── ClipboardKit/                     # Core framework
│   │   ├── AppDelegate.swift             # AppKit lifecycle & hotkey initialization
│   │   ├── AppState.swift                # Central reactive ObservableObject state coordinator
│   │   ├── ClipItem.swift                # Data models, ClipType enum & formatting helpers
│   │   ├── ClipboardStorage.swift        # Thread-safe disk persistence, pruning & search
│   │   ├── ContentTypeClassifier.swift   # Semantic classifier (Code, Color, URL, Text)
│   │   ├── FloatingHUDWindowController.swift # NSPanel HUD manager & keyboard monitors
│   │   ├── HotkeyManager.swift           # Carbon Event HotKey global shortcut handler
│   │   ├── HUDView.swift                 # SwiftUI search bar, split list & rich live preview
│   │   ├── ImageStore.swift              # Full-resolution disk cache & multi-type pasteboard writer
│   │   ├── PasteboardMonitor.swift       # NSPasteboard changeCount polling engine
│   │   ├── PasteService.swift            # Target app restore & Quartz keystroke synthesis
│   │   ├── PreferencesView.swift         # SwiftUI settings window (General, History, Privacy)
│   │   ├── ScreenshotMonitor.swift       # Real-time screenshot file watcher & auto-copy engine
│   │   ├── SensitiveDataFilter.swift     # 1Password, Bitwarden & credential protections
│   │   ├── SoundManager.swift            # Subtle native system sound feedback
│   │   └── StatusBarController.swift     # Menu Bar NSStatusItem & dynamic dropdown
│   └── ClipboardTestRunner/              # Automated test suite (all 9 suites, 63 assertions)
│       └── main.swift
├── docs/
│   ├── readme.md                         # Documentation index & hub
│   ├── developer_guid.md                 # Complete developer architecture guide
│   ├── tech.md                           # Deep technical specifications & schemas
│   ├── summary_about_project.md          # Executive summary & competitive matrix
│   ├── prd.md                            # Product Requirements Document
│   └── brd.md                            # Business Requirements Document
└── scripts/
    ├── build_app.sh                      # Release bundler for Clipboard.app
    └── generate_icon.swift               # Icon renderer script
```

---

## 🚀 Building & Running

### Option 1: Package Standalone macOS App (`Clipboard.app`)
Run the packaging script to generate a signed release application bundle:
```bash
./scripts/build_app.sh
```

To launch the app:
```bash
open build/Clipboard.app
```

To install into `/Applications`:
```bash
cp -R build/Clipboard.app /Applications/
```

### Option 2: Swift Package Manager (Development CLI)
Run directly from terminal during development:
```bash
swift run Clipboard
```

---

## 🧪 Automated Tests

Run the comprehensive 8-suite automated test runner:
```bash
swift run ClipboardTestRunner
```

Verified test suites:
1. `ContentTypeClassifier Tests`: Hex & RGB colors, HTTP/HTTPS links, JSON/Swift/Python/SQL code detection, plain text.
2. `SensitiveDataFilter Tests`: Apple Keychain, 1Password, Bitwarden bundle exclusions, private key and AWS token detection.
3. `ClipItem Model Tests`: Line count, character count, title extraction, relative time formatting.
4. `ClipboardStorage Persistence Tests`: Serialization, disk reload, deduplication, max item pruning, pin preservation.
5. `Search & Filtering Tests`: Substring search, category filters (`.url`, `.color`, `.code`, `.pinned`).
6. `JSON Serialization Tests`: Encoding and decoding fidelity.
7. `Controls & Monitor Tests`: PasteboardMonitor pause/resume state and SoundManager toggles.
8. `Screenshot & Full-Resolution Image Tests`: Multi-format pasteboard exports, Retina caching, screenshot filename patterns.
