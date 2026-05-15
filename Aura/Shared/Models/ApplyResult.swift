import Foundation

struct ApplyResult: Codable {
    let success: Bool
    let appliedCount: Int
    let errors: [String]
    let backupID: UUID?
}
