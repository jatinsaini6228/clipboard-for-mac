import SwiftUI
import AppKit

/// Settings & Preferences window view.
public struct PreferencesView: View {
    @ObservedObject var appState: AppState = .shared
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $appState.selectedPreferencesTab) {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(0)
            
            historyTab
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(1)
            
            privacyTab
                .tabItem {
                    Label("Privacy", systemImage: "hand.raised.fill")
                }
                .tag(2)
            
            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(3)
        }
        .frame(width: 480, height: 360)
        .padding()
        .onAppear {
            appState.isAccessibilityGranted = PasteService.isAccessibilityTrusted
        }
    }
    
    // MARK: - General Tab
    
    private var generalTab: some View {
        Form {
            Section(header: Text("Shortcuts & Activation").font(.headline)) {
                HStack {
                    Text("Global Search HUD:")
                    Spacer()
                    Text("⌘ ⇧ V")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.1)))
                }
            }
            
            Section(header: Text("Behavior").font(.headline)) {
                Toggle("Launch Clipboard at login", isOn: $appState.launchAtLogin)
                Toggle("Automatically copy new screenshots to clipboard", isOn: $appState.autoCaptureScreenshots)
                Toggle("Play sound effects on copy & paste", isOn: $appState.soundEnabled)
                
                VStack(alignment: .leading, spacing: 6) {
                    Toggle("Direct Paste into active app upon selection", isOn: $appState.directPasteEnabled)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(appState.isAccessibilityGranted ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        
                        Text(appState.isAccessibilityGranted ? "Accessibility Permission Granted" : "Accessibility Permission Required for Direct Paste")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        if !appState.isAccessibilityGranted {
                            Spacer()
                            Button("Open Settings") {
                                PasteService.requestAccessibilityPermissions()
                                PasteService.openAccessibilitySettings()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    appState.isAccessibilityGranted = PasteService.isAccessibilityTrusted
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    // MARK: - History Tab
    
    private var historyTab: some View {
        Form {
            Section(header: Text("Storage & Limits").font(.headline)) {
                Picker("Maximum items in history:", selection: $appState.maxHistoryCount) {
                    Text("50 items").tag(50)
                    Text("100 items").tag(100)
                    Text("200 items").tag(200)
                    Text("500 items").tag(500)
                    Text("1,000 items").tag(1000)
                }
                
                Text("Pinned items are preserved indefinitely and never pruned.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("Maintenance").font(.headline)) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Clear History")
                            .font(.system(size: 13, weight: .medium))
                        Text("Deletes all unpinned clips from local storage.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Clear Unpinned Clips", role: .destructive) {
                        appState.clearAllHistory()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding()
    }
    
    // MARK: - Privacy Tab
    
    private var privacyTab: some View {
        Form {
            Section(header: Text("Confidential Data Protection").font(.headline)) {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Password Manager Filter Active")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Payloads marked with concealed types by 1Password, Bitwarden, KeePassXC, and Apple Keychain are automatically dropped.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("Excluded Applications").font(.headline)) {
                Text("Credentials copied from Keychain Access and password managers are never recorded.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("• Keychain Access (com.apple.keychainaccess)")
                    Text("• 1Password (com.agilebits.onepassword)")
                    Text("• Bitwarden (com.bitwarden.desktop)")
                    Text("• KeePassXC (org.keepassxc.keepassxc)")
                }
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    // MARK: - About Tab
    
    private var aboutTab: some View {
        VStack(spacing: 16) {
            Image(systemName: "clipboard.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 4) {
                Text("Clipboard for Mac")
                    .font(.system(size: 18, weight: .bold))
                Text("Version 1.0.0 (Production Release)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Text("A native, ultra-lightweight, privacy-first clipboard history manager for macOS Sonoma, Sequoia, and macOS 27+.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Divider()
                .frame(width: 240)
            
            Text("Engineered with Swift 6, AppKit & SwiftUI.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
