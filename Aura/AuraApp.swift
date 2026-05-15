import SwiftUI

@main
struct AuraApp: App {
    @StateObject private var manager = MockDefaultsManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            CustomizerView()
                .environmentObject(manager)
                .sheet(isPresented: Binding(get: { !hasCompletedOnboarding }, set: { _ in })) {
                    OnboardingView(onComplete: { hasCompletedOnboarding = true })
                        .interactiveDismissDisabled()
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 940, height: 620)
    }
}
