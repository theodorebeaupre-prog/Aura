import Combine
import Foundation

final class ThemeManager: ObservableObject {
    @Published private(set) var selectedTheme: AuraTheme

    private let defaults: UserDefaults
    private let storageKey = "selectedThemeID"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if
            let storedID = defaults.string(forKey: storageKey),
            let theme = AuraTheme.all.first(where: { $0.id == storedID })
        {
            selectedTheme = theme
        } else {
            selectedTheme = .sakura
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
}
