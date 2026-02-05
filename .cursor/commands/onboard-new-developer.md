# Onboard New Developer

## Overview
This command guides you through setting up the Meup Flutter project for development, ensuring you have all the necessary tools, dependencies, and understanding of the project structure.

## Prerequisites
- [ ] Flutter SDK installed (latest stable version)
- [ ] Dart SDK (comes with Flutter)
- [ ] Android Studio or VS Code
- [ ] Xcode (for iOS development on macOS)
- [ ] Git configured with your credentials
- [ ] Python 3 installed (for localization scripts)

## Project Setup Steps

### 1. **Clone and Initial Setup**
```bash
# Clone the repository
git clone <repository-url>
cd meup-flutter

# Get Flutter dependencies
flutter pub get

# Generate code (models, DI, routes)
dart run build_runner build --delete-conflicting-outputs
```

### 2. **Environment Configuration**
- [ ] Copy environment template files from `.env/` directory
- [ ] Configure flavor-specific environment variables
- [ ] Set up Firebase configuration files for each flavor

### 3. **IDE Configuration**
- [ ] Install Flutter and Dart extensions
- [ ] Configure launch configurations for different flavors
- [ ] Set up code formatting (dart format)
- [ ] Enable Flutter Inspector

### 4. **Understanding Project Architecture**

#### Clean Architecture Structure:
- **Domain Layer** (`lib/src/domain/`): Business logic, entities, repository interfaces
- **Data Layer** (`lib/src/data/`): API clients, data sources, repository implementations  
- **Presentation Layer** (`lib/src/presentation/`): UI components, BLoC state management

#### Key Patterns:
- **Dependency Injection**: Uses `AppDI.injector.get<T>()` pattern with `@lazySingleton`
- **State Management**: BLoC pattern with `HydratedCubit` for persistence
- **Error Handling**: `AppException` with `Either<AppException, T>` return types
- **Navigation**: GoRouter with code generation
- **Localization**: ARB files with Google Sheets integration

### 5. **Flavors and Build Configuration**
The project supports three flavors:
- **dev**: Development environment
- **stg**: Staging environment
- **prod**: Production environment

#### Running Different Flavors:
```bash
# Development
flutter run --flavor dev -t lib/main_dev.dart

# Staging  
flutter run --flavor stg -t lib/main_stg.dart

# Production
flutter run --flavor prod -t lib/main_prod.dart
```

### 6. **Development Workflow**

#### Code Generation:
```bash
# After changes to models, APIs, or routes
dart run build_runner build --delete-conflicting-outputs

# Generate localization from Google Sheets
./tools/macos/localization/generate_localization.sh
```

#### Testing:
```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/domain/usecases/auth/login_usecase_test.dart
```

#### Building:
```bash
# Android APK
./tools/macos/build/build_apk.sh dev

# Android App Bundle
./tools/macos/build/build_appbundle.sh prod

# iOS
./tools/macos/build/build_ipa.sh prod
```

### 7. **Common Commands Quick Reference**
```bash
# Clean project
flutter clean && flutter pub get

# Format code
dart format lib/ test/

# Analyze code
flutter analyze

# Generate app icons
flutter pub run flutter_launcher_icons

# Configure Firebase
./tools/macos/config/flutterfire_config.sh
```

## Development Guidelines

### Code Style:
- Follow Clean Architecture principles
- Use `@lazySingleton` for dependency injection
- Implement proper error handling with `AppException`
- Write comprehensive tests for business logic
- Use localization for all user-facing text

### Git Workflow:
- Create feature branches: `feature/TICKET-ID/description`
- Commit message format: `type-TICKET-ID: description`
- Follow GitFlow workflow

### File Structure:
```
lib/
├── config/          # App configuration (DI, routes, themes)
├── core/            # Core utilities and constants
└── src/             # Main application code
    ├── data/        # Data layer (repositories, models, APIs)
    ├── domain/      # Domain layer (entities, use cases)
    └── presentation/ # UI layer (pages, widgets, BLoCs)
```

## Verification Checklist
- [ ] Project builds successfully for all flavors
- [ ] Tests pass (`flutter test`)
- [ ] Code analysis passes (`flutter analyze`)
- [ ] Can run localization generation script
- [ ] Understanding of Clean Architecture layers
- [ ] Familiar with BLoC state management pattern
- [ ] Know how to use dependency injection (`AppDI.injector`)
- [ ] Can create and run different build flavors

## Next Steps
1. Read the project documentation in `docs/projects/`
2. Review the Cursor rules in `.cursor/rules/`
3. Start with a small task to practice the development workflow
4. Ask questions in team channels for clarification

## Getting Help
- Check `CLAUDE.md` for quick command references
- Review `.cursor/rules/` for coding patterns
- Consult team documentation in `docs/` directory
- Use project-specific commands in `.cursor/commands/`