import Combine
import Foundation
import SwiftUI

struct BackupRecord: Identifiable {
    let id: UUID
    let date: Date
    let label: String
    let settingCount: Int
}

class MockDefaultsManager: ObservableObject, DefaultsManaging {
    @Published private(set) var settings: [SystemSetting] = MockDefaultsManager.defaultSettings
    @Published private(set) var presets: [Preset] = MockDefaultsManager.defaultPresets
    @Published private(set) var backups: [BackupRecord] = []

    private var store: [String: SettingValue] = [:]

    private static func storeKey(domain: String, key: String) -> String {
        "\(domain)/\(key)"
    }

    func read(key: String, domain: String) async throws -> SettingValue? {
        store[Self.storeKey(domain: domain, key: key)]
    }

    func write(setting: SystemSetting) async throws {
        store[Self.storeKey(domain: setting.domain, key: setting.key)] = setting.value
        if let idx = settings.firstIndex(where: { $0.key == setting.key && $0.domain == setting.domain }) {
            settings[idx] = SystemSetting(
                id: settings[idx].id,
                key: setting.key,
                domain: setting.domain,
                value: setting.value,
                category: setting.category
            )
        } else {
            settings.append(setting)
        }
    }

    func applyPreset(_ preset: Preset) async throws -> ApplyResult {
        for setting in preset.settings {
            try await write(setting: setting)
        }
        let record = BackupRecord(
            id: UUID(),
            date: Date(),
            label: preset.name,
            settingCount: preset.settings.count
        )
        backups.insert(record, at: 0)
        return ApplyResult(success: true, appliedCount: preset.settings.count, errors: [], backupID: record.id)
    }

    func preview(_ preset: Preset) -> [SettingDiff] {
        preset.settings.map { setting in
            SettingDiff(
                id: UUID(),
                key: setting.key,
                domain: setting.domain,
                oldValue: store[Self.storeKey(domain: setting.domain, key: setting.key)],
                newValue: setting.value
            )
        }
    }

    func reset(setting: SystemSetting) async throws {
        store.removeValue(forKey: Self.storeKey(domain: setting.domain, key: setting.key))
        if let original = Self.defaultSettings.first(where: { $0.key == setting.key && $0.domain == setting.domain }),
           let idx = settings.firstIndex(where: { $0.key == setting.key && $0.domain == setting.domain }) {
            settings[idx] = SystemSetting(
                id: settings[idx].id,
                key: original.key,
                domain: original.domain,
                value: original.value,
                category: original.category
            )
        }
    }

    func resetAll() async throws {
        store.removeAll()
        settings = Self.defaultSettings
        backups.removeAll()
    }

    func clearBackupsHistory() {
        backups.removeAll()
    }

    // MARK: - Sample data (stable UUIDs so reset can restore originals)

    static let defaultSettings: [SystemSetting] = [
        // Animations
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000001")!, key: "NSAutomaticWindowAnimationsEnabled", domain: "NSGlobalDomain", value: .bool(true), category: .animations),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000002")!, key: "NSWindowResizeTime", domain: "NSGlobalDomain", value: .double(0.2), category: .animations),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000003")!, key: "NSScrollAnimationEnabled", domain: "NSGlobalDomain", value: .bool(true), category: .animations),
        // Dock
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000010")!, key: "autohide", domain: "com.apple.dock", value: .bool(false), category: .dock),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000011")!, key: "tilesize", domain: "com.apple.dock", value: .double(48), category: .dock),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000012")!, key: "autohide-delay", domain: "com.apple.dock", value: .double(0.5), category: .dock),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000013")!, key: "magnification", domain: "com.apple.dock", value: .bool(true), category: .dock),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000014")!, key: "largesize", domain: "com.apple.dock", value: .double(72), category: .dock),
        // Menu Bar
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000020")!, key: "AppleMenuBarVisibleInFullscreen", domain: "NSGlobalDomain", value: .bool(true), category: .menuBar),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000021")!, key: "ShowSeconds", domain: "com.apple.menuextra.clock", value: .bool(false), category: .menuBar),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000022")!, key: "_HIHideMenuBar", domain: "NSGlobalDomain", value: .bool(false), category: .menuBar),
        // Transparency
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000030")!, key: "AppleEnableMenuBarTransparency", domain: "NSGlobalDomain", value: .bool(true), category: .transparency),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000031")!, key: "reduceTransparency", domain: "com.apple.universalaccess", value: .bool(false), category: .transparency),
        // Accessibility
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000040")!, key: "increaseContrast", domain: "com.apple.universalaccess", value: .bool(false), category: .accessibility),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000041")!, key: "reduceMotion", domain: "com.apple.universalaccess", value: .bool(false), category: .accessibility),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000042")!, key: "grayscale", domain: "com.apple.universalaccess", value: .bool(false), category: .accessibility),
        // Finder
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000050")!, key: "ShowPathbar", domain: "com.apple.finder", value: .bool(false), category: .finder),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000051")!, key: "ShowStatusBar", domain: "com.apple.finder", value: .bool(false), category: .finder),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000052")!, key: "FXPreferredViewStyle", domain: "com.apple.finder", value: .string("icnv"), category: .finder),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000053")!, key: "AppleShowAllFiles", domain: "com.apple.finder", value: .bool(false), category: .finder),
        // Other
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000060")!, key: "ApplePressAndHoldEnabled", domain: "NSGlobalDomain", value: .bool(true), category: .other),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000061")!, key: "KeyRepeat", domain: "NSGlobalDomain", value: .int(6), category: .other),
        SystemSetting(id: UUID(uuidString: "A0010000-0000-0000-0000-000000000062")!, key: "InitialKeyRepeat", domain: "NSGlobalDomain", value: .int(25), category: .other),
    ]

    static let defaultPresets: [Preset] = [
        Preset(
            id: UUID(uuidString: "B0010000-0000-0000-0000-000000000001")!,
            name: "Speed Boost",
            description: "Disables animations and reduces transparency for maximum performance",
            settings: [
                SystemSetting(id: UUID(), key: "NSAutomaticWindowAnimationsEnabled", domain: "NSGlobalDomain", value: .bool(false), category: .animations),
                SystemSetting(id: UUID(), key: "reduceTransparency", domain: "com.apple.universalaccess", value: .bool(true), category: .transparency),
                SystemSetting(id: UUID(), key: "reduceMotion", domain: "com.apple.universalaccess", value: .bool(true), category: .accessibility),
            ],
            createdAt: Date(timeIntervalSinceNow: -86400 * 7)
        ),
        Preset(
            id: UUID(uuidString: "B0010000-0000-0000-0000-000000000002")!,
            name: "Minimal Dock",
            description: "Compact auto-hiding dock without magnification",
            settings: [
                SystemSetting(id: UUID(), key: "autohide", domain: "com.apple.dock", value: .bool(true), category: .dock),
                SystemSetting(id: UUID(), key: "tilesize", domain: "com.apple.dock", value: .double(36), category: .dock),
                SystemSetting(id: UUID(), key: "magnification", domain: "com.apple.dock", value: .bool(false), category: .dock),
            ],
            createdAt: Date(timeIntervalSinceNow: -86400 * 3)
        ),
        Preset(
            id: UUID(uuidString: "B0010000-0000-0000-0000-000000000003")!,
            name: "Accessibility First",
            description: "High contrast with reduced motion for better accessibility",
            settings: [
                SystemSetting(id: UUID(), key: "increaseContrast", domain: "com.apple.universalaccess", value: .bool(true), category: .accessibility),
                SystemSetting(id: UUID(), key: "reduceMotion", domain: "com.apple.universalaccess", value: .bool(true), category: .accessibility),
                SystemSetting(id: UUID(), key: "reduceTransparency", domain: "com.apple.universalaccess", value: .bool(true), category: .transparency),
            ],
            createdAt: Date(timeIntervalSinceNow: -86400 * 1)
        ),
        Preset(
            id: UUID(uuidString: "B0010000-0000-0000-0000-000000000004")!,
            name: "Power User Finder",
            description: "Shows path bar, status bar, and hidden files in list view",
            settings: [
                SystemSetting(id: UUID(), key: "ShowPathbar", domain: "com.apple.finder", value: .bool(true), category: .finder),
                SystemSetting(id: UUID(), key: "ShowStatusBar", domain: "com.apple.finder", value: .bool(true), category: .finder),
                SystemSetting(id: UUID(), key: "AppleShowAllFiles", domain: "com.apple.finder", value: .bool(true), category: .finder),
                SystemSetting(id: UUID(), key: "FXPreferredViewStyle", domain: "com.apple.finder", value: .string("Nlsv"), category: .finder),
            ],
            createdAt: Date(timeIntervalSinceNow: -86400 * 5)
        ),
    ]
}
