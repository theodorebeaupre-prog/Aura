import Foundation

struct SettingDiff: Identifiable {
    let id: UUID
    let key: String
    let domain: String
    let oldValue: SettingValue?
    let newValue: SettingValue
}
