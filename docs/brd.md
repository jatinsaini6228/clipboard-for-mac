# 💼 Business Requirements Document (BRD)

## Document Metadata
* **Project Name**: Clipboard for macOS
* **Version**: 1.0.0
* **Target Audience**: Product Leadership, Commercial Strategy, Enterprise Users

---

## 1. Business Opportunity & Market Context

The macOS clipboard market is divided into two unsatisfactory extremes:
1. **Bloated Commercial Subscriptions**: Tools like *Paste* charge recurring $14.99–$29.99/year subscriptions and run heavy background frameworks that consume excessive battery and memory.
2. **Minimalist Open-Source Tools**: Tools like *Maccy* provide basic text menus but lack rich live previews, color swatch cards, syntax highlighting, image dimension metadata, or modern visual design.

**Clipboard for Mac** fills this high-value gap: A lightning-fast, native Swift utility delivering the visual elegance of Raycast, the rich preview fidelity of Paste, and the privacy and zero-overhead performance of native AppKit.

---

## 2. Competitive Positioning Matrix

| Capability / Attribute | Clipboard for Mac | Paste (Commercial) | Maccy (Open Source) | Raycast (Clipboard Ext) |
| :--- | :--- | :--- | :--- | :--- |
| **Technology Stack** | Native Swift 6 + SwiftUI + AppKit | Swift / Webview Hybrid | Swift / AppKit Menu | React / Node Runtime |
| **Memory Footprint** | **~30 MB** | ~180–300 MB | ~35 MB | ~250–450 MB |
| **Pricing Model** | **100% Free / Open Native** | $14.99/year subscription | Free | Bundled with Raycast |
| **Password Manager Defense** | **Built-in ConcealedType Filter** | Basic | Basic | Good |
| **Color Swatches Preview** | **Yes (HEX, RGB with visual card)** | Yes | No | Limited |
| **Code Syntax Detection** | **Yes (Swift, Python, JS, SQL, Shell)** | No (plain monospace) | No | Limited |
| **Direct Keystroke Paste** | **Yes (CGEvent synthesis)** | Yes | Yes | Yes |
| **Offline Privacy** | **100% Local (0 Network Requests)** | Cloud Sync Required | 100% Local | Requires Account |

---

## 3. Key Performance Indicators (KPIs)

* **Performance & Reliability**:
  - Memory consumption maintained under 40 MB RSS.
  - Zero crashes or UI hangs during rapid pasteboard spamming.
  - 100% test coverage across classification, storage pruning, and security filters.
* **User Productivity**:
  - Reduction in multi-window context switching time by >60%.
  - Zero unintended password leaks from password manager entries.
