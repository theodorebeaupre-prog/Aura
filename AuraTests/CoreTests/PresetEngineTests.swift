import XCTest
@testable import Aura

final class PresetEngineTests: XCTestCase {
    private var temporaryDirectoryURL: URL!

    override func setUpWithError() throws {
        temporaryDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectoryURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        if let temporaryDirectoryURL {
            try? FileManager.default.removeItem(at: temporaryDirectoryURL)
        }
    }

    func testImportExportRoundTrip() async throws {
        let defaultsManager = MockDefaultsManager()
        let backupManager = BackupManager(
            defaultsManager: defaultsManager,
            backupsDirectory: temporaryDirectoryURL.appendingPathComponent("Backups", isDirectory: true)
        )
        let engine = PresetEngine(
            defaultsManager: defaultsManager,
            backupManager: backupManager,
            presetsDirectory: temporaryDirectoryURL.appendingPathComponent("Presets", isDirectory: true),
            builtInPresetsDirectory: temporaryDirectoryURL.appendingPathComponent("BuiltIns", isDirectory: true)
        )

        let preset = Preset(
            id: UUID(),
            name: "Focus Mode",
            description: "Reduce motion-heavy window and Dock behavior.",
            settings: [
                SystemSetting(
                    id: UUID(),
                    key: "launchanim",
                    domain: "com.apple.dock",
                    value: .bool(false),
                    category: .dock
                ),
                SystemSetting(
                    id: UUID(),
                    key: "NSWindowResizeTime",
                    domain: "NSGlobalDomain",
                    value: .double(0.001),
                    category: .animations
                )
            ],
            createdAt: Date(timeIntervalSince1970: 1_700_000_000)
        )

        let exportURL = temporaryDirectoryURL.appendingPathComponent("exported-preset.json")
        try await engine.exportPreset(preset, to: exportURL)
        let importedPreset = try await engine.importPreset(from: exportURL)

        XCTAssertEqual(importedPreset.id, preset.id)
        XCTAssertEqual(importedPreset.name, preset.name)
        XCTAssertEqual(importedPreset.description, preset.description)
        XCTAssertEqual(importedPreset.settings.count, preset.settings.count)
        XCTAssertEqual(importedPreset.createdAt, preset.createdAt)
    }
}
