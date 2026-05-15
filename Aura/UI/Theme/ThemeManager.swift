import Combine
import Foundation

@MainActor
final class ThemeManager: ObservableObject {
    @Published private(set) var selectedTheme: AuraTheme
    @Published private(set) var osxColorsStatus = OSXColorsStatus(isInstalled: false, executablePath: nil)
    @Published private(set) var systemAccentStatusMessage = ""
    @Published private(set) var isApplyingSystemAccent = false
    @Published private(set) var isInstallingOSXColors = false

    private let defaults: UserDefaults
    private let storageKey = "selectedThemeID"
    private let osxColorsService: OSXColorsService

    init(
        defaults: UserDefaults = .standard,
        osxColorsService: OSXColorsService? = nil
    ) {
        self.defaults = defaults
        self.osxColorsService = osxColorsService ?? OSXColorsService()

        if
            let storedID = defaults.string(forKey: storageKey),
            let theme = AuraTheme.all.first(where: { $0.id == storedID })
        {
            selectedTheme = theme
        } else {
            selectedTheme = .sakura
        }

        Task {
            await refreshOSXColorsStatus()
        }
    }

    var themes: [AuraTheme] {
        AuraTheme.all
    }

    func selectTheme(_ theme: AuraTheme) {
        guard selectedTheme != theme else { return }
        selectedTheme = theme
        defaults.set(theme.id, forKey: storageKey)
    }

    func refreshOSXColorsStatus() async {
        osxColorsStatus = await osxColorsService.status()
    }

    func applySelectedThemeToMacOSAccent() async {
        guard !isApplyingSystemAccent else { return }
        isApplyingSystemAccent = true
        defer { isApplyingSystemAccent = false }

        do {
            try await osxColorsService.apply(colorInput: selectedTheme.systemAccentInput)
            await refreshOSXColorsStatus()
            systemAccentStatusMessage = "Applied \(selectedTheme.name) to macOS accent + highlight."
        } catch {
            systemAccentStatusMessage = error.localizedDescription
        }
    }

    func installOSXColors() async {
        guard !isInstallingOSXColors else { return }
        isInstallingOSXColors = true
        defer { isInstallingOSXColors = false }

        do {
            try await osxColorsService.install()
            await refreshOSXColorsStatus()
            systemAccentStatusMessage = "`osx-colors` installed. You can now apply the macOS accent from Aura."
        } catch {
            systemAccentStatusMessage = error.localizedDescription
        }
    }

    func openOSXColorsInstallPage() {
        osxColorsService.openInstallPage()
    }

    var osxColorsInstallCommand: String {
        osxColorsService.installCommand
    }
}
