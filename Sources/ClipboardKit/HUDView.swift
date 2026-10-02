import SwiftUI
import AppKit

/// Main floating HUD SwiftUI interface with unified header, authentic keycap footer, and drag-and-drop.
public struct HUDView: View {
    @ObservedObject var appState: AppState = .shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Unified Professional Header (Traffic lights, Branding, Filter Pills, Search)
            unifiedHeaderView
                .layoutPriority(1)
            
            Divider()
                .opacity(0.25)
            
            // Two-Pane Content Split Area
            HStack(spacing: 0) {
                // Left Column: List of Clips with Drag & Drop
                clipListView
                    .frame(width: 320)
                
                Divider()
                    .opacity(0.25)
                
                // Right Column: Rich Detail Preview with Actions
                detailPreviewView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            Divider()
                .opacity(0.25)
            
            // Professional Footer Shortcuts Bar
            footerView
                .layoutPriority(1)
        }
        .frame(minWidth: 860, maxWidth: .infinity, minHeight: 600, maxHeight: .infinity)
        .background(
            ZStack {
                VisualEffectBackground()
                WindowDragHandleView()
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 25, x: 0, y: 12)
        .onAppear {
            appState.refreshAccessibilityStatus()
        }
        .onReceive(Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()) { _ in
            if !appState.isAccessibilityGranted {
                appState.refreshAccessibilityStatus()
            }
        }
    }
    
    // MARK: - Unified Professional Header
    
    private var unifiedHeaderView: some View {
        VStack(spacing: 10) {
            // Top Navigation & Window Control Bar
            HStack(spacing: 12) {
                // Authentic macOS Style Traffic Lights (Window Controls with hover symbols)
                TrafficLightCluster()
                
                Rectangle()
                    .fill(Color.primary.opacity(0.12))
                    .frame(width: 1, height: 16)
                    .padding(.horizontal, 2)
                
                // App Branding
                HStack(spacing: 7) {
                    Image(systemName: "clipboard.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.accentColor)
                    
                    Text("Clipboard")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                
                Spacer()
                
                // Category Filter Pills Segmented Bar with Command shortcuts
                HStack(spacing: 3) {
                    ForEach(Array(ClipType.allCases.enumerated()), id: \.element) { idx, filter in
                        CategoryPillButton(
                            title: filter.rawValue,
                            icon: filter.iconName,
                            shortcutIndex: idx + 1,
                            isSelected: appState.selectedFilter == filter
                        ) {
                            appState.selectedFilter = filter
                        }
                    }
                }
                .padding(3)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.primary.opacity(0.06)))
                
                Spacer()
                
                // Quick Window Controls: Expand, Clear, Settings & Quit
                HStack(spacing: 6) {
                    Button(action: {
                        FloatingHUDWindowController.shared.toggleZoom()
                    }) {
                        Image(systemName: appState.isWindowExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Color.primary.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                    .help(appState.isWindowExpanded ? "Compact View" : "Expand View")
                    
                    Button(action: {
                        appState.clearAllHistory()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Color.primary.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                    .help("Clear Unpinned History")
                    
                    Button(action: {
                        StatusBarController.shared.openPreferences()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Color.primary.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                    .help("Preferences...")
                    
                    Button(action: {
                        FloatingHUDWindowController.shared.quitApp()
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.red.opacity(0.85))
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Color.red.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .help("Quit Clipboard App")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            
            // Search Input Field Card
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.accentColor)
                
                TextField("Search clips, code, links, colors, or screenshots...", text: $appState.searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                
                if !appState.searchQuery.isEmpty {
                    Button(action: { appState.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                HStack(spacing: 6) {
                    Text("\(appState.filteredClips.count) items")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.primary.opacity(0.08)))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 16)
            .padding(.bottom, appState.isAccessibilityGranted ? 10 : 4)
            
            // Accessibility Permission Banner (shown only when direct paste is enabled, permission is not granted, and user hasn't dismissed it)
            if appState.directPasteEnabled && !appState.isAccessibilityGranted && !appState.isAccessibilityBannerDismissed {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                    
                    Text("Direct Paste into background apps requires Accessibility permission.")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primary.opacity(0.85))
                    
                    Spacer()
                    
                    Button(action: {
                        PasteService.requestAccessibilityPermissions()
                        PasteService.openAccessibilitySettings()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 9))
                            Text("Enable in Settings")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.orange))
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            appState.isAccessibilityBannerDismissed = true
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.primary.opacity(0.6))
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                    .help("Dismiss banner")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.orange.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.orange.opacity(0.25), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .background(WindowDragHandleView())
    }
    
    // MARK: - Clip List View with Drag & Drop
    
    private var clipListView: some View {
        Group {
            if appState.filteredClips.isEmpty {
                VStack(spacing: 14) {
                    Spacer()
                    Image(systemName: appState.selectedFilter == .image ? "photo.on.rectangle.angled" : "doc.text.magnifyingglass")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.45))
                    
                    VStack(spacing: 5) {
                        Text(appState.searchQuery.isEmpty ? 
                             (appState.selectedFilter == .all ? "No clips saved yet" : "No \(appState.selectedFilter.rawValue.lowercased()) clips") :
                             "No matching clips found")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text(appState.searchQuery.isEmpty ? 
                             (appState.selectedFilter == .image ? "Press ⌘⇧3 or ⌘⇧4 to capture a screenshot." : "Copy text or take screenshots to start building your history.") :
                             "Try searching with different keywords or switch filters.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.75))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    Spacer()
                }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(appState.filteredClips) { clip in
                                ClipRowView(
                                    clip: clip,
                                    isSelected: clip.id == appState.selectedClipId,
                                    isHovered: clip.id == appState.hoveredClipId,
                                    onSelect: {
                                        appState.selectedClipId = clip.id
                                    },
                                    onDoubleClick: {
                                        appState.pasteClip(clip)
                                    },
                                    onTogglePin: {
                                        appState.togglePin(id: clip.id)
                                    },
                                    onDelete: {
                                        appState.storage.removeItem(id: clip.id)
                                    },
                                    onHover: { hovering in
                                        appState.hoveredClipId = hovering ? clip.id : nil
                                    }
                                )
                                .id(clip.id)
                                // Native Drag-and-Drop
                                .onDrag {
                                    createItemProvider(for: clip)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                    }
                    .onChange(of: appState.selectedClipId) { newId in
                        if let newId = newId {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                proxy.scrollTo(newId, anchor: .center)
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Detail Preview View
    
    private var detailPreviewView: some View {
        Group {
            if let clip = appState.selectedClip {
                VStack(spacing: 0) {
                    // Metadata Header Bar
                    HStack(spacing: 10) {
                        Label(clip.type.rawValue, systemImage: clip.type.iconName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.accentColor)
                        
                        if let lang = clip.detectedLanguage {
                            Text(lang)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.orange.opacity(0.2)))
                                .foregroundColor(.orange)
                        }
                        
                        if let app = clip.sourceAppName {
                            Text("From \(app)")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(clip.timeAgoFormatted)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            appState.togglePin(id: clip.id)
                        }) {
                            Image(systemName: clip.isPinned ? "pin.fill" : "pin")
                                .font(.system(size: 13))
                                .foregroundColor(clip.isPinned ? .orange : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help(clip.isPinned ? "Unpin Clip" : "Pin Clip (⌘P)")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.primary.opacity(0.02))
                    
                    Divider().opacity(0.2)
                    
                    // Main Preview Scroll View
                    ScrollView {
                        VStack(alignment: .leading, spacing: 14) {
                            if clip.type == .color, let hex = clip.hexColor {
                                colorPreview(hex: hex)
                            } else if clip.type == .image {
                                imageDetailPreview(clip: clip)
                            } else if clip.type == .url {
                                urlPreview(urlString: clip.text)
                            } else if clip.type == .code {
                                codePreview(code: clip.text, lang: clip.detectedLanguage)
                            } else {
                                textPreview(text: clip.text)
                            }
                        }
                        .padding(16)
                    }
                    
                    Divider().opacity(0.2)
                    
                    // Production-Ready Bottom Action Toolbar
                    actionToolbar(for: clip)
                }
            } else {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "hand.tap")
                        .font(.system(size: 34))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("Select a clip to view preview and actions")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Specialized Preview Cards
    
    private func colorPreview(hex: String) -> some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(hex: hex) ?? Color.gray)
                .frame(height: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(radius: 6)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Color Value:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(hex)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                    Spacer()
                    Button("Copy HEX") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(hex, forType: .string)
                        SoundManager.playCopySound()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.04)))
        }
    }
    
    private func imageDetailPreview(clip: ClipItem) -> some View {
        let loadedImage: NSImage? = {
            if let path = clip.imageFilePath, let img = ImageStore.shared.loadImage(at: path) {
                return img
            }
            if let base64 = clip.imageThumbnailBase64, let data = Data(base64Encoded: base64) {
                return NSImage(data: data)
            }
            return nil
        }()
        
        return VStack(spacing: 12) {
            // Visual Image Box with Drag Support
            ZStack(alignment: .topTrailing) {
                if let image = loadedImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
                        .onDrag {
                            createItemProvider(for: clip)
                        }
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                        .frame(height: 200)
                }
                
                // Drag badge indicator
                HStack(spacing: 4) {
                    Image(systemName: "hand.draw")
                        .font(.system(size: 10))
                    Text("Drag to Drop")
                        .font(.system(size: 10, weight: .bold))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.65)))
                .foregroundColor(.white)
                .padding(8)
            }
            
            // Image Metadata Bar
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    if let w = clip.imageWidth, let h = clip.imageHeight {
                        Label("\(Int(w)) × \(Int(h)) px", systemImage: "aspectratio")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    
                    if clip.sourceAppName == "Screenshot" || clip.text.lowercased().contains("screenshot") {
                        Text("Retina Screenshot")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.blue.opacity(0.2)))
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                
                if let path = clip.imageFilePath, FileManager.default.fileExists(atPath: path) {
                    HStack {
                        Image(systemName: "folder")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(path)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button(action: {
                            ImageStore.shared.revealInFinder(at: path)
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 9))
                                Text("Reveal in Finder")
                                    .font(.system(size: 10, weight: .medium))
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
        }
    }
    
    private func urlPreview(urlString: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 26))
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(URL(string: urlString)?.host ?? "Web Link")
                        .font(.system(size: 14, weight: .bold))
                    Text(urlString)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.04)))
            
            if let url = URL(string: urlString) {
                Button(action: {
                    NSWorkspace.shared.open(url)
                    appState.hideHUD()
                }) {
                    Label("Open in Web Browser", systemImage: "arrow.up.right.square")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.bordered)
            }
        }
    }
    
    private func codePreview(code: String, lang: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ScrollView([.horizontal, .vertical]) {
                Text(code)
                    .font(.system(size: 12, design: .monospaced))
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.28))
            )
        }
    }
    
    private func textPreview(text: String) -> some View {
        Text(text)
            .font(.system(size: 13))
            .lineSpacing(4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
    }
    
    // MARK: - Action Toolbar
    
    private func actionToolbar(for clip: ClipItem) -> some View {
        HStack(spacing: 10) {
            Button(action: {
                appState.removeSelected()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                    Text("Delete")
                        .font(.system(size: 11))
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Delete Clip (⌘⌫)")
            
            Text("·")
                .foregroundColor(.secondary.opacity(0.3))
            
            Text("\(clip.characterCount) chars · \(clip.lineCount) lines")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
            
            Spacer()
            
            if clip.type == .image {
                // Button to specifically paste Image URL into text inputs
                Button(action: {
                    appState.pasteSelectedImageURL()
                }) {
                    Label("Paste Image URL", systemImage: "link")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Pastes file:/// URL into search bars, terminals, or markdown text fields")
                
                // Primary paste button (universal)
                Button(action: {
                    appState.pasteSelected()
                }) {
                    Label("Paste Image", systemImage: "arrow.right.doc.on.clipboard")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .help("Pastes image directly into frontmost app (↵)")
            } else {
                Button(action: {
                    appState.copySelectedWithoutPaste()
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button(action: {
                    appState.pasteSelected()
                }) {
                    Label("Paste", systemImage: "arrow.right.doc.on.clipboard")
                        .font(.system(size: 12, weight: .bold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .help("Pastes content directly into frontmost app (↵)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.02))
    }
    
    // MARK: - Professional Apple Keycap Footer Bar
    
    private var footerView: some View {
        HStack(spacing: 12) {
            // Elevated Real Keycaps
            KeycapBadge(key: "↵", label: "Paste")
            KeycapBadge(key: "⌘C", label: "Copy")
            KeycapBadge(key: "⌘P", label: "Pin")
            KeycapBadge(key: "⌘⌫", label: "Delete")
            KeycapBadge(key: "⌘1-7", label: "Filter")
            KeycapBadge(key: "↑↓", label: "Navigate")
            KeycapBadge(key: "⎋", label: "Dismiss")
            
            Spacer()
            
            // Status & Drag Hint
            HStack(spacing: 8) {
                if appState.isAccessibilityGranted {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)
                        .shadow(color: Color.green.opacity(0.6), radius: 2)
                    
                    Text("Direct Paste Ready")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                } else {
                    Button(action: {
                        PasteService.requestAccessibilityPermissions()
                        PasteService.openAccessibilitySettings()
                    }) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 7, height: 7)
                                .shadow(color: Color.orange.opacity(0.6), radius: 2)
                            
                            Text("Accessibility Needed")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Click to grant Accessibility permission in System Settings")
                }
                
                Text("·")
                    .foregroundColor(.secondary.opacity(0.4))
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                        .font(.system(size: 9))
                    Text("Drag header to move · Drag edges to resize")
                        .font(.system(size: 10))
                }
                .foregroundColor(.secondary.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(
            ZStack {
                Color.primary.opacity(0.035)
                WindowDragHandleView()
            }
        )
    }
    
    // MARK: - Drag-and-Drop Item Provider Helper
    
    private func createItemProvider(for clip: ClipItem) -> NSItemProvider {
        if clip.type == .image {
            if let path = clip.imageFilePath, FileManager.default.fileExists(atPath: path) {
                let url = URL(fileURLWithPath: path)
                let provider = NSItemProvider(contentsOf: url) ?? NSItemProvider(object: url as NSURL)
                provider.suggestedName = clip.text
                return provider
            } else if let base64 = clip.imageThumbnailBase64, let data = Data(base64Encoded: base64), let img = NSImage(data: data) {
                return NSItemProvider(object: img)
            }
        }
        return NSItemProvider(object: clip.text as NSString)
    }
}

// MARK: - Professional Apple Keycap View Component

struct KeycapBadge: View {
    let key: String
    let label: String
    
    var body: some View {
        HStack(spacing: 5) {
            Text(key)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.primary.opacity(0.85))
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.primary.opacity(0.09))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
                )
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Authentic Apple Traffic Light Cluster

struct TrafficLightCluster: View {
    @ObservedObject var appState: AppState = .shared
    
    var body: some View {
        HStack(spacing: 7) {
            // Close (Red)
            TrafficLightButton(
                color: Color(red: 1.0, green: 0.38, blue: 0.34),
                symbol: "xmark",
                isHovered: appState.isTrafficHovered,
                tooltip: "Close (⎋)"
            ) {
                FloatingHUDWindowController.shared.hideWindow()
            }
            
            // Minimize (Yellow)
            TrafficLightButton(
                color: Color(red: 1.0, green: 0.74, blue: 0.2),
                symbol: "minus",
                isHovered: appState.isTrafficHovered,
                tooltip: "Minimize to Menu Bar"
            ) {
                FloatingHUDWindowController.shared.minimizeWindow()
            }
            
            // Zoom / Expand (Green)
            TrafficLightButton(
                color: Color(red: 0.16, green: 0.78, blue: 0.35),
                symbol: "plus",
                isHovered: appState.isTrafficHovered,
                tooltip: "Resize / Expand Window"
            ) {
                FloatingHUDWindowController.shared.toggleZoom()
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                appState.isTrafficHovered = hovering
            }
        }
    }
}

struct TrafficLightButton: View {
    let color: Color
    let symbol: String
    let isHovered: Bool
    let tooltip: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.black.opacity(0.18), lineWidth: 0.5))
                
                if isHovered {
                    Image(systemName: symbol)
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(Color.black.opacity(0.65))
                }
            }
        }
        .buttonStyle(.plain)
        .help(tooltip)
    }
}

// MARK: - Category Pill Segmented Button Component

struct CategoryPillButton: View {
    let title: String
    let icon: String
    let shortcutIndex: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4.5)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            .foregroundColor(isSelected ? .white : .secondary)
        }
        .buttonStyle(.plain)
        .help("\(title) (⌘\(shortcutIndex))")
    }
}

// MARK: - Clip Row Component with Hover Actions & Drag Support

struct ClipRowView: View {
    let clip: ClipItem
    let isSelected: Bool
    let isHovered: Bool
    let onSelect: () -> Void
    let onDoubleClick: () -> Void
    let onTogglePin: () -> Void
    let onDelete: () -> Void
    let onHover: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            // Type Icon, Color Swatch, or Image Thumbnail
            if clip.type == .color, let hex = clip.hexColor {
                Circle()
                    .fill(Color(hex: hex) ?? Color.gray)
                    .frame(width: 18, height: 18)
                    .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
            } else if clip.type == .image, let base64 = clip.imageThumbnailBase64, let data = Data(base64Encoded: base64), let img = NSImage(data: data) {
                Image(nsImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 22, height: 22)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 4, style: .continuous).stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
            } else {
                Image(systemName: clip.type.iconName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .secondary)
                    .frame(width: 18, height: 18)
            }
            
            // Text Snippet & Source
            VStack(alignment: .leading, spacing: 2) {
                Text(clip.displayTitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                HStack(spacing: 6) {
                    if let app = clip.sourceAppName {
                        Text(app)
                            .font(.system(size: 10))
                    }
                    Text("·")
                    Text(clip.timeAgoFormatted)
                        .font(.system(size: 10))
                }
                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            
            Spacer()
            
            // Quick hover actions or pin status indicator
            if isHovered && !isSelected {
                HStack(spacing: 6) {
                    Button(action: onTogglePin) {
                        Image(systemName: clip.isPinned ? "pin.fill" : "pin")
                            .font(.system(size: 10))
                            .foregroundColor(clip.isPinned ? .orange : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(clip.isPinned ? "Unpin Clip" : "Pin Clip (⌘P)")
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Delete Clip (⌘⌫)")
                }
            } else if clip.isPinned {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(isSelected ? Color.accentColor : (isHovered ? Color.primary.opacity(0.04) : Color.clear))
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                onHover(hovering)
            }
        }
        .onTapGesture {
            onSelect()
        }
        .simultaneousGesture(TapGesture(count: 2).onEnded {
            onDoubleClick()
        })
    }
}

// MARK: - Native Window Dragging Handle

public struct WindowDragHandleView: NSViewRepresentable {
    public init() {}
    
    public func makeNSView(context: Context) -> DraggingNSView {
        DraggingNSView()
    }
    
    public func updateNSView(_ nsView: DraggingNSView, context: Context) {}
}

public class DraggingNSView: NSView {
    public override var mouseDownCanMoveWindow: Bool { true }
    
    public override func mouseDown(with event: NSEvent) {
        if event.clickCount == 1 {
            window?.performDrag(with: event)
        } else {
            super.mouseDown(with: event)
        }
    }
}

// MARK: - NSVisualEffectView Wrapper

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// MARK: - Color Hex Initializer Extension

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        let length = hexSanitized.count
        let r, g, b, a: Double
        
        if length == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if length == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else if length == 3 {
            r = Double((rgb & 0xF00) >> 8) / 15.0
            g = Double((rgb & 0x0F0) >> 4) / 15.0
            b = Double(rgb & 0x00F) / 15.0
            a = 1.0
        } else {
            return nil
        }
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
