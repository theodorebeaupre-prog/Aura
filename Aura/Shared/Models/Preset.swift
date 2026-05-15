import Foundation

struct Preset: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var settings: [SystemSetting]
    var createdAt: Date
}
