import SwiftUI

@main
struct AuraApp: App {
    @StateObject private var manager = MockDefaultsManager()
    @StateObject private var themeManager = ThemeManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            CustomizerView()
                .environmentObject(manager)
                .environmentObject(themeManager)
                .tint(themeManager.selectedTheme.accent)
                .sheet(isPresented: Binding(get: { !hasCompletedOnboarding }, set: { _ in })) {
                    OnboardingView(onComplete: { hasCompletedOnboarding = true })
                        .environmentObject(themeManager)
                        .interactiveDismissDisabled()
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 940, height: 620)
    }
}
