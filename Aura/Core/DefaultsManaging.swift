import Foundation

protocol DefaultsManaging {
    func read(key: String, domain: String) async throws -> SettingValue?
    func write(setting: SystemSetting) async throws
    func applyPreset(_ preset: Preset) async throws -> ApplyResult
    func preview(_ preset: Preset) -> [SettingDiff]
    func reset(setting: SystemSetting) async throws
    func resetAll() async throws
}
