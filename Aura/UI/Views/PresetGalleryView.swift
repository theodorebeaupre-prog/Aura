import SwiftUI

struct PresetGalleryView: View {
    @EnvironmentObject var manager: MockDefaultsManager
    @Environment(\.dismiss) private var dismiss
    @State private var applyingPresetID: UUID? = nil
    @State private var statusMessage = ""
    @State private var showingCreateSheet = false

    private let columns = [GridItem(.adaptive(minimum: 220, maximum: 340))]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(manager.presets) { preset in
                        PresetCardView(
                            preset: preset,
                            isApplying: applyingPresetID == preset.id,
                            onApply: { applyPreset(preset) }
                        )
                    }
                    AddPresetCardView(isPresented: $showingCreateSheet)
                }
                .padding()
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
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(.bar)
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
}

// MARK: - Preset card

private struct PresetCardView: View {
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
        .background(.background.secondary)
        // TODO: VERIFY macOS 26 Liquid Glass API — replace with .glassEffect() if available
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.separator, lineWidth: 0.5)
        }
    }
}

// MARK: - Add preset card

private struct AddPresetCardView: View {
    @Binding var isPresented: Bool

    var body: some View {
        Button { isPresented = true } label: {
            VStack(spacing: 10) {
                Image(systemName: "plus.circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("New Preset")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 130)
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.separator.opacity(0.6), lineWidth: 0.5, antialiased: true)
            }
        }
        .buttonStyle(.plain)
    }
}
