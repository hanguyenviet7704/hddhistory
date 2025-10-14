# Cursor Commands for Meup Flutter Project

## Overview
This directory contains Cursor AI commands specifically designed for the Meup Flutter project. These commands provide step-by-step guidance for common development tasks, following the project's Clean Architecture patterns and conventions.

## Available Commands

### 🚀 Getting Started
- **[onboard-new-developer.md](./onboard-new-developer.md)** - Complete onboarding guide for new team members
  - Project setup and dependencies
  - Architecture overview
  - Development workflow
  - Verification checklist

### 🏗️ Development
- **[setup-new-feature.md](./setup-new-feature.md)** - Create new features following Clean Architecture
  - Feature planning and structure
  - Domain, Data, and Presentation layer setup
  - Code templates and patterns
  - Testing setup

- **[generate-code.md](./generate-code.md)** - Code generation for models, DI, routes, and localization
  - Build runner commands
  - Localization from Google Sheets
  - Firebase configuration
  - Troubleshooting generation issues

### 🧪 Testing
- **[run-tests.md](./run-tests.md)** - Comprehensive testing guide
  - Unit tests, widget tests, integration tests
  - Coverage reporting
  - Testing patterns and utilities
  - CI/CD integration

### 🔨 Building
- **[build-app.md](./build-app.md)** - Build apps for different platforms and flavors
  - Android APK and App Bundle builds
  - iOS and IPA builds  
  - Code obfuscation and optimization
  - Build troubleshooting

### 🚀 Deployment
- **[deploy-app.md](./deploy-app.md)** - Deploy to various distribution channels
  - Firebase App Distribution
  - Google Play Store
  - Apple App Store
  - CI/CD automation

### 🐛 Debugging
- **[debug-issues.md](./debug-issues.md)** - Troubleshoot common development issues
  - Build failures
  - Dependency injection problems
  - Flutter/Dart issues
  - Performance debugging

## Quick Reference Commands

### Project Setup
```bash
# Initial setup
flutter pub get
dart run build_runner build --delete-conflicting-outputs
./tools/macos/localization/generate_localization.sh
```

### Development Workflow
```bash
# Code generation
dart run build_runner watch --delete-conflicting-outputs

# Run tests
flutter test --coverage

# Build for testing
./tools/macos/build/build_apk.sh dev
```

### Clean Project
```bash
# Full clean and setup
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
./tools/macos/localization/generate_localization.sh
```

## Project Architecture Quick Reference

### Dependency Injection
```dart
// Use AppDI.injector pattern
final useCase = AppDI.injector.get<GetUserUseCase>();

// Register with @lazySingleton (default pattern)
@lazySingleton
class UserRepository { }
```

### State Management
```dart
// BLoC pattern with HydratedCubit
@injectable
class UserCubit extends HydratedCubit<UserState> {
  UserCubit(this.useCase) : super(const UserState.initial());
}
```

### Error Handling
```dart
// Use Either pattern with AppException
TaskEither<AppException, User> getUser(String id) async {
  try {
    final user = await apiClient.getUser(id);
    return Right(user.toEntity());
  } catch (e) {
    return Left(AppException.fromException(e as Exception));
  }
}
```

### Localization
```dart
// Use context.text extension
Text(context.text.welcomeMessage)

// Generate from Google Sheets
./tools/macos/localization/generate_localization.sh
```

## Flavor Management

### Available Flavors
- **dev**: Development environment
- **stg**: Staging environment  
- **prod**: Production environment

### Usage
```dart
// Access current flavor
String flavorName = F.name;
Flavor? currentFlavor = F.appFlavor;

// Environment-specific logic
String apiUrl = switch (F.appFlavor) {
  Flavor.dev => 'https://dev.venusshop.top/api/v1',
  Flavor.prod => 'https://venusshop.top/api/v1',
  _ => 'https://venusshop.top/api/v1',
};
```

## File Structure
```
lib/
├── config/              # App configuration
│   ├── di/             # Dependency injection
│   ├── l10n/           # Localization
│   ├── routes/         # Navigation
│   ├── services/       # External services
│   ├── share/          # Shared utilities
│   └── themes/         # UI themes
├── core/               # Core utilities
│   ├── constants/      # App constants
│   └── utils/          # Utility functions
└── src/                # Main application code
    ├── data/           # Data layer (repos, models, APIs)
    ├── domain/         # Domain layer (entities, use cases)
    └── presentation/   # UI layer (pages, widgets, BLoCs)
```

## Development Guidelines

### Code Style
- Follow Clean Architecture principles
- Use `@lazySingleton` for dependency injection
- Implement proper error handling with `AppException`
- Write comprehensive tests
- Use localization for all user-facing text

### Git Workflow  
- Feature branches: `feature/TICKET-ID/description`
- Commit format: `type-TICKET-ID: description`
- Follow GitFlow workflow

### Testing Strategy
- **Domain Layer**: 100% coverage (business logic)
- **Data Layer**: 90%+ coverage (repositories)
- **Presentation Layer**: 80%+ coverage (BLoCs, UI)

## Getting Help

### Documentation
- **Project Docs**: `docs/projects/` directory
- **Cursor Rules**: `.cursor/rules/` directory
- **Quick Reference**: `CLAUDE.md` file

### Resources
- Team documentation and guidelines
- Architecture decision records
- API documentation
- Design system guidelines

## Contributing to Commands

When adding new commands:
1. Follow the existing markdown structure
2. Include clear overview and steps
3. Provide code examples
4. Add troubleshooting section
5. Update this README with new command

## Command Template

```markdown
# Command Title

## Overview
Brief description of what this command helps with.

## Steps
1. **Step One**
   - Detailed instructions
   - Code examples
   - Expected outcomes

2. **Step Two**
   - More instructions
   - Commands to run
   - Verification steps

## Checklist
- [ ] Requirement 1
- [ ] Requirement 2
- [ ] Verification step

## Troubleshooting
Common issues and solutions.
```