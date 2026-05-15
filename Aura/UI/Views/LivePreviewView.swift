import SwiftUI

struct LivePreviewView: View {
    @EnvironmentObject var manager: MockDefaultsManager
    @Environment(\.dismiss) private var dismiss
    var previewPreset: Preset?

    private var diffs: [SettingDiff] {
        guard let preset = previewPreset else { return [] }
        return manager.preview(preset)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mockDesktop
                    .padding()

                Divider()

                changesSection
            }
            .navigationTitle("Preview")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: 700, minHeight: 520)
    }

    // MARK: - Mock desktop

    private var mockDesktop: some View {
        ZStack(alignment: .top) {
            // Wallpaper gradient
            LinearGradient(
                colors: [
                    Color(NSColor.systemBlue).opacity(0.5),
                    Color(NSColor.systemPurple).opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 0) {
                fakeMenuBar
                Spacer()
                fakeDock
                    .padding(.bottom, 10)
            }
        }
        .frame(height: 240)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(.separator, lineWidth: 0.5)
        }
    }

    private var fakeMenuBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "apple.logo")
                .font(.caption)
                .fontWeight(.semibold)
            Text("Finder")
                .font(.caption)
                .fontWeight(.semibold)
            ForEach(["File", "Edit", "View", "Go", "Window"], id: \.self) { item in
                Text(item)
                    .font(.caption)
            }
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "wifi")
                Image(systemName: "battery.100")
                Text(Date(), style: .time)
            }
            .font(.caption)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        // TODO: VERIFY macOS 26 Liquid Glass API — replace with .glassEffect() if available
    }

    private var fakeDock: some View {
        let icons: [(String, String)] = [
            ("folder", "Finder"),
            ("safari", "Safari"),
            ("envelope", "Mail"),
            ("bubble.left.and.bubble.right.fill", "Messages"),
            ("music.note", "Music"),
            ("photo", "Photos"),
        ]
        return HStack(spacing: 6) {
            ForEach(icons, id: \.0) { icon, label in
                RoundedRectangle(cornerRadius: 7)
                    .fill(.ultraThinMaterial)
                    .frame(width: 30, height: 30)
                    .overlay {
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundStyle(.white)
                    }
                    .help(label)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        // TODO: VERIFY macOS 26 Liquid Glass API — replace with .glassEffect() if available
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Changes list

    @ViewBuilder
    private var changesSection: some View {
        if diffs.isEmpty {
            ContentUnavailableView(
                "No Pending Changes",
                systemImage: "checkmark.circle",
                description: Text("Modify settings in the main window to preview changes here.")
            )
        } else {
            List(diffs) { diff in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(diff.key)
                            .font(.callout)
                        Text(diff.domain)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if let old = diff.oldValue {
                        Text(old.displayString)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .strikethrough()
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    Text(diff.newValue.displayString)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.accentColor)
                }
                .padding(.vertical, 2)
            }
            .listStyle(.inset)
        }
    }
}
