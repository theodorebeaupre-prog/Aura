import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let onComplete: () -> Void

    private var theme: AuraTheme {
        themeManager.selectedTheme
    }

    var body: some View {
        ZStack {
            theme.canvasGradient
                .ignoresSafeArea()

            VStack(spacing: 36) {
                VStack(spacing: 14) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(theme.previewGradient)
                        .frame(width: 112, height: 112)
                        .overlay {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 42))
                                .foregroundStyle(.white)
                                .symbolEffect(.pulse)
                        }
                        .shadow(color: theme.heroGlow.opacity(0.42), radius: 28, x: 0, y: 16)

                    Text("Welcome to Aura")
                        .font(.system(size: 34, weight: .bold, design: .rounded))

                    Text("Customize your macOS Tahoe experience")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 20) {
                    OnboardingFeatureRow(
                        theme: theme,
                        icon: "slider.horizontal.3",
                        title: "Tweak System Defaults",
                        description: "Adjust animations, Dock behavior, menu bar, Finder, and more — all in one place."
                    )
                    OnboardingFeatureRow(
                        theme: theme,
                        icon: "square.grid.2x2",
                        title: "Apply Presets",
                        description: "Use built-in presets for common setups, or save your own custom configuration."
                    )
                    OnboardingFeatureRow(
                        theme: theme,
                        icon: "paintpalette.fill",
                        title: "Switch Themes",
                        description: "Move between Sakura, Tidal, Ember, and Nocturne without breaking the rest of the interface."
                    )
                }

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

                HStack(alignment: .center) {
                    Link("View on GitHub", destination: URL(string: "https://github.com/theodorebeaupre-prog/Aura")!)
                        .font(.callout)
                    Spacer()
                    ThemePickerView()
                        .environmentObject(themeManager)
                    Button("Get Started") {
                        onComplete()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(44)
            .frame(minWidth: 560, idealWidth: 560, minHeight: 520, idealHeight: 520)
            .auraCardStyle(theme: theme, radius: 30)
            .padding(20)
        }
    }
}

// MARK: - Feature row

private struct OnboardingFeatureRow: View {
    let theme: AuraTheme
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(theme.accentSoft.opacity(0.8))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: icon)
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(theme.accentStrong)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.semibold)
                Text(description)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}
