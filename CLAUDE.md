# Meup Flutter Project

## Project Overview

**Meup** is a Flutter application built following Clean Architecture principles. It's an art education platform with features for picture studies, quizzes, roadmaps, and user authentication. The project uses modern Flutter development practices with code generation, dependency injection, and multi-flavor support.

## Quick Start Commands

### Development Setup
```bash
# Get dependencies
flutter pub get

# Generate code (models, routes, DI, etc.)
flutter pub run build_runner build --delete-conflicting-outputs
# or
dart run build_runner build --delete-conflicting-outputs

# Clean and regenerate
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Building

#### Android APK
```bash
# Build APK for specific flavor
./tools/macos/build/build_apk.sh dev    # Development
./tools/macos/build/build_apk.sh stg    # Staging
./tools/macos/build/build_apk.sh prod   # Production

# Build with tree shaking disabled (if needed for icons)
./tools/macos/build/build_apk.sh dev --no-tree-shake-icons
```

#### Android App Bundle
```bash
./tools/macos/build/build_appbundle.sh dev    # Development
./tools/macos/build/build_appbundle.sh stg    # Staging
./tools/macos/build/build_appbundle.sh prod   # Production
```

#### iOS
```bash
./tools/macos/build/build_ios.sh dev     # Development
./tools/macos/build/build_ios.sh stg     # Staging
./tools/macos/build/build_ios.sh prod    # Production

# Build IPA
./tools/macos/build/build_ipa.sh dev
./tools/macos/build/build_ipa.sh stg
./tools/macos/build/build_ipa.sh prod
```

### Testing
```bash
# Run all tests
flutter test

# Run unit tests only
flutter test test/unit/

# Run with coverage
flutter test --coverage

# Run specific test file
flutter test test/unit/domain/usecases/auth/login_usecase_test.dart
```

### Linting
```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/
```

### Code Generation
```bash
# Generate app icons
flutter pub run flutter_launcher_icons

# Generate localization
flutter gen-l10n

# Generate flavors (after modifying flavorizr.yaml)
dart run flutter_flavorizr

# Generate Firebase configuration
./tools/macos/config/flutterfire_config.sh
```

## Architecture

### Clean Architecture Structure

The project follows Clean Architecture with clear separation of concerns:

```
lib/
├── config/                 # Application configuration
│   ├── di/                # Dependency injection setup
│   ├── l10n/              # Localization
│   ├── routes/            # Navigation and routing
│   ├── services/          # External services configuration
│   ├── share/             # Shared utilities
│   └── themes/            # UI theming
├── core/                  # Core utilities and constants
│   ├── constants/         # App constants and generated files
│   └── utils/             # Utility functions and widgets
└── src/                   # Main application code
    ├── data/              # Data layer
    │   ├── datasources/   # API and data sources
    │   ├── models/        # Data models
    │   └── repositories/  # Repository implementations
    ├── domain/            # Business logic layer
    │   ├── entities/      # Domain entities
    │   ├── repositories/  # Repository interfaces
    │   └── usecases/      # Use cases
    └── presentation/      # UI layer
        ├── blocs/         # State management (BLoC)
        ├── pages/         # Screen widgets
        └── widgets/       # Reusable UI components
```

### Key Architectural Patterns

#### 1. Clean Architecture
- **Domain Layer**: Contains business logic, entities, and repository interfaces
- **Data Layer**: Implements repositories, handles API calls and data persistence
- **Presentation Layer**: UI components and state management

#### 2. State Management - BLoC Pattern
- Uses `flutter_bloc` for state management
- Each feature has its own Cubit/Bloc for state handling
- Hydrated BLoC for state persistence

#### 3. Dependency Injection
- Uses `get_it` and `injectable` for dependency injection
- Auto-generated dependency configuration
- Service locator pattern implementation

#### 4. Repository Pattern
- Abstracts data sources behind repository interfaces
- Separate repositories for different domains (auth, profile, roadmap, etc.)

#### 5. Use Case Pattern
- Business logic encapsulated in use cases
- Uses `UseCaseWithParams` and `UseCaseWithoutParams` base classes
- Clean separation between business logic and UI

## Key Libraries and Tools

### State Management
- **flutter_bloc**: State management with BLoC pattern
- **hydrated_bloc**: Persistent state management

### Networking
- **dio**: HTTP client with interceptors
- **retrofit**: Type-safe REST client generation
- **graphql_flutter**: GraphQL client

### Navigation
- **go_router**: Declarative routing with code generation

### Code Generation
- **build_runner**: Build system for code generation
- **freezed**: Immutable classes and unions
- **json_serializable**: JSON serialization
- **injectable**: Dependency injection code generation
- **retrofit_generator**: REST API client generation

### UI/UX
- **flutter_screenutil**: Screen adaptation
- **flutter_svg**: SVG support
- **cached_network_image**: Image caching
- **flutter_animate**: Animations
- **lottie**: Lottie animations

### Storage & Services
- **flutter_secure_storage**: Secure local storage
- **path_provider**: File system paths
- **supabase_flutter**: Backend as a Service

### Firebase Services
- **firebase_core**: Firebase initialization
- **firebase_auth**: Authentication
- **firebase_messaging**: Push notifications
- **firebase_crashlytics**: Crash reporting
- **firebase_analytics**: Analytics

## Environment Configuration

### Flavors
The project supports three flavors:
- **dev**: Development environment
- **stg**: Staging environment  
- **prod**: Production environment

### Environment Files
- `.env/.env.dev` - Development configuration
- `.env/.env.stg` - Staging configuration  
- `.env/.env.prod` - Production configuration

### Flavor-specific Entry Points
- `lib/main_dev.dart` - Development entry point
- `lib/main_stg.dart` - Staging entry point
- `lib/main_prod.dart` - Production entry point

### Flavor Configuration
- `flavorizr.yaml` - Flavor definitions and settings
- `android/app/flavorizr.gradle.kts` - Generated Android flavor configuration (Kotlin DSL)
- `lib/flavors.dart` - Flutter flavor management with Firebase integration

## Development Workflow

### 1. Feature Development
1. Create feature branch following GitFlow: `feature/TICKET-ID/description`
2. Implement following Clean Architecture layers:
   - Domain: entities, repository interfaces, use cases
   - Data: models, repository implementations, data sources
   - Presentation: BLoC/Cubit, pages, widgets
3. Run code generation: `dart run build_runner build`
4. Write tests following the patterns in `test/unit/README.md`
5. Test across flavors

### 2. Code Generation
Required after changes to:
- Data models (JSON serialization)
- API clients (Retrofit)
- Routes (GoRouter)
- Dependency injection (Injectable)
- Flavor configuration (flutter_flavorizr)

### 3. Testing Strategy
- **Unit Tests**: Business logic and use cases
- **Widget Tests**: UI components
- **Integration Tests**: End-to-end scenarios
- Follow test patterns in `test/unit/README.md`

### 4. Git Workflow
- Uses GitFlow workflow
- Commit message format: `type-TICKET-ID: description`
- See `.cursorrules` for detailed commit conventions

## Build Configuration

### Code Obfuscation
All release builds use:
- `--obfuscate` flag for code obfuscation
- `--split-debug-info` for crash reporting
- Debug symbols automatically uploaded to Firebase Crashlytics

### Build Outputs
- **Android APK**: `build/app/outputs/flutter-apk/`
- **Android Bundle**: `build/app/outputs/bundle/`
- **iOS IPA**: `build/ios/ipa/`
- **Debug Info**: `.obfuscation/`

## Localization

### Configuration
- Uses `flutter_localizations`
- Configuration in `l10n.yaml`
- ARB files in `lib/config/l10n/arb/`

### Generate Localization
```bash
flutter gen-l10n
```

## CI/CD and Distribution

### Automated Distribution
The project includes comprehensive CI/CD workflows for automated building and distribution:

- **GitHub Actions**: Complete workflow for multi-environment builds
- **Environment-specific builds**: Automatic builds for dev, staging, and production
- **Play Store Integration**: Automated uploads to Google Play Console
- **TestFlight Integration**: iOS distribution through TestFlight
- **Quality Gates**: Code analysis, testing, and coverage reporting

### Manual Distribution Commands
```bash
# Build development APK for testing
./tools/macos/build/build_apk.sh dev

# Build production app bundle for Play Store
./tools/macos/build/build_appbundle.sh prod

# Build iOS for TestFlight
./tools/macos/build/build_ipa.sh prod
```

## Troubleshooting

### Common Issues

1. **Build Runner Issues**
   ```bash
   flutter packages pub run build_runner clean
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

2. **Pod Install Issues (iOS)**
   ```bash
   cd ios && pod install --repo-update
   ```

3. **Gradle Issues (Android)**
   ```bash
   cd android && ./gradlew clean
   flutter clean && flutter pub get
   ```

4. **Code Generation Not Working**
   - Ensure all required annotations are present
   - Check build.yaml configuration
   - Run clean before build

5. **Flavor Generation Issues**
   ```bash
   # Clean and regenerate flavors
   flutter clean
   dart run flutter_flavorizr
   flutter pub get
   ```

### Development Tips

1. **Hot Reload**: Use with caution after BLoC state changes
2. **State Debugging**: Use BLoC Inspector for state debugging
3. **Network Debugging**: Check Dio interceptors for request/response logs
4. **Performance**: Use Flutter Inspector for widget tree analysis

## Useful Scripts

All build scripts are in `tools/` directory:
- `tools/macos/build/` - Build scripts
- `tools/macos/config/` - Configuration scripts
- `tools/macos/distribution/` - Distribution scripts

Run scripts from project root for proper path resolution.