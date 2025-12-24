# Meup Flutter Application

Meup is a multi-platform Flutter product that delivers interactive language-learning experiences using Clean Architecture, TaskEither-based use cases, and parity tooling across macOS/Linux/Windows. This README stays concise—treat the `docs/` directory as the canonical source of truth.

## Quick Start
1. **Bootstrap tooling**
   ```bash
   tools/<os>/config/setup_project.sh        # add --non-interactive for CI
   tools/<os>/smoke.sh                       # sanity check (tools\windows\smoke.bat)
   ```
2. **Generate code + localization**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   tools/<os>/localization/localization.sh pull
   dart run slang && dart run slang_build_runner
   ```
3. **Run quality gates**
   ```bash
   flutter analyze
   flutter test
   ```
4. **Launch an environment**
   ```bash
   flutter run --flavor dev -t lib/main_dev.dart
   # or use IDE run configurations (VS Code/.vscode, Android Studio/.idea)
   ```

Additional flows (builds, distribution, Firebase config) are documented inside `docs/system-architecture.md` and `docs/code-standards.md`.

## Core Documentation
| Topic | Location |
| --- | --- |
| Product Development Requirements | `docs/project-overview-pdr.md` |
| Code Standards & Processes | `docs/code-standards.md` |
| System Architecture | `docs/system-architecture.md` |
| Codebase Snapshot | `docs/codebase-summary.md` |
| Tooling & Configuration Reference | `tools/README.md`, `.info/README.md` |

## Architecture Highlights
- Feature pods in `lib/src/<feature>/` split into presentation, domain (TaskEither use cases), and data (Retrofit/GraphQL repos).
- `lib/config/di` bootstraps `get_it` + `injectable`; `lib/config/routes` uses `go_router` for typed navigation.
- Localization assets live under `assets/i18n/` and regenerate via `slang`.
- Build scripts in `tools/<os>/build` honor `.env/.env.<flavor>` and `.info/app/*.json` for flavor-specific settings.

## Testing & Quality
- Workflow: build_runner → analyze → test → optional coverage.
- TaskEither adoption is complete—repositories, use cases, and cubits must maintain the pattern to ensure consistent error semantics.

## Support
If an answer is not in this README, check `docs/`. Update those docs before sharing process changes with other developers.

## License
See `LICENSE.md`.
