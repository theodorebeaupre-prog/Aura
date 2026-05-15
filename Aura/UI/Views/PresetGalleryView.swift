import SwiftUI

struct PresetGalleryView: View {
    @EnvironmentObject var manager: MockDefaultsManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var applyingPresetID: UUID? = nil
    @State private var statusMessage = ""
    @State private var showingCreateSheet = false

    private let columns = [GridItem(.adaptive(minimum: 220, maximum: 340))]

    private var theme: AuraTheme {
        themeManager.selectedTheme
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.canvasGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        galleryHero

                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(manager.presets) { preset in
                                PresetCardView(
                                    theme: theme,
                                    preset: preset,
                                    isApplying: applyingPresetID == preset.id,
                                    onApply: { applyPreset(preset) }
                                )
                            }
                            AddPresetCardView(isPresented: $showingCreateSheet, theme: theme)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Presets")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !statusMessage.isEmpty {
                    HStack {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(theme.material)
                }
            }
        }
        .frame(minWidth: 620, minHeight: 420)
    }

    private func applyPreset(_ preset: Preset) {
        applyingPresetID = preset.id
        Task {
            do {
                let result = try await manager.applyPreset(preset)
                statusMessage = result.success
                    ? "Applied \"\(preset.name)\" — \(result.appliedCount) setting\(result.appliedCount == 1 ? "" : "s") changed"
                    : "Failed to apply preset"
            } catch {
                statusMessage = error.localizedDescription
            }
            applyingPresetID = nil
            try? await Task.sleep(for: .seconds(3))
            statusMessage = ""
        }
    }

    private var galleryHero: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Theme-ready presets")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text("Built for quick switches. Pair system tweaks with the current visual mood so the app feels cohesive end-to-end.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(theme.previewGradient)
                .frame(width: 120, height: 92)
                .overlay {
                    Image(systemName: theme.symbol)
                        .font(.system(size: 34))
                        .foregroundStyle(.white.opacity(0.92))
                }
        }
        .padding(20)
        .auraCardStyle(theme: theme, radius: 24)
    }
}

// MARK: - Preset card

private struct PresetCardView: View {
    let theme: AuraTheme
    let preset: Preset
    let isApplying: Bool
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                Text(preset.name)
                    .font(.headline)
                Text(preset.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()

            Spacer(minLength: 8)

            Divider()

            HStack {
                Label(
                    "\(preset.settings.count) setting\(preset.settings.count == 1 ? "" : "s")",
                    systemImage: "slider.horizontal.3"
                )
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                Button(isApplying ? "Applying…" : "Apply") {
                    onApply()
                }
                .disabled(isApplying)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .frame(minHeight: 130)
        .padding(2)
        .auraCardStyle(theme: theme, radius: 18)
    }
}

// MARK: - Add preset card

private struct AddPresetCardView: View {
    @Binding var isPresented: Bool
    let theme: AuraTheme

    var body: some View {
        Button { isPresented = true } label: {
            VStack(spacing: 10) {
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundStyle(theme.accentStrong)
                Text("New Preset")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Text("Soon")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(theme.accentStrong)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(theme.accentSoft.opacity(0.7))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, minHeight: 130)
            .auraCardStyle(theme: theme, radius: 18)
        }
        .buttonStyle(.plain)
    }
}
