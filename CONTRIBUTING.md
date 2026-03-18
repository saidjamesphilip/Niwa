# Contributing to Niwa

Thanks for your interest in contributing! Here's how to get started.

## Requirements

- **macOS 15.0+** (Sequoia or later)
- **Xcode 16+**
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Development Setup

```bash
git clone https://github.com/saidjamesphilip/Niwa.git
cd Niwa

# Generate Xcode project from spec (re-run when adding/removing files)
xcodegen generate

# Build
xcodebuild -scheme NiwaApp -configuration Debug build

# Or open in Xcode
open Niwa.xcodeproj
```

## Project Structure

```
Niwa/
├── NiwaApp/          — Main app target (views, services, assets)
├── NiwaShared/       — Shared code (models, engines, constants)
├── NiwaWidget/       — WidgetKit extension
└── project.yml       — XcodeGen project definition
```

## Code Style

- **Zero external dependencies** — Apple frameworks only (SwiftUI, SwiftData, EventKit, WidgetKit)
- **SwiftUI** for all views, **SwiftData** for persistence, **EventKit** for calendar access
- **`@Observable`** for engines and managers (not `ObservableObject`)
- Views receive dependencies via init parameters (not `@EnvironmentObject`)
- One primary type per file, filename matches type name
- All colors use `DesignTokens.Colors` — never hardcode color values
- All spacing uses `DesignTokens.Spacing` constants
- 4-space indentation

## Design Tokens

All visual properties are centralized in `NiwaShared/Constants/DesignTokens.swift`. When adding or modifying UI:

1. Use `DesignTokens.Colors` for all colors (they adapt to light/dark automatically)
2. Use `DesignTokens.Spacing` for padding and margins
3. Use `DesignTokens.Typography` for fonts
4. Use `DesignTokens.CornerRadius` for rounded corners
5. Use `DesignTokens.Animation` for animation curves

## Development Workflow

### Branching

All work happens on feature branches — never commit directly to `main`.

```bash
git checkout -b feat/my-feature    # or fix/my-bug
# ... make changes ...
git add -A && git commit -m "Add my feature"
git push -u origin feat/my-feature
```

### Pull Requests

1. Create a feature branch (`feat/...`, `fix/...`, `docs/...`)
2. Make your changes
3. Verify the build succeeds: `xcodebuild -scheme NiwaApp build`
4. Test locally — run the app and verify your changes work
5. Run unit tests: `xcodebuild -scheme NiwaApp -destination 'platform=macOS' test`
6. Push and open a PR on GitHub — describe what changed and why
7. Once approved, merge to `main`

### Releasing

Releases are triggered by pushing a version tag. Only maintainers do this:

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

This triggers a GitHub Actions workflow that builds the app, creates a zip, and publishes a GitHub Release. After the release, the Homebrew Cask formula is updated with the new version and SHA.

## Reporting Issues

Open an [issue](https://github.com/saidjamesphilip/Niwa/issues) with:

- macOS version
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable

## Security

Found a vulnerability? Please report it privately — see [SECURITY.md](SECURITY.md).

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](LICENSE).
