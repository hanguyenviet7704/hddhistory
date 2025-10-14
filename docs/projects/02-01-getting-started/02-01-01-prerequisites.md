# Prerequisites and Requirements

This document outlines the prerequisites and system requirements for developing Dcore Flutter applications.

## System Requirements

### Operating System Support
- **macOS**: Fully supported (recommended for development)
- **Windows**: Basic support (tooling partially implemented)
- **Linux**: Basic support (tooling partially implemented)

> **Important**: Custom development tools in `/tools/` directory are currently optimized for macOS only. Windows and Linux scripts are placeholder implementations for future development.

### Development Environment

#### Required Software
1. **Flutter SDK**
   - Version: >=3.8.0 <4.0.0 (as specified in pubspec.yaml)
   - Installation: [Flutter Installation Guide](https://docs.flutter.dev/get-started/install)

2. **Dart SDK**
   - Included with Flutter SDK
   - Version: >=3.8.0 <4.0.0

3. **Flutter Version Management (FVM)** - Recommended
   - Installation: `dart pub global activate fvm`
   - Project uses FVM as indicated by `.fvmrc` file

4. **Git**
   - For version control and GitFlow workflow
   - Configure with your credentials

#### IDE Options
Choose one of the following IDEs:

##### VS Code / VSCodium
- Install Flutter and Dart extensions
- Pre-configured launch configurations available in `.vscode/launch.json`

##### IntelliJ IDEA / Android Studio
- Install Flutter and Dart plugins
- Pre-configured run configurations available in `.idea/runConfigurations/`

#### Platform-Specific Requirements

##### Android Development
- **Android Studio** or **Android SDK**
- **Android SDK** (API level 21 or higher)
- **Java Development Kit (JDK)** - version 17 recommended

##### iOS Development (macOS only)
- **Xcode** (latest stable version)
- **iOS Simulator** or physical iOS device
- **CocoaPods** for dependency management
- **Apple Developer Account** (for device testing and distribution)

## Additional Tools

### Build and Development Tools

#### Python 3
Required for localization script:
- Used by `tools/macos/localization/generate_localization.sh`
- Virtual environment will be created automatically

#### Node.js and npm
- For any JavaScript-based tooling (if applicable)
- Check `package.json` for specific requirements

### Firebase Setup
The project integrates with Firebase for:
- Analytics
- Crashlytics
- Authentication
- Remote Config
- Push Notifications

#### Firebase CLI
```bash
npm install -g firebase-tools
firebase login
```

#### Firebase Project Configuration
- Development environment Firebase project
- Staging environment Firebase project  
- Production environment Firebase project

Configuration files are located in project root:
- `firebase.json`
- `.info/firebase_info.json`

## Environment Variables

### Required Environment Files
The project uses environment-specific configuration files in `.env/` directory:
- `.env.dev` - Development environment
- `.env.stg` - Staging environment
- `.env.prod` - Production environment

These files contain:
- API endpoints
- Firebase configuration
- Feature flags
- Environment-specific settings

> **Security Note**: Environment files may contain sensitive information. Ensure they are properly configured and never commit sensitive data to version control.

## Version Verification

### Check Flutter Installation
```bash
flutter doctor -v
```

This command will verify:
- Flutter SDK installation
- Platform-specific tooling
- IDE setup
- Connected devices

### Check FVM Setup (if using)
```bash
fvm flutter --version
```

### Verify Project Dependencies
```bash
flutter pub deps
```

## Common Issues and Solutions

### Flutter Doctor Issues

#### Android License Issues
```bash
flutter doctor --android-licenses
```

#### iOS Development Setup
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
```

#### CocoaPods Installation
```bash
sudo gem install cocoapods
pod setup
```

### FVM Issues

#### Set Flutter Version for Project
```bash
fvm use [version] --force
```

#### Global FVM Configuration
```bash
fvm global [version]
```

## Development Machine Setup Checklist

- [ ] Operating system meets requirements
- [ ] Flutter SDK installed and configured
- [ ] IDE with Flutter/Dart plugins installed
- [ ] Android development environment setup (if targeting Android)
- [ ] iOS development environment setup (if targeting iOS, macOS only)
- [ ] Git configured with proper credentials
- [ ] Firebase CLI installed and authenticated
- [ ] Python 3 available for localization scripts
- [ ] FVM installed and configured (recommended)
- [ ] Run `flutter doctor` and resolve any issues
- [ ] Clone project repository
- [ ] Verify access to Firebase projects
- [ ] Environment files configured

## Next Steps

After completing the prerequisites:
1. Follow [Project Setup Guide](02-01-02-project-setup.md)
2. Complete [First-Time Developer Setup](02-01-03-first-time-setup.md)
3. Start development using IDE run configurations

## Support and Troubleshooting

### Flutter Community Resources
- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Community Discord](https://discord.gg/flutter)
- [Flutter GitHub Issues](https://github.com/flutter/flutter/issues)

### Project-Specific Support
- Check project documentation in `docs/` directory
- Review existing issues in project repository
- Consult team members or project maintainers