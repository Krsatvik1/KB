import SwiftUI
import AppKit

/// Root navigation state shared across views
// Removed because it now lives in AppState.swift

enum SidebarTab: String, CaseIterable, Identifiable {
    case connect = "Connect"
    case settings = "Settings"
    case updates = "Updates"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .connect: return "link.circle.fill"
        case .settings: return "slider.horizontal.3"
        case .updates: return "arrow.down.circle.fill"
        }
    }
}

struct ConnectView: View {
    @ObservedObject private var appState = AppState.shared
    @State private var selectedTab: SidebarTab = .connect
    @State private var isConnecting = false
    @State private var errorMessage: String? = nil
    @State private var showPairing = false
    @State private var isCheckingUpdates = false
    @State private var showUpToDateMessage = false

    // Settings
    @AppStorage("cmdToWin") var cmdToWin = true
    @AppStorage("optToAlt") var optToAlt = true
    @AppStorage("fnPassthrough") var fnPassthrough = true
    @AppStorage("mouseSensitivity") var mouseSensitivity: Double = 1.0

    var body: some View {
        ZStack {
            Color(hex: "0B0F1A").ignoresSafeArea()

            HStack(spacing: 0) {
                // ── Sidebar ────────────────────────────────────────────────
                VStack(spacing: 4) {
                    // Logo
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 40, height: 40)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                    ForEach(SidebarTab.allCases) { tab in
                        SidebarItem(tab: tab, selected: selectedTab == tab)
                            .onTapGesture { withAnimation(.easeOut(duration: 0.15)) { selectedTab = tab } }
                    }
                    Spacer()
                }
                .frame(width: 60)
                .background(Color(hex: "0D1120"))

                Rectangle()
                    .fill(Color(hex: "00D4FF").opacity(0.08))
                    .frame(width: 1)

                // ── Content ───────────────────────────────────────────────
                Group {
                    switch selectedTab {
                    case .connect: connectPanel
                    case .settings: settingsPanel
                    case .updates: updatesPanel
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $showPairing) {
            PairingView(pin: .constant("")) { pin in
                ConnectionManager.shared.submitPairingPin(pin)
                showPairing = false
            } onCancel: {
                ConnectionManager.shared.disconnect()
                showPairing = false
            }
        }
        .alert("Accessibility Access Required", isPresented: $appState.showAccessibilityAlert) {
            Button("Open System Settings") {
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                NSWorkspace.shared.open(url)
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("FlowDesk needs Accessibility permissions to share your keyboard and mouse with Windows. Please enable it in System Settings.")
        }
        .onAppear {
            startDiscovery()
            checkForUpdates()
        }
    }

    // MARK: - Connect Panel
    var connectPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            panelHeader("Connect to Windows")

            if let discovered = appState.autoDiscoveredIP {
                discoverBanner(discovered)
            }

            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Windows IP Address")
                FlowDeskTextField(placeholder: "192.168.1.x", text: $appState.serverIP)
            }

            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Port")
                FlowDeskTextField(placeholder: "5123", text: $appState.serverPort)
            }

            if let err = errorMessage {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "FF4566"))
            }

            HStack {
                Spacer()
                if isConnecting {
                    ProgressView().scaleEffect(0.7)
                        .tint(Color(hex: "00D4FF"))
                } else {
                    Button(appState.isConnected ? "Disconnect" : "Connect") {
                        if !checkAccessibility() { return }
                        appState.isConnected ? doDisconnect() : doConnect()
                    }
                    .buttonStyle(FlowDeskPrimaryButton())
                }
            }

            // Pairing history
            if !DeviceStore.shared.devices.isEmpty {
                Divider().background(Color(hex: "00D4FF").opacity(0.1))
                Text("Recent Devices")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(hex: "6B7280"))
                    .textCase(.uppercase)
                ForEach(Array(DeviceStore.shared.devices.values.prefix(3)), id: \.ip) { d in
                    deviceRow(d)
                }
            }

            Spacer()

            // Latency pill
            HStack(spacing: 6) {
                Circle()
                    .fill(appState.isConnected ? Color(hex: "00D4FF") : Color(hex: "FF4566"))
                    .frame(width: 7, height: 7)
                    .shadow(color: appState.isConnected ? Color(hex: "00D4FF") : .clear, radius: 4)
                Text(appState.isConnected ? "Connected · \(appState.latencyMs)ms" : "Disconnected")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "6B7280"))
                Spacer()
                Text("⎋⎋⎋ to release")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "6B7280").opacity(0.6))
            }
        }
        .padding(24)
    }

    // MARK: - Settings Panel
    var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            panelHeader("Settings")

            settingsToggle("⌘ Command → Win Key", on: $cmdToWin)
            settingsToggle("⌥ Option → Alt", on: $optToAlt)
            settingsToggle("Fn Keys Passthrough", on: $fnPassthrough)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    fieldLabel("Mouse Sensitivity")
                    Spacer()
                    Text(String(format: "%.1fx", mouseSensitivity))
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(Color(hex: "6B7280"))
                }
                Slider(value: $mouseSensitivity, in: 0.25...3.0, step: 0.25)
                    .accentColor(Color(hex: "00D4FF"))
            }

            Divider().background(Color(hex: "00D4FF").opacity(0.1))

            VStack(alignment: .leading, spacing: 6) {
                fieldLabel("Escape Method")
                Text("Press Esc × 3 within 1 second to instantly release control and return cursor to Mac.")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "6B7280"))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Updates Panel
    var updatesPanel: some View {
        VStack(alignment: .leading, spacing: 20) {
            panelHeader("Updates")

            HStack {
                fieldLabel("Current Version")
                Spacer()
                Text(Updater.shared.currentVersion)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(hex: "6B7280"))
            }

            if let update = appState.updateAvailable {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Circle().fill(Color(hex: "00D4FF")).frame(width: 8, height: 8)
                            .shadow(color: Color(hex: "00D4FF"), radius: 4)
                        Text("v\(update.version) available")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color(hex: "E8EAF6"))
                    }
                    Button("Download Update") {
                        NSWorkspace.shared.open(update.url)
                    }
                    .buttonStyle(FlowDeskPrimaryButton())
                }
            } else {
                Text(showUpToDateMessage ? "Just checked: Everything is current!" : "FlowDesk is up to date.")
                    .font(.system(size: 12))
                    .foregroundColor(showUpToDateMessage ? Color(hex: "00D4FF") : Color(hex: "6B7280"))
                    .animation(.default, value: showUpToDateMessage)
            }

            HStack {
                Spacer()
                if isCheckingUpdates {
                    ProgressView().scaleEffect(0.7)
                        .tint(Color(hex: "00D4FF"))
                } else {
                    Button("Check Now") { checkForUpdates() }
                        .buttonStyle(FlowDeskSecondaryButton())
                }
            }

            Spacer()
        }
        .padding(24)
    }

    // MARK: - Helpers

    func checkAccessibility() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : false]
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        if !isTrusted {
            appState.showAccessibilityAlert = true
        }
        return isTrusted
    }

    func doConnect() {
        guard !appState.serverIP.isEmpty else { errorMessage = "Enter a Windows IP address."; return }
        isConnecting = true
        errorMessage = nil
        let port = UInt16(appState.serverPort) ?? 5123
        UserDefaults.standard.set(appState.serverIP, forKey: "lastIP")
        UserDefaults.standard.set(appState.serverPort, forKey: "lastPort")
        ConnectionManager.shared.connect(host: appState.serverIP, port: port) { result in
            DispatchQueue.main.async {
                isConnecting = false
                switch result {
                case .success:
                    appState.isConnected = true
                case .requiresPairing:
                    showPairing = true
                case .failure(let msg):
                    errorMessage = msg
                }
            }
        }
    }

    func doDisconnect() {
        ConnectionManager.shared.disconnect()
        appState.isConnected = false
    }

    func startDiscovery() {
        DiscoveryListener.shared.onDiscovered = { ip, _ in
            if appState.serverIP.isEmpty || appState.autoDiscoveredIP == nil {
                appState.autoDiscoveredIP = ip
                appState.serverIP = ip
            }
        }
        DiscoveryListener.shared.start()
    }

    func checkForUpdates() {
        isCheckingUpdates = true
        showUpToDateMessage = false
        Updater.shared.checkForUpdates { info in
            DispatchQueue.main.async { 
                appState.updateAvailable = info
                isCheckingUpdates = false
                if info == nil {
                    showUpToDateMessage = true
                    // Hide message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        showUpToDateMessage = false
                    }
                }
            }
        }
    }

    // MARK: - Sub-components

    func panelHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(Color(hex: "E8EAF6"))
    }

    func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color(hex: "6B7280"))
    }

    func settingsToggle(_ label: String, on: Binding<Bool>) -> some View {
        Toggle(isOn: on) {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "E8EAF6"))
        }
        .toggleStyle(SwitchToggleStyle(tint: Color(hex: "00D4FF")))
    }

    func discoverBanner(_ ip: String) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(hex: "00D4FF"))
                .frame(width: 7, height: 7)
                .shadow(color: Color(hex: "00D4FF"), radius: 4)
            Text("FlowDesk found on \(ip)")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "00D4FF"))
            Spacer()
            Button("Use") { appState.serverIP = ip }
                .buttonStyle(FlowDeskSecondaryButton())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: "00D4FF").opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(hex: "00D4FF").opacity(0.2), lineWidth: 1)
        )
    }

    func deviceRow(_ device: PairedDevice) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(device.ip)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(Color(hex: "E8EAF6"))
                Text("Last connected · \(device.lastSeen.formatted(.relative(presentation: .named)))")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: "6B7280"))
            }
            Spacer()
            Button("Connect") {
                appState.serverIP = device.ip
                selectedTab = .connect
            }
            .buttonStyle(FlowDeskSecondaryButton())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: "111827"))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Sidebar item

private struct SidebarItem: View {
    let tab: SidebarTab
    let selected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: tab.icon)
                .font(.system(size: 18))
                .foregroundColor(selected ? Color(hex: "00D4FF") : Color(hex: "6B7280"))
                .shadow(color: selected ? Color(hex: "00D4FF").opacity(0.6) : .clear, radius: 6)
        }
        .frame(width: 60, height: 54)
        .contentShape(Rectangle())
        .background(selected ? Color(hex: "00D4FF").opacity(0.08) : Color.clear)
    }
}
