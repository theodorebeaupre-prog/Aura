import XCTest
@testable import Aura

final class BackupManagerTests: XCTestCase {
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

    func testBackupAndListBackupsUseInjectedDirectory() async throws {
        let defaultsManager = MockDefaultsManager(
            initialValues: [
                "com.apple.dock::autohide": .bool(true)
            ]
        )
        let manager = BackupManager(
            defaultsManager: defaultsManager,
            backupsDirectory: temporaryDirectoryURL
        )

        let settings = [
            SystemSetting(
                id: UUID(),
                key: "autohide",
                domain: "com.apple.dock",
                value: .bool(false),
                category: .dock
            )
        ]

        let backupID = try await manager.backup(settings: settings)
        let backups = try await manager.listBackups()

        XCTAssertEqual(backups.count, 1)
        XCTAssertEqual(backups.first?.id, backupID)
        XCTAssertEqual(backups.first?.settingCount, 1)

        let backupFileURL = temporaryDirectoryURL.appendingPathComponent("\(backupID.uuidString).json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupFileURL.path))
    }

    func testRestoreWritesExistingValuesAndDeletesMissingValues() async throws {
        let defaultsManager = MockDefaultsManager(
            initialValues: [
                "com.apple.dock::autohide": .bool(true),
                "NSGlobalDomain::AppleInterfaceStyle": .string("Dark")
            ]
        )
        let manager = BackupManager(
            defaultsManager: defaultsManager,
            backupsDirectory: temporaryDirectoryURL
        )

        let settings = [
            SystemSetting(
                id: UUID(),
                key: "autohide",
                domain: "com.apple.dock",
                value: .bool(false),
                category: .dock
            ),
            SystemSetting(
                id: UUID(),
                key: "AppleInterfaceStyle",
                domain: "NSGlobalDomain",
                value: .string("Light"),
                category: .other
            )
        ]

        let backupID = try await manager.backup(settings: settings)
        defaultsManager.storage["com.apple.dock::autohide"] = .bool(false)
        defaultsManager.storage.removeValue(forKey: "NSGlobalDomain::AppleInterfaceStyle")

        try await manager.restore(backupID: backupID)

        XCTAssertEqual(defaultsManager.storage["com.apple.dock::autohide"], .bool(true))
        XCTAssertEqual(defaultsManager.storage["NSGlobalDomain::AppleInterfaceStyle"], .string("Dark"))
        XCTAssertEqual(defaultsManager.writeCalls.count, 2)
    }
}
