# Aura — Claude Code Guide

## Project overview
Aura is an open-source macOS 26 Tahoe customization utility written in Swift/SwiftUI.
It lets users browse, tweak, preview, and apply macOS `defaults` settings through a native GUI.

## Repository layout
```
Aura/
  AuraApp.swift            ← @main entry point
  Core/                    ← Backend: DefaultsManager, BackupManager, PresetEngine (Codex agent)
  Shared/
    Models/                ← Codable contracts: Preset, SystemSetting, SettingValue, Category…
    BuiltInPresets/        ← JSON preset files
  UI/
    Theme/                 ← AuraTheme struct, ThemeManager, OSXColorsService
    Mocks/                 ← MockDefaultsManager (development/preview)
    Extensions/            ← Category+UI, SettingValue+UI, Color+AuraTheme, View+AuraTheme
    Views/                 ← All SwiftUI views
AuraTests/
  CoreTests/               ← Unit tests for Core/ (XCTest)
  UITests/                 ← UI tests
.agents/
  HANDOFF.md               ← Inter-agent contracts and messages
  PROGRESS.md              ← Timestamped completion log
  BLOCKERS.md              ← Outstanding blockers
```

## Shared contracts (DO NOT CHANGE without updating .agents/HANDOFF.md)
The following types are contracts between the UI agent and Core agent — treat them as frozen:
`Preset`, `SystemSetting`, `SettingValue`, `Category`, `DefaultsManaging`,
`ApplyResult`, `SettingDiff`.

## Coding conventions
- **Language**: Swift 6 / SwiftUI, targeting macOS 26 Tahoe
- **Architecture**: Protocol-oriented. `DefaultsManaging` is the seam between UI and Core.
- **UI only uses**: `Color.accentColor`, `Color(NSColor.*)`, `.primary`, `.secondary`, theme tokens from `AuraTheme`. No hardcoded hex colors outside `AuraTheme.swift`.
- **No comments** unless the WHY is non-obvious (hidden constraint, workaround, invariant).
- **No invented SwiftUI modifiers** — if unsure whether an API exists on macOS 26, use `.background(.ultraThinMaterial)` and add `// TODO: VERIFY macOS 26 Liquid Glass API`.
- **No mutations to disk or system** from `Aura/UI/` — all side effects go through `DefaultsManaging`.
- SF Symbols via `Image(systemName:)`. System fonts only.

## Branch strategy
| Branch | Owner | Purpose |
|--------|-------|---------|
| `main` | shared | integration / releases |
| `claude-ui` | Claude Code | all UI work |
| `codex-core` | Codex | all backend work |

PRs merge into `main`. Do not push directly to `main`.

## Running the project
```bash
# Open in Xcode
open Aura.xcodeproj

# Build from CLI (requires macOS 26 SDK / Xcode 26+)
xcodebuild build -scheme Aura -destination 'platform=macOS'
```

## Known build issues (as of 2026-05-15)
- Duplicate resource outputs from `.gitkeep` and `README.md` files in filesystem-synced groups. See `.agents/BLOCKERS.md`.
- Test scheme not yet configured for `xcodebuild test`. See `.agents/BLOCKERS.md`.

## How to summon Claude
- **On an issue**: comment `@claude <instruction>` — Claude will open a PR with the fix.
- **On a PR**: comment `@claude review` — Claude will leave a detailed code review.
- **In CI**: the `claude.yml` workflow fires automatically on `@claude` mentions.

## Project contacts
- GitHub: [@theodorebeaupre-prog](https://github.com/theodorebeaupre-prog)
