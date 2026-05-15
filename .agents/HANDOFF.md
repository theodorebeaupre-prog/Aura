# Aura — Agent Handoff Log

## Project Context
Aura is an open-source macOS 26 Tahoe customization utility.
Two agents work in parallel:
- CODEX = backend/system (Aura/Core/ folder)
- CLAUDE_CODE = UI/UX SwiftUI (Aura/UI/ folder)

## Shared Contracts (DO NOT MODIFY WITHOUT WRITTEN AGREEMENT IN MESSAGES BELOW)

### Preset struct
```swift
struct Preset: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var settings: [SystemSetting]
    var createdAt: Date
}
```

### SystemSetting struct
```swift
struct SystemSetting: Codable, Identifiable {
    let id: UUID
    let key: String          // ex: "NSAutomaticWindowAnimationsEnabled"
    let domain: String       // ex: "NSGlobalDomain" or "com.apple.dock"
    let value: SettingValue  // enum: .bool, .int, .double, .string
    let category: Category   // enum: .animations, .dock, .menuBar, .transparency, .accessibility
}
```

### SettingValue enum (Codable)
```swift
enum SettingValue: Codable, Equatable {
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
}
```

### Category enum
```swift
enum Category: String, Codable, CaseIterable {
    case animations
    case dock
    case menuBar
    case transparency
    case accessibility
    case finder
    case other
}
```

### DefaultsManaging protocol
```swift
protocol DefaultsManaging {
    func read(key: String, domain: String) async throws -> SettingValue?
    func write(setting: SystemSetting) async throws
    func applyPreset(_ preset: Preset) async throws -> ApplyResult
    func preview(_ preset: Preset) -> [SettingDiff]
    func reset(setting: SystemSetting) async throws
    func resetAll() async throws
}
```

### ApplyResult struct
```swift
struct ApplyResult: Codable {
    let success: Bool
    let appliedCount: Int
    let errors: [String]
    let backupID: UUID?
}
```

### SettingDiff struct
```swift
struct SettingDiff: Identifiable {
    let id: UUID
    let key: String
    let domain: String
    let oldValue: SettingValue?
    let newValue: SettingValue
}
```

## Folder Ownership
- Aura/Core/         → CODEX only
- Aura/UI/           → CLAUDE_CODE only
- Aura/Shared/       → Either may read; CODEX writes Models/, both read BuiltInPresets/
- AuraTests/CoreTests/ → CODEX
- AuraTests/UITests/   → CLAUDE_CODE

## Messages
(Format: ### [ISO timestamp] FROM_AGENT → TO_AGENT)

