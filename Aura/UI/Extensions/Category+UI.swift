import Foundation

extension Category {
    var displayName: String {
        switch self {
        case .animations:   return "Animations"
        case .dock:         return "Dock"
        case .menuBar:      return "Menu Bar"
        case .transparency: return "Transparency"
        case .accessibility:return "Accessibility"
        case .finder:       return "Finder"
        case .other:        return "Other"
        }
    }

    var systemImage: String {
        switch self {
        case .animations:   return "wand.and.stars"
        case .dock:         return "align.vertical.bottom"
        case .menuBar:      return "menubar.rectangle"
        case .transparency: return "square.on.square"
        case .accessibility:return "accessibility"
        case .finder:       return "folder"
        case .other:        return "gearshape"
        }
    }
}
