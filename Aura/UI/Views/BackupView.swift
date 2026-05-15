import SwiftUI

struct BackupView: View {
    @EnvironmentObject var manager: MockDefaultsManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var restoringID: UUID? = nil
    @State private var statusMessage = ""
    @State private var showingResetConfirm = false

    private var theme: AuraTheme {
        themeManager.selectedTheme
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.canvasGradient
                    .ignoresSafeArea()

                Group {
                    if manager.backups.isEmpty {
                        ContentUnavailableView(
                            "No Backups Yet",
                            systemImage: "clock.arrow.circlepath",
                            description: Text("Backups are created automatically each time you apply a preset or changes.")
                        )
                        .auraCardStyle(theme: theme, radius: 22)
                        .padding(24)
                    } else {
                        List(manager.backups) { backup in
                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .foregroundStyle(theme.accentStrong)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text(backup.label)
                                        .font(.callout)
                                        .fontWeight(.medium)
                                    HStack(spacing: 6) {
                                        Text("\(backup.date, style: .relative) ago")
                                        Text("·")
                                            .foregroundStyle(.tertiary)
                                        Text("\(backup.settingCount) setting\(backup.settingCount == 1 ? "" : "s")")
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button(restoringID == backup.id ? "Restoring…" : "Restore") {
                                    restore(backup)
                                }
                                .disabled(restoringID != nil)
                                .controlSize(.small)
                            }
                            .padding(.vertical, 6)
                        }
                        .listStyle(.inset)
                        .scrollContentBackground(.hidden)
                        .padding(18)
                    }
                }
            }
            .navigationTitle("Backups")
            .toolbar {
                ToolbarItem(placement: .destructiveAction) {
                    Button("Clear History", role: .destructive) {
                        showingResetConfirm = true
                    }
                    .disabled(manager.backups.isEmpty)
                }
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
            .confirmationDialog(
                "Clear backup history?",
                isPresented: $showingResetConfirm,
                titleVisibility: .visible
            ) {
                Button("Clear History", role: .destructive) {
                    manager.clearBackupsHistory()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes the backup list. Your current system settings are not affected.")
            }
        }
        .frame(minWidth: 520, minHeight: 320)
    }

    private func restore(_ backup: BackupRecord) {
        restoringID = backup.id
        Task {
            // Simulates a restore delay; production Core/ would restore from the actual backup snapshot.
            try? await Task.sleep(for: .milliseconds(600))
            try? await manager.resetAll()
            statusMessage = "Restored \"\(backup.label)\""
            restoringID = nil
            try? await Task.sleep(for: .seconds(3))
            statusMessage = ""
        }
    }
}
