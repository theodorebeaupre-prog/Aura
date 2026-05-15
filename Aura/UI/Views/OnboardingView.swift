import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 36) {
            // Hero
            VStack(spacing: 14) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)
                    .symbolEffect(.pulse)

                Text("Welcome to Aura")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Customize your macOS Tahoe experience")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            // Feature rows
            VStack(alignment: .leading, spacing: 20) {
                OnboardingFeatureRow(
                    icon: "slider.horizontal.3",
                    title: "Tweak System Defaults",
                    description: "Adjust animations, Dock behavior, menu bar, Finder, and more — all in one place."
                )
                OnboardingFeatureRow(
                    icon: "square.grid.2x2",
                    title: "Apply Presets",
                    description: "Use built-in presets for common setups, or save your own custom configuration."
                )
                OnboardingFeatureRow(
                    icon: "clock.arrow.circlepath",
                    title: "Automatic Backups",
                    description: "Every apply operation creates a backup so you can restore at any time."
                )
            }

            // Disclaimer
            GroupBox {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Aura writes macOS **system defaults** on your behalf. Some changes take effect only after a logout or restart. Always review what you apply.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Footer
            HStack(alignment: .center) {
                Link("View on GitHub", destination: URL(string: "https://github.com/theodorebeaupre-prog/Aura")!)
                    .font(.callout)
                Spacer()
                Button("Get Started") {
                    onComplete()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(44)
        .frame(minWidth: 560, idealWidth: 560, minHeight: 520, idealHeight: 520)
    }
}

// MARK: - Feature row

private struct OnboardingFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
