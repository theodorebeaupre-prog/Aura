import SwiftUI

struct CustomizerView: View {
    @EnvironmentObject var manager: MockDefaultsManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedCategory: Category? = .dock
    @State private var pendingValues: [UUID: SettingValue] = [:]
    @State private var statusMessage = ""
    @State private var isApplying = false
    @State private var showingPresetGallery = false
    @State private var showingPreview = false
    @State private var showingBackups = false

    private var filteredSettings: [SystemSetting] {
        guard let category = selectedCategory else { return [] }
        return manager.settings.filter { $0.category == category }
    }

    private var pendingPreset: Preset {
        let modified: [SystemSetting] = manager.settings.compactMap { setting in
            guard let newValue = pendingValues[setting.id] else { return nil }
            return SystemSetting(id: setting.id, key: setting.key, domain: setting.domain, value: newValue, category: setting.category)
        }
        return Preset(id: UUID(), name: "Preview", description: "", settings: modified, createdAt: Date())
    }

    private var theme: AuraTheme {
        themeManager.selectedTheme
    }

    var body: some View {
        ZStack {
            theme.canvasGradient
                .ignoresSafeArea()

            glowOrbs
                .ignoresSafeArea()

            NavigationSplitView {
                sidebarContent
                    .navigationSplitViewColumnWidth(min: 180, ideal: 220)
                    .scrollContentBackground(.hidden)
                    .background(theme.panelGradient.opacity(0.74))
            } detail: {
                detailContent
                    .scrollContentBackground(.hidden)
                    .background(theme.panelGradient.opacity(0.38))
            }
        }
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { statusBar }
        .sheet(isPresented: $showingPresetGallery) {
            PresetGalleryView()
                .environmentObject(manager)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingPreview) {
            LivePreviewView(previewPreset: pendingPreset)
                .environmentObject(manager)
                .environmentObject(themeManager)
        }
        .sheet(isPresented: $showingBackups) {
            BackupView()
                .environmentObject(manager)
                .environmentObject(themeManager)
        }
    }

    // MARK: - Sidebar

    private var sidebarContent: some View {
        List(Category.allCases, id: \.self, selection: $selectedCategory) { category in
            Label {
                HStack {
                    Text(category.displayName)
                    Spacer()
                    let count = pendingCount(for: category)
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(theme.accent)
                            .clipShape(Capsule())
                    }
                }
            } icon: {
                Image(systemName: category.systemImage)
            }
        }
        .listRowBackground(theme.cardFill.opacity(0.35))
        .navigationTitle("Aura")
        .safeAreaInset(edge: .top, spacing: 10) {
            headerHero
                .padding(.horizontal, 12)
                .padding(.top, 10)
        }
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailContent: some View {
        if let category = selectedCategory {
            List {
                Section {
                    ForEach(filteredSettings) { setting in
                        SettingsRowView(
                            setting: setting,
                            pendingValue: pendingBinding(for: setting)
                        )
                        .environmentObject(themeManager)
                    }
                } header: {
                    detailHeader(category: category)
                }
            }
            .listStyle(.inset)
            .navigationTitle(category.displayName)
            .background(Color.clear)
        } else {
            ContentUnavailableView(
                "No Category Selected",
                systemImage: "sidebar.left",
                description: Text("Choose a category from the sidebar.")
            )
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button("Presets", systemImage: "square.grid.2x2") {
                showingPresetGallery = true
            }
            Button("Backups", systemImage: "clock.arrow.circlepath") {
                showingBackups = true
            }
            ThemePickerView()
                .environmentObject(themeManager)
        }
        ToolbarItemGroup(placement: .primaryAction) {
            if !pendingValues.isEmpty {
                Button("Discard", systemImage: "arrow.uturn.backward") {
                    pendingValues.removeAll()
                    setStatus("Changes discarded")
                }
                .foregroundStyle(.secondary)
            }
            Button("Preview", systemImage: "eye") {
                showingPreview = true
            }
            .disabled(pendingValues.isEmpty)
            Button(isApplying ? "Applying…" : "Apply") {
                applyPendingChanges()
            }
            .disabled(pendingValues.isEmpty || isApplying)
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Status bar

    @ViewBuilder
    private var statusBar: some View {
        if !statusMessage.isEmpty || !pendingValues.isEmpty || !themeManager.systemAccentStatusMessage.isEmpty {
            HStack(spacing: 10) {
                if !pendingValues.isEmpty {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(theme.statusDot)
                            .frame(width: 6, height: 6)
                        Text("\(pendingValues.count) unsaved change\(pendingValues.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if !themeManager.systemAccentStatusMessage.isEmpty {
                    Text(themeManager.systemAccentStatusMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(theme.material)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(theme.stroke.opacity(0.8))
                    .frame(height: 1)
            }
        }
    }

    private var headerHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Aura")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text(theme.name)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.accentStrong)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(theme.previewGradient)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: theme.symbol)
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
            }

            Text("Tune Tahoe with a theme-aware workspace and calmer visual presets.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Circle()
                    .fill(themeManager.osxColorsStatus.isInstalled ? .green : .orange)
                    .frame(width: 8, height: 8)
                Text(themeManager.osxColorsStatus.isInstalled ? "macOS accent integration ready" : "`osx-colors` not installed yet")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ThemePickerView()
                .environmentObject(themeManager)
        }
        .padding(14)
        .auraCardStyle(theme: theme)
    }

    private func detailHeader(category: Category) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.displayName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            Text("Adjust live values, preview the diff, then apply everything in one clean pass.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 8)
    }

    private var glowOrbs: some View {
        ZStack {
            Circle()
                .fill(theme.heroGlow.opacity(0.35))
                .frame(width: 280, height: 280)
                .blur(radius: 40)
                .offset(x: -280, y: -180)
            Circle()
                .fill(theme.accentSoft.opacity(0.22))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .offset(x: 300, y: 260)
        }
    }

    // MARK: - Helpers

    private func pendingBinding(for setting: SystemSetting) -> Binding<SettingValue?> {
        Binding(
            get: { pendingValues[setting.id] },
            set: { newValue in
                if let newValue {
                    pendingValues[setting.id] = newValue
                } else {
                    pendingValues.removeValue(forKey: setting.id)
                }
            }
        )
    }

    private func pendingCount(for category: Category) -> Int {
        pendingValues.keys.filter { id in
            manager.settings.first(where: { $0.id == id })?.category == category
        }.count
    }

    private func applyPendingChanges() {
        guard !pendingValues.isEmpty else { return }
        isApplying = true
        let modified: [SystemSetting] = manager.settings.compactMap { setting in
            guard let newValue = pendingValues[setting.id] else { return nil }
            return SystemSetting(id: setting.id, key: setting.key, domain: setting.domain, value: newValue, category: setting.category)
        }
        let preset = Preset(id: UUID(), name: "Manual Changes", description: "Applied via settings panel", settings: modified, createdAt: Date())
        Task {
            do {
                let result = try await manager.applyPreset(preset)
                if result.success {
                    setStatus("Applied \(result.appliedCount) change\(result.appliedCount == 1 ? "" : "s")")
                } else {
                    setStatus("Failed: \(result.errors.joined(separator: ", "))")
                }
                pendingValues.removeAll()
            } catch {
                setStatus("Error: \(error.localizedDescription)")
            }
            isApplying = false
        }
    }

    private func setStatus(_ message: String) {
        statusMessage = message
        Task {
            try? await Task.sleep(for: .seconds(3))
            if statusMessage == message { statusMessage = "" }
        }
    }
}
