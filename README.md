# Aura

**An open-source customization utility for macOS 26 Tahoe — currently in early development.**

![Status](https://img.shields.io/badge/status-early_development-yellow)
![macOS 26](https://img.shields.io/badge/macOS-26_Tahoe-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-SwiftUI-orange?logo=swift)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

macOS 26 Tahoe introduced Liquid Glass and a wave of new visual behavior — and no single place to tune it. Aura aims to be that place: a safe, reversible control panel for the system's look and feel.

> ⚠️ **Aura is a work in progress.** The features below are the project's roadmap, not a finished product. Star/watch the repo to follow along, or jump in — early contributors get to shape the architecture.

## Roadmap

- [ ] Toggle system animations on/off
- [ ] Liquid Glass tinting presets (Cinéma, Focus Mode, Performance)
- [ ] Dock behavior customization
- [ ] Automatic backup before every change — nothing is irreversible
- [ ] Export/import presets as JSON
- [ ] One-click reset to macOS defaults

## Design principles

1. **Reversible by default** — every change is backed up before it's applied, and a single click restores macOS defaults.
2. **Strict separation** — `Core/` holds all logic and system interaction; `UI/` holds SwiftUI views. The UI never touches the system directly.
3. **Presets over knobs** — curated, named configurations first; granular controls second.

## Requirements

- macOS 26 Tahoe or later
- Xcode 16+ (to build from source)

## Building

```bash
git clone https://github.com/theodorebeaupre-prog/Aura
cd Aura
open Aura.xcodeproj   # then ⌘R
```

## Contributing

The project is young enough that architectural input matters as much as code. See [CONTRIBUTING.md](CONTRIBUTING.md), or open an issue with the system tweak you'd want Aura to manage first.

## License

MIT — built by [Théo Beaupré](https://github.com/theodorebeaupre-prog) (Théo Picture)
