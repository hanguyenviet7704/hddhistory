# First-Time Developer Setup

This document provides comprehensive guidance for developers setting up Dcore projects for the first time, including IDE configuration and development workflow setup.

## Essential Setup Commands

> **Critical**: These commands must be run in order before starting development:

```bash
# 1. Generate all code files (REQUIRED)
sh tools/macos/resource/generate_file.sh

# 2. Clean and reset project state (REQUIRED)
sh tools/macos/build/reset_app.sh

# 3. Generate localization files (REQUIRED)
sh tools/macos/localization/generate_localization.sh
```

## IDE Configuration

### VS Code / VSCodium Setup

#### Required Extensions
Install the following extensions:
- **Flutter** (by Dart Code)
- **Dart** (by Dart Code)
- **GitLens** (by GitKraken) - for Git integration
- **Bracket Pair Colorizer** (optional) - for code readability

#### Launch Configurations
The project includes pre-configured launch configurations in `.vscode/launch.json`:

##### Available Configurations
- **dev Debug**: Development environment in debug mode
- **dev Profile**: Development environment in profile mode  
- **dev Release**: Development environment in release mode
- **stg Debug**: Staging environment in debug mode
- **stg Profile**: Staging environment in profile mode
- **stg Release**: Staging environment in release mode
- **prod Debug**: Production environment in debug mode
- **prod Profile**: Production environment in profile mode
- **prod Release**: Production environment in release mode

#### Running the Application
1. Open Command Palette (Ctrl/Cmd + Shift + P)
2. Type "Flutter: Launch Emulator" to start Android emulator (if needed)
3. Go to Run and Debug view (Ctrl/Cmd + Shift + D)
4. Select desired configuration (e.g., "dev Debug")
5. Press F5 or click the run button

#### VS Code Settings
The project includes optimized settings in `.vscode/settings.json`:
```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  "flutter.sdkPath": ".fvm/flutter_sdk",
  "search.exclude": {
    "**/*.freezed.dart": true,
    "**/*.g.dart": true
  }
}
```

### IntelliJ IDEA / Android Studio Setup

#### Required Plugins
Install these plugins via Settings > Plugins:
- **Flutter** (includes Dart support)
- **GitToolBox** (optional) - for enhanced Git integration

#### Run Configurations
The project includes pre-configured run configurations in `.idea/runConfigurations/`:

##### Available Configurations
- `main_dart.xml` - Default configuration
- `main_dev_dart.xml` - Development environment
- `main_stg_dart.xml` - Staging environment
- `main_prod_dart.xml` - Production environment

#### Running the Application
1. Open the project in IntelliJ IDEA/Android Studio
2. Wait for indexing to complete
3. Look for run configurations in the toolbar dropdown
4. Select desired configuration (e.g., "main_dev_dart")
5. Click the run button (green triangle)

#### IntelliJ Project Settings
- **SDK**: Ensure Flutter SDK is properly configured
- **Modules**: Verify Flutter module is recognized
- **Code Style**: Dart formatting should be enabled

## Development Workflow Setup

### Git Configuration

#### Configure User Information
```bash
git config user.name "Your Name"
git config user.email "your.email@company.com"
```

#### GitFlow Setup
The project uses GitFlow workflow:
```bash
# Initialize git flow (if not already done)
git flow init

# Verify gitflow configuration
cat .gitflow.config
```

#### Commit Message Template
Create a commit message template:
```bash
# Create template file
cat > ~/.gitmessage << EOF
# type-TICKET-ID: Brief description (50 chars max)
#
# Longer explanation if needed
#
# Examples:
# feature-ARTLEXIS-123: Add user authentication
# fix-ARTLEXIS-456: Resolve login validation bug
EOF

# Configure git to use template
git config commit.template ~/.gitmessage
```

### Environment Understanding

#### Environment Files Structure
```bash
# View environment configurations
ls -la .env/

# Understand each environment
cat .env/.env.dev    # Development settings
cat .env/.env.stg    # Staging settings  
cat .env/.env.prod   # Production settings
```

#### Environment Usage
Each environment file contains:
- API endpoints
- Firebase project configurations
- Feature flags
- Debug settings
- Analytics configurations

### Firebase Setup

#### Firebase Project Access
Verify you have access to Firebase projects:
```bash
firebase login
firebase projects:list
```

#### Firebase Configuration Files
The project uses these Firebase configurations:
- `firebase.json` - Main Firebase configuration
- `.info/firebase_info.json` - Project-specific Firebase settings
- iOS: `ios/Runner/GoogleService-Info.plist`
- Android: `android/app/google-services.json`

### Code Generation Understanding

#### What Gets Generated
The setup scripts generate:
- **JSON Serialization** (`.g.dart` files)
- **Immutable Classes** (`.freezed.dart` files)
- **Dependency Injection** (`injection.config.dart`)
- **Routes** (`app_router.gr.dart`)
- **Localizations** (`app_localizations.dart`)
- **Assets** (`gen/` directory)

#### When to Regenerate
Run code generation when you:
- Add new models with `@JsonSerializable()`
- Create new `@freezed` classes
- Add new dependencies with `@injectable`
- Modify routing definitions
- Add new assets to `pubspec.yaml`

```bash
# Regenerate code when needed
sh tools/macos/resource/generate_file.sh
```

## Development Tools Familiarization

### Custom Scripts Overview

#### macOS Tools (Fully Functional)
```bash
# Build scripts
tools/macos/build/build_apk.sh        # Build Android APK
tools/macos/build/build_appbundle.sh  # Build Android App Bundle
tools/macos/build/build_ios.sh        # Build iOS app
tools/macos/build/reset_app.sh        # Clean and reset project

# Resource management
tools/macos/resource/generate_file.sh # Generate code files

# Localization
tools/macos/localization/generate_localization.sh # Generate translations

# Configuration
tools/macos/config/firebase_setup.sh  # Firebase configuration
```

#### Windows/Linux Tools (Placeholder)
> **Note**: Windows and Linux scripts in `tools/windows/` and `tools/linux/` are placeholders for future development. Use manual Flutter commands on these platforms.

### Build Process Understanding

#### --dart-define-from-file Usage
The project uses `--dart-define-from-file` (NOT `--dart-define`):
```bash
# This is how the project builds
flutter build apk --flavor dev --dart-define-from-file=.env/.env.dev

# NOT this way
flutter build apk --flavor dev --dart-define=ENVIRONMENT=dev
```

#### Multi-Flavor Architecture
- **dev**: Development builds with debug features
- **stg**: Staging builds mimicking production  
- **prod**: Production builds with optimizations

## Testing Your Setup

### Verification Checklist

#### 1. Code Generation Test
```bash
# Should complete without errors
sh tools/macos/resource/generate_file.sh
```

#### 2. Build Test
```bash
# Should build successfully
flutter build apk --flavor dev --dart-define-from-file=.env/.env.dev
```

#### 3. Localization Test
```bash
# Should generate localization files
sh tools/macos/localization/generate_localization.sh
```

#### 4. IDE Integration Test
- Open project in your IDE
- Select a run configuration
- Should run without errors

### Common First-Time Issues

#### Build Runner Conflicts
```bash
# Solution: Clean and regenerate
flutter packages pub run build_runner clean
sh tools/macos/resource/generate_file.sh
```

#### Missing Generated Files
```bash
# Solution: Ensure all setup scripts ran
sh tools/macos/build/reset_app.sh
sh tools/macos/resource/generate_file.sh
sh tools/macos/localization/generate_localization.sh
```

#### Environment File Issues
- Verify `.env/` files exist and contain proper configuration
- Contact team if environment files are missing or incomplete

#### IDE Configuration Issues
- Ensure Flutter/Dart plugins are installed and enabled
- Verify Flutter SDK path is correctly configured
- Check that run configurations are available

## Development Best Practices

### Daily Workflow
1. **Start of Day**:
   ```bash
   git checkout develop
   git pull origin develop
   ```

2. **Before Starting New Feature**:
   ```bash
   git checkout -b feature/ARTLEXIS-XXX-description
   ```

3. **During Development**:
   - Use IDE run configurations
   - Make frequent, small commits
   - Follow commit message conventions

4. **Before Committing**:
   - Ensure code is properly formatted
   - Run tests if available
   - Verify build works

### Code Organization
- Follow Clean Architecture patterns
- Use BLoC for state management  
- Implement proper error handling
- Write descriptive commit messages

### Performance Tips
- Use `const` constructors where possible
- Implement proper disposal for controllers
- Use `ListView.builder` for large lists
- Cache network images appropriately

## Getting Help

### Resources
1. **Project Documentation**: `docs/` directory
2. **Flutter Documentation**: [docs.flutter.dev](https://docs.flutter.dev)
3. **Team Resources**: Check team communication channels

### Troubleshooting Steps
1. Check Flutter Doctor: `flutter doctor -v`
2. Verify environment files are configured
3. Ensure all setup scripts completed successfully
4. Check IDE plugin configuration
5. Review error messages carefully
6. Consult team members or documentation

### Emergency Reset
If everything breaks, start over:
```bash
# Nuclear option - complete reset
flutter clean
rm -rf build/
rm -rf .dart_tool/
flutter pub get
sh tools/macos/build/reset_app.sh
sh tools/macos/resource/generate_file.sh
sh tools/macos/localization/generate_localization.sh
```

## Next Steps

After completing first-time setup:
1. Explore the [Project Architecture](../02-02-project-architecture/) documentation
2. Review [Build Process](../02-03-build-process/) documentation
3. Understand [Environment Configuration](../02-04-environment-configuration/)
4. Familiarize yourself with [Development Tools](../02-05-development-tools/)
5. Start contributing to the project following established patterns