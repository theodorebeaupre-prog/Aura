import AppKit
import Foundation

struct OSXColorsStatus: Equatable {
    let isInstalled: Bool
    let executablePath: String?
}

enum OSXColorsError: LocalizedError {
    case executableNotFound
    case installFailed(String)
    case applyFailed(String)
    case invalidOutput

    var errorDescription: String? {
        switch self {
        case .executableNotFound:
            return "`osx-colors` is not installed."
        case .installFailed(let message):
            return message.isEmpty ? "Unable to install `osx-colors`." : message
        case .applyFailed(let message):
            return message.isEmpty ? "Unable to apply the macOS accent color." : message
        case .invalidOutput:
            return "Received an invalid response from `osx-colors`."
        }
    }
}

struct OSXColorsService: Sendable {
    let envExecutableURL = URL(fileURLWithPath: "/usr/bin/env")
    let pythonExecutableURL = URL(fileURLWithPath: "/usr/bin/python3")
    let installURL = URL(string: "https://pypi.org/project/osx-colors/")!
    let installCommand = "python3 -m pip install --user osx-colors"

    func status() async -> OSXColorsStatus {
        do {
            let output = try await run(arguments: ["which", "osx-colors"])
            let path = output.trimmingCharacters(in: .whitespacesAndNewlines)
            return OSXColorsStatus(isInstalled: !path.isEmpty, executablePath: path.isEmpty ? nil : path)
        } catch {
            return OSXColorsStatus(isInstalled: false, executablePath: nil)
        }
    }

    func install() async throws {
        do {
            _ = try await runProcess(
                executableURL: pythonExecutableURL,
                arguments: ["-m", "pip", "install", "--user", "osx-colors"]
            )
        } catch let error as OSXColorsError {
            switch error {
            case .applyFailed(let message):
                throw OSXColorsError.installFailed(message)
            default:
                throw error
            }
        } catch {
            throw OSXColorsError.installFailed(error.localizedDescription)
        }
    }

    func apply(colorInput: String) async throws {
        let currentStatus = await status()
        guard currentStatus.isInstalled else {
            throw OSXColorsError.executableNotFound
        }

        do {
            _ = try await run(arguments: ["osx-colors", "set", colorInput])
        } catch let error as OSXColorsError {
            switch error {
            case .applyFailed:
                throw error
            default:
                throw OSXColorsError.applyFailed(error.localizedDescription)
            }
        } catch {
            throw OSXColorsError.applyFailed(error.localizedDescription)
        }
    }

    @MainActor
    func openInstallPage() {
        NSWorkspace.shared.open(installURL)
    }

    private func run(arguments: [String]) async throws -> String {
        try await Task.detached(priority: .userInitiated) {
            try runProcess(executableURL: envExecutableURL, arguments: arguments)
        }.value
    }

    private func runProcess(executableURL: URL, arguments: [String]) throws -> String {
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
            throw OSXColorsError.applyFailed(error.localizedDescription)
        }

        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw OSXColorsError.applyFailed(stderr.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return stdout
    }
}
