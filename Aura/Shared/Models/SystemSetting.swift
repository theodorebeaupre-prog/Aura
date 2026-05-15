import Foundation

struct SystemSetting: Codable, Identifiable {
    let id: UUID
    let key: String
    let domain: String
    let value: SettingValue
    let category: Category
}
