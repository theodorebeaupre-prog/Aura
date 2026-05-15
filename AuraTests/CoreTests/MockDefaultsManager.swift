import Foundation
@testable import Aura

final class MockDefaultsManager: DefaultsManaging {
    var storage: [String: SettingValue] = [:]
    private(set) var writeCalls: [SystemSetting] = []
    private(set) var resetCalls: [SystemSetting] = []

    init(initialValues: [String: SettingValue] = [:]) {
        self.storage = initialValues
    }

    func read(key: String, domain: String) async throws -> SettingValue? {
        storage[storageKey(domain: domain, key: key)]
    }

    func write(setting: SystemSetting) async throws {
        writeCalls.append(setting)
        storage[storageKey(domain: setting.domain, key: setting.key)] = setting.value
    }

    func applyPreset(_ preset: Preset) async throws -> ApplyResult {
        for setting in preset.settings {
            try await write(setting: setting)
        }

        return ApplyResult(
            success: true,
            appliedCount: preset.settings.count,
            errors: [],
            backupID: nil
        )
    }

    func preview(_ preset: Preset) -> [SettingDiff] {
        preset.settings.map { setting in
            SettingDiff(
                id: UUID(),
                key: setting.key,
                domain: setting.domain,
                oldValue: storage[storageKey(domain: setting.domain, key: setting.key)],
                newValue: setting.value
            )
        }
    }

    func reset(setting: SystemSetting) async throws {
        resetCalls.append(setting)
        storage.removeValue(forKey: storageKey(domain: setting.domain, key: setting.key))
    }

    func resetAll() async throws {
        storage.removeAll()
    }

    private func storageKey(domain: String, key: String) -> String {
        "\(domain)::\(key)"
    }
}
