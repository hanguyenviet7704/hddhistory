# Meup Flutter Application

**Meup** is a comprehensive Flutter application built with Clean Architecture, multi-environment support, and robust development tooling. This project demonstrates modern Flutter development practices with advanced build processes, localization, and state management.

## Quick Start

For new developers joining the project, follow these essential setup steps:

1. **Generate Project Resources**
   ```bash
   sh tools/macos/resource/generate_file.sh
   ```

2. **Reset and Clean Project**
   ```bash
   sh tools/macos/build/reset_app.sh
   ```

3. **Generate Localization Files**
   ```bash
   sh tools/macos/localization/generate_localization.sh
   ```

4. **Run the Application**
   Use your IDE's pre-configured run configurations (see IDE Configuration section below)

## Project Overview

### Architecture
- **Clean Architecture** with Domain, Data, and Presentation layers
- **BLoC Pattern** for state management with `flutter_bloc` and `hydrated_bloc`
- **Dependency Injection** using `get_it` and `injectable`
- **Repository Pattern** with interfaces and implementations

### Multi-Environment Support
- **dev**: Development environment
- **stg**: Staging environment  
- **prod**: Production environment

Each environment has its own configuration files, build scripts, and Firebase setup.

### Key Features
- Advanced build system with obfuscation and Firebase Crashlytics integration
- Comprehensive localization system with Google Sheets integration
- Custom development tools for macOS (Windows/Linux tools are placeholders)
- Code generation for models, APIs, routing, and dependency injection
- Multi-flavor support with environment-specific configurations

## Documentation Structure

This project uses a structured documentation approach:

### 📁 [docs/common/](docs/common/)
Reusable documentation applicable across projects:
- [Git workflow and branching strategy](docs/common/01-01-git-workflow.md)
- [Coding standards and best practices](docs/common/01-02-coding-standards.md)
- [Commit message conventions](docs/common/01-03-commit-conventions.md)
- [Flutter development guidelines](docs/common/01-04-flutter-best-practices.md)

### 📁 [docs/projects/](docs/projects/)
Project-specific documentation for Meup:

#### Getting Started
- [Prerequisites and Requirements](docs/projects/02-01-getting-started/02-01-01-prerequisites.md)
- [Project Setup Guide](docs/projects/02-01-getting-started/02-01-02-project-setup.md)
- [First-Time Developer Setup](docs/projects/02-01-getting-started/02-01-03-first-time-setup.md)

#### Architecture & Design
- [Clean Architecture Implementation](docs/projects/02-02-project-architecture/02-02-01-clean-architecture.md)
- [State Management with BLoC](docs/projects/02-02-project-architecture/02-02-02-state-management.md)
- [Dependency Injection](docs/projects/02-02-project-architecture/02-02-03-dependency-injection.md)
- [Project Folder Structure](docs/projects/02-02-project-architecture/02-02-04-folder-structure.md)

#### Build Process
- [Build Process Overview](docs/projects/02-03-build-process/02-03-01-build-overview.md)
- [Building for Android](docs/projects/02-03-build-process/02-03-02-building-for-android.md)
- [Building for iOS](docs/projects/02-03-build-process/02-03-03-building-for-ios.md)
- [App Bundle Generation](docs/projects/02-03-build-process/02-03-04-building-app-bundles.md)
- [Code Obfuscation](docs/projects/02-03-build-process/02-03-05-code-obfuscation.md)

#### Environment Configuration
- [Environment Files (.env)](docs/projects/02-04-environment-configuration/02-04-01-environment-files.md)
- [Using --dart-define-from-file](docs/projects/02-04-environment-configuration/02-04-02-dart-define-usage.md)
- [Flavor Configuration](docs/projects/02-04-environment-configuration/02-04-03-flavor-configuration.md)

#### Development Tools
- [Custom Scripts Overview](docs/projects/02-05-development-tools/02-05-01-custom-scripts-overview.md)
- [macOS Development Tools](docs/projects/02-05-development-tools/02-05-02-macos-tools.md)
- [Code Generation](docs/projects/02-05-development-tools/02-05-03-code-generation.md)
- [Localization Tools](docs/projects/02-05-development-tools/02-05-04-localization-tools.md)

#### IDE Configuration
- [VS Code Setup](docs/projects/02-06-ide-configuration/02-06-01-vscode-setup.md)
- [IntelliJ/Android Studio Setup](docs/projects/02-06-ide-configuration/02-06-02-intellij-setup.md)

#### Project Metadata
- [Project Information Folder](docs/projects/02-07-project-metadata/02-07-01-project-info-folder.md)

#### Testing & Deployment
- [Testing Strategy](docs/projects/02-08-testing-deployment/02-08-01-testing-strategy.md)
- [Firebase Integration](docs/projects/02-08-testing-deployment/02-08-02-firebase-integration.md)
- [App Distribution](docs/projects/02-08-testing-deployment/02-08-03-app-distribution.md)

## IDE Configuration

### VS Code / VSCodium
Pre-configured launch configurations are available in `.vscode/launch.json` for:
- Development, Staging, and Production environments
- Debug, Profile, and Release modes

### IntelliJ IDEA / Android Studio
Run configurations are available in `.idea/runConfigurations/` for all environment and mode combinations.

## Important Notes

### Platform Support for Custom Tools
- ✅ **macOS**: Fully functional and up-to-date tools
- ⚠️ **Windows/Linux**: Placeholder scripts for future development

The project's custom tooling in `tools/` is currently optimized for macOS development. Windows and Linux directories contain placeholder scripts that will be implemented in future versions.

### Build Process
This project uses `--dart-define-from-file` (NOT `--dart-define`) for environment configuration. All build scripts are configured to load environment variables from files in the `.env/` directory.

## Support

For questions about the project structure or development setup, refer to the detailed documentation in the `docs/` directory. Each section provides comprehensive information about specific aspects of the project.

## License

See [LICENSE.md](LICENSE.md) for license information.