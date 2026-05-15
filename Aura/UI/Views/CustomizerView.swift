import SwiftUI

struct CustomizerView: View {
    @EnvironmentObject var manager: MockDefaultsManager
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

    var body: some View {
        NavigationSplitView {
            sidebarContent
                .navigationSplitViewColumnWidth(min: 165, ideal: 195)
        } detail: {
            detailContent
        }
        .toolbar { toolbarContent }
        .safeAreaInset(edge: .bottom) { statusBar }
        .sheet(isPresented: $showingPresetGallery) {
            PresetGalleryView().environmentObject(manager)
        }
        .sheet(isPresented: $showingPreview) {
            LivePreviewView(previewPreset: pendingPreset).environmentObject(manager)
        }
        .sheet(isPresented: $showingBackups) {
            BackupView().environmentObject(manager)
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
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
            } icon: {
                Image(systemName: category.systemImage)
            }
        }
        .navigationTitle("Aura")
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailContent: some View {
        if let category = selectedCategory {
            List {
                Section(category.displayName) {
                    ForEach(filteredSettings) { setting in
                        SettingsRowView(
                            setting: setting,
                            pendingValue: pendingBinding(for: setting)
                        )
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle(category.displayName)
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
        if !statusMessage.isEmpty || !pendingValues.isEmpty {
            HStack(spacing: 10) {
                if !pendingValues.isEmpty {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(.orange)
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
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.bar)
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
