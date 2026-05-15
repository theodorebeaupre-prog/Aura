import Foundation

struct BackupMetadata: Codable, Identifiable, Equatable {
    let id: UUID
    let createdAt: Date
    let settingCount: Int
}

final class BackupManager {
    private let defaultsManager: DefaultsManaging
    private let fileManager: FileManager
    private let backupsDirectory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        defaultsManager: DefaultsManaging,
        fileManager: FileManager = .default,
        backupsDirectory: URL? = nil
    ) {
        self.defaultsManager = defaultsManager
        self.fileManager = fileManager
        self.backupsDirectory = backupsDirectory ?? Self.defaultBackupsDirectory(fileManager: fileManager)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func backup(settings: [SystemSetting]) async throws -> UUID {
        try ensureBackupsDirectoryExists()

        let backupID = UUID()
        let createdAt = Date()
        var snapshots: [BackupSnapshot] = []

        for setting in settings {
            let currentValue = try await defaultsManager.read(key: setting.key, domain: setting.domain)
            snapshots.append(
                BackupSnapshot(
                    id: setting.id,
                    key: setting.key,
                    domain: setting.domain,
                    value: currentValue,
                    category: setting.category
                )
            )
        }

        let record = BackupRecord(
            metadata: BackupMetadata(
                id: backupID,
                createdAt: createdAt,
                settingCount: snapshots.count
            ),
            settings: snapshots
        )

        let data = try encoder.encode(record)
        try data.write(to: fileURL(for: backupID), options: .atomic)
        return backupID
    }

    func restore(backupID: UUID) async throws {
        let record = try loadRecord(for: backupID)

        for snapshot in record.settings {
            if let value = snapshot.value {
                let setting = SystemSetting(
                    id: snapshot.id,
                    key: snapshot.key,
                    domain: snapshot.domain,
                    value: value,
                    category: snapshot.category
                )

                try await defaultsManager.write(setting: setting)
            } else {
                let placeholder = SystemSetting(
                    id: snapshot.id,
                    key: snapshot.key,
                    domain: snapshot.domain,
                    value: .string(""),
                    category: snapshot.category
                )

                do {
                    try await defaultsManager.reset(setting: placeholder)
                } catch DefaultsError.notFound {
                    continue
                }
            }
        }
    }

    func listBackups() async throws -> [BackupMetadata] {
        try ensureBackupsDirectoryExists()

        let urls = try fileManager.contentsOfDirectory(
            at: backupsDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        let records = try urls.map(loadRecord(from:))
        return records
            .map(\.metadata)
            .sorted { $0.createdAt > $1.createdAt }
    }

    private func ensureBackupsDirectoryExists() throws {
        try fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
    }

    private func loadRecord(for backupID: UUID) throws -> BackupRecord {
        let url = fileURL(for: backupID)

        guard fileManager.fileExists(atPath: url.path) else {
            throw CocoaError(.fileNoSuchFile)
        }

        return try loadRecord(from: url)
    }

    private func loadRecord(from url: URL) throws -> BackupRecord {
        let data = try Data(contentsOf: url)
        return try decoder.decode(BackupRecord.self, from: data)
    }

    private func fileURL(for backupID: UUID) -> URL {
        backupsDirectory.appendingPathComponent("\(backupID.uuidString).json")
    }

    private static func defaultBackupsDirectory(fileManager: FileManager) -> URL {
        let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return applicationSupportDirectory
            .appendingPathComponent("Aura", isDirectory: true)
            .appendingPathComponent("Backups", isDirectory: true)
    }
}

private struct BackupRecord: Codable {
    let metadata: BackupMetadata
    let settings: [BackupSnapshot]
}

private struct BackupSnapshot: Codable {
    let id: UUID
    let key: String
    let domain: String
    let value: SettingValue?
    let category: Category
}
