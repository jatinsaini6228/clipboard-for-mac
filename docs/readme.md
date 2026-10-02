# 📋 Documentation Hub: Clipboard for macOS

Welcome to the **Clipboard for Mac** documentation suite. All documentation files are provided in GitHub-flavored Markdown (`.md`) format for seamless reading across code editors, terminal viewers, and web browsers.

---

## 📚 Document Index

| Document | File Path | Target Audience | Summary |
| :--- | :--- | :--- | :--- |
| **Project Readme** | [`README.md`](../README.md) & [`docs/readme.md`](readme.md) | All Users & Developers | Main application overview, key feature list, keyboard shortcuts cheatsheet, and quick start guide. |
| **Developer Guide** | [`docs/developer_guid.md`](developer_guid.md) | Software Engineers & Contributors | Deep dive into codebase structure, subsystem breakdowns, thread safety, IPC, Carbon hotkeys, and adding new features. |
| **Technical Specs** | [`docs/tech.md`](tech.md) | Architects & Performance Engineers | In-depth technical specifications: memory consumption, CPU benchmarks, Quartz keystroke synthesis, and JSON schemas. |
| **Project Summary** | [`docs/summary_about_project.md`](summary_about_project.md) | Leadership & Evaluators | High-level executive summary, business value, competitive comparison against Paste/Maccy/Raycast, and ROI. |
| **Product Requirements** | [`docs/prd.md`](prd.md) | Product Managers & QA | Detailed functional requirements (FR-1 through FR-5), user personas, journey flows, and acceptance criteria. |
| **Business Requirements** | [`docs/brd.md`](brd.md) | Business Leads & Commercial Strategy | Market positioning, commercial opportunity, pricing landscape analysis, and KPI targets. |

---

## ⚡ Quick Reference Commands

### Building & Running
```bash
# Build standalone release bundle (build/Clipboard.app)
./scripts/build_app.sh

# Run development binary from terminal
swift run Clipboard

# Execute automated test suite (63 test assertions across 9 suites)
swift run ClipboardTestRunner
```

### Keyboard Shortcuts (HUD)
* **`Cmd + Shift + V`**: Summon / Dismiss Floating Search HUD (Global)
* **`Cmd + 1 .. 7`**: Switch category filter pills (All, Text, Code, Links, Colors, Images, Pinned)
* **`↑` / `↓`**: Navigate clipboard history
* **`PageUp` / `PageDown`**: Quick scroll jump through clip history
* **`Return` (`↵`)**: Paste selected clip directly into the previous active app
* **`Cmd + C`**: Copy selected clip to clipboard without auto-pasting
* **`Cmd + P`**: Toggle Pin status for selected clip
* **`Cmd + Backspace`**: Delete selected clip from history
* **`Escape` (`⎋`)**: Dismiss Search HUD
