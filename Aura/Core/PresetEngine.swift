import Foundation

enum PresetEngineError: Error, Equatable {
    case invalidPreset([String])
    case builtInPresetsDirectoryNotFound
}

final class PresetEngine {
    private let defaultsManager: DefaultsManaging
    private let backupManager: BackupManager
    private let fileManager: FileManager
    private let presetsDirectory: URL
    private let builtInPresetsDirectory: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(
        defaultsManager: DefaultsManaging,
        backupManager: BackupManager,
        fileManager: FileManager = .default,
        presetsDirectory: URL? = nil,
        builtInPresetsDirectory: URL? = PresetEngine.resolveBuiltInPresetsDirectory()
    ) {
        self.defaultsManager = defaultsManager
        self.backupManager = backupManager
        self.fileManager = fileManager
        self.presetsDirectory = presetsDirectory ?? Self.defaultPresetsDirectory(fileManager: fileManager)
        self.builtInPresetsDirectory = builtInPresetsDirectory

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func savePreset(_ preset: Preset) async throws {
        try validateOrThrow(preset)
        try ensurePresetsDirectoryExists()

        let data = try encoder.encode(preset)
        try data.write(to: fileURL(for: preset.id), options: .atomic)
    }

    func loadSavedPresets() async throws -> [Preset] {
        try ensurePresetsDirectoryExists()

        let urls = try fileManager.contentsOfDirectory(
            at: presetsDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        return try urls
            .map(loadPreset(from:))
            .sorted { $0.createdAt > $1.createdAt }
    }

    func exportPreset(_ preset: Preset, to url: URL) async throws {
        try validateOrThrow(preset)
        let data = try encoder.encode(preset)
        try data.write(to: url, options: .atomic)
    }

    func importPreset(from url: URL) async throws -> Preset {
        let preset = try loadPreset(from: url)
        try validateOrThrow(preset)
        return preset
    }

    func loadBuiltInPresets() async throws -> [Preset] {
        guard let builtInPresetsDirectory else {
            throw PresetEngineError.builtInPresetsDirectoryNotFound
        }

        let urls = try fileManager.contentsOfDirectory(
            at: builtInPresetsDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }

        return try urls
            .map(loadPreset(from:))
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func apply(_ preset: Preset) async throws -> ApplyResult {
        try validateOrThrow(preset)
        let backupID = try await backupManager.backup(settings: preset.settings)
        let result = try await defaultsManager.applyPreset(preset)

        return ApplyResult(
            success: result.success,
            appliedCount: result.appliedCount,
            errors: result.errors,
            backupID: backupID
        )
    }

    func validate(_ preset: Preset) -> [String] {
        var errors: [String] = []

        if preset.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Preset name must not be empty.")
        }

        if preset.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Preset description must not be empty.")
        }

        if preset.settings.isEmpty {
            errors.append("Preset must include at least one setting.")
        }

        var seenSettingIdentifiers: Set<String> = []
        for setting in preset.settings {
            if setting.key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append("Setting key must not be empty.")
            }

            if setting.domain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.append("Setting domain must not be empty.")
            }

            let identifier = "\(setting.domain)::\(setting.key)"
            if !seenSettingIdentifiers.insert(identifier).inserted {
                errors.append("Duplicate setting detected for \(setting.domain)/\(setting.key).")
            }
        }

        return errors
    }

    private func validateOrThrow(_ preset: Preset) throws {
        let errors = validate(preset)
        guard errors.isEmpty else {
            throw PresetEngineError.invalidPreset(errors)
        }
    }

    private func ensurePresetsDirectoryExists() throws {
        try fileManager.createDirectory(at: presetsDirectory, withIntermediateDirectories: true)
    }

    private func loadPreset(from url: URL) throws -> Preset {
        let data = try Data(contentsOf: url)
        return try decoder.decode(Preset.self, from: data)
    }

    private func fileURL(for presetID: UUID) -> URL {
        presetsDirectory.appendingPathComponent("\(presetID.uuidString).json")
    }

    private static func defaultPresetsDirectory(fileManager: FileManager) -> URL {
        let applicationSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return applicationSupportDirectory
            .appendingPathComponent("Aura", isDirectory: true)
            .appendingPathComponent("Presets", isDirectory: true)
    }

    private static func resolveBuiltInPresetsDirectory() -> URL? {
        let bundleCandidates = [
            Bundle.main.resourceURL?.appendingPathComponent("BuiltInPresets", isDirectory: true),
            Bundle.main.resourceURL?.appendingPathComponent("Shared/BuiltInPresets", isDirectory: true)
        ].compactMap { $0 }

        for candidate in bundleCandidates where FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }

        let sourceFileURL = URL(fileURLWithPath: #filePath)
        let repositoryCandidate = sourceFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Shared/BuiltInPresets", isDirectory: true)

        if FileManager.default.fileExists(atPath: repositoryCandidate.path) {
            return repositoryCandidate
        }

        return nil
    }
}
