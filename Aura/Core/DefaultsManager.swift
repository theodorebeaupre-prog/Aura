import Foundation

enum DefaultsError: Error, Equatable {
    case notFound
    case invalidValue
    case processFailure(exitCode: Int32, stderr: String)
}

final class DefaultsManager: DefaultsManaging {
    private let executableURL: URL
    private let managedSettingsProvider: @Sendable () -> [SystemSetting]

    init(
        executableURL: URL = URL(fileURLWithPath: "/usr/bin/defaults"),
        managedSettingsProvider: @escaping @Sendable () -> [SystemSetting] = { [] }
    ) {
        self.executableURL = executableURL
        self.managedSettingsProvider = managedSettingsProvider
    }

    func read(key: String, domain: String) async throws -> SettingValue? {
        do {
            let typeOutput = try await runDefaults(arguments: ["read-type", domain, key])
            let valueOutput = try await runDefaults(arguments: ["read", domain, key])
            return try parseValue(
                stdout: valueOutput.stdout,
                typeDescription: typeOutput.stdout
            )
        } catch let error as DefaultsError {
            if case .processFailure(_, let stderr) = error, isNotFound(stderr: stderr) {
                return nil
            }

            throw error
        }
    }

    func write(setting: SystemSetting) async throws {
        let arguments = ["write", setting.domain, setting.key] + commandArguments(for: setting.value)
        _ = try await runDefaults(arguments: arguments)
    }

    func applyPreset(_ preset: Preset) async throws -> ApplyResult {
        var appliedCount = 0
        var errors: [String] = []

        for setting in preset.settings {
            do {
                try await write(setting: setting)
                appliedCount += 1
            } catch {
                errors.append("\(setting.domain)/\(setting.key): \(error)")
            }
        }

        return ApplyResult(
            success: errors.isEmpty,
            appliedCount: appliedCount,
            errors: errors,
            backupID: nil
        )
    }

    func preview(_ preset: Preset) -> [SettingDiff] {
        preset.settings.map { setting in
            let oldValue: SettingValue?

            do {
                oldValue = try readSynchronously(key: setting.key, domain: setting.domain)
            } catch {
                oldValue = nil
            }

            return SettingDiff(
                id: UUID(),
                key: setting.key,
                domain: setting.domain,
                oldValue: oldValue,
                newValue: setting.value
            )
        }
    }

    func reset(setting: SystemSetting) async throws {
        do {
            _ = try await runDefaults(arguments: ["delete", setting.domain, setting.key])
        } catch let error as DefaultsError {
            if case .processFailure(_, let stderr) = error, isNotFound(stderr: stderr) {
                throw DefaultsError.notFound
            }

            throw error
        }
    }

    func resetAll() async throws {
        for setting in uniqueManagedSettings() {
            do {
                try await reset(setting: setting)
            } catch DefaultsError.notFound {
                continue
            }
        }
    }

    private func uniqueManagedSettings() -> [SystemSetting] {
        var seen: Set<String> = []

        return managedSettingsProvider().filter { setting in
            let identifier = "\(setting.domain)::\(setting.key)"
            return seen.insert(identifier).inserted
        }
    }

    private func readSynchronously(key: String, domain: String) throws -> SettingValue? {
        do {
            let typeOutput = try runDefaultsSynchronously(arguments: ["read-type", domain, key])
            let valueOutput = try runDefaultsSynchronously(arguments: ["read", domain, key])
            return try parseValue(
                stdout: valueOutput.stdout,
                typeDescription: typeOutput.stdout
            )
        } catch let error as DefaultsError {
            if case .processFailure(_, let stderr) = error, isNotFound(stderr: stderr) {
                return nil
            }

            throw error
        }
    }

    private func runDefaults(arguments: [String]) async throws -> CommandOutput {
        try await Task.detached(priority: .userInitiated) { [executableURL] in
            try Self.runDefaultsProcess(executableURL: executableURL, arguments: arguments)
        }.value
    }

    private func runDefaultsSynchronously(arguments: [String]) throws -> CommandOutput {
        try Self.runDefaultsProcess(executableURL: executableURL, arguments: arguments)
    }

    private static func runDefaultsProcess(executableURL: URL, arguments: [String]) throws -> CommandOutput {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = executableURL
        process.arguments = arguments
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        do {
            try process.run()
        } catch {
            throw DefaultsError.processFailure(exitCode: -1, stderr: error.localizedDescription)
        }

        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw DefaultsError.processFailure(
                exitCode: process.terminationStatus,
                stderr: stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            )
        }

        return CommandOutput(stdout: stdout.trimmingCharacters(in: .whitespacesAndNewlines), stderr: stderr)
    }

    private func parseValue(stdout: String, typeDescription: String) throws -> SettingValue {
        let normalizedType = typeDescription.lowercased()

        if normalizedType.contains("boolean") {
            return try parseBoolean(stdout)
        }

        if normalizedType.contains("integer") {
            guard let value = Int(stdout) else {
                throw DefaultsError.invalidValue
            }

            return .int(value)
        }

        if normalizedType.contains("float") || normalizedType.contains("double") || normalizedType.contains("real") {
            guard let value = Double(stdout) else {
                throw DefaultsError.invalidValue
            }

            return .double(value)
        }

        if normalizedType.contains("string") {
            return .string(stdout)
        }

        // TODO: VERIFY whether additional plist-backed scalar types should be supported in Aura.
        throw DefaultsError.invalidValue
    }

    private func parseBoolean(_ stdout: String) throws -> SettingValue {
        switch stdout.lowercased() {
        case "1", "true", "yes":
            return .bool(true)
        case "0", "false", "no":
            return .bool(false)
        default:
            throw DefaultsError.invalidValue
        }
    }

    private func commandArguments(for value: SettingValue) -> [String] {
        switch value {
        case .bool(let boolValue):
            return ["-bool", boolValue ? "TRUE" : "FALSE"]
        case .int(let intValue):
            return ["-int", String(intValue)]
        case .double(let doubleValue):
            return ["-float", String(doubleValue)]
        case .string(let stringValue):
            return ["-string", stringValue]
        }
    }

    private func isNotFound(stderr: String) -> Bool {
        let normalized = stderr.lowercased()
        return normalized.contains("does not exist") || normalized.contains("could not find")
    }
}

private struct CommandOutput {
    let stdout: String
    let stderr: String
}
