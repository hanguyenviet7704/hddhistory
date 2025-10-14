# Building for iOS

This document provides detailed instructions for building iOS applications in Dcore projects.

## iOS Build Script

### Primary Build Tool
**File**: `tools/macos/build/build_ios.sh`
**Purpose**: Generate iOS applications for testing and App Store distribution

### Basic Usage
```bash
# Build development iOS app
sh tools/macos/build/build_ios.sh dev

# Build staging iOS app  
sh tools/macos/build/build_ios.sh stg

# Build production iOS app
sh tools/macos/build/build_ios.sh prod
```

### Build Process Details

#### Environment Mapping
The script automatically maps flavors to environment files:

| Flavor | Environment File | Purpose |
|--------|------------------|---------|
| `dev` | `.env/.env.dev` | Development testing |
| `stg` | `.env/.env.stg` | Staging/pre-production |
| `prod` | `.env/.env.prod` | Production release |

#### Build Command
The script executes:
```bash
fvm flutter build ios \
    --release \
    --obfuscate \
    --split-debug-info=".obfuscation" \
    --flavor "$FLAVOR" \
    --dart-define-from-file="$ENV_FILE" \
    -t "lib/main_$FLAVOR.dart"
```

#### Build Features
- **Release Mode**: Optimized for production
- **Code Obfuscation**: Protects source code
- **Debug Symbols**: Separated for crash analysis
- **Environment Variables**: Loaded from `.env` files
- **Flavor Support**: Multi-environment builds

### Output Location
iOS builds are generated in:
```
build/ios/iphoneos/
├── Runner.app              # iOS application bundle
└── Runner.app.dSYM/        # Debug symbols (if enabled)
```

## Manual Build Commands

For building without scripts (or understanding the underlying process):

### iOS App Build
```bash
# Development
flutter build ios --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart --release --obfuscate --split-debug-info=.obfuscation

# Staging
flutter build ios --flavor stg --dart-define-from-file=.env/.env.stg -t lib/main_stg.dart --release --obfuscate --split-debug-info=.obfuscation

# Production
flutter build ios --flavor prod --dart-define-from-file=.env/.env.prod -t lib/main_prod.dart --release --obfuscate --split-debug-info=.obfuscation
```

### Additional Build Options
```bash
# Build without obfuscation (for debugging)
flutter build ios --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart --release

# Build for simulator
flutter build ios --simulator --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart --debug

# Build with specific iOS deployment target
flutter build ios --flavor prod --dart-define-from-file=.env/.env.prod -t lib/main_prod.dart --release --ios-deployment-target=12.0
```

## iOS-Specific Configuration

### Xcode Project Structure
```
ios/
├── Runner.xcworkspace/          # Main workspace
├── Runner.xcodeproj/           # Xcode project
├── Runner/                     # Main app target
│   ├── Info-dev.plist         # Development configuration
│   ├── Info-stg.plist         # Staging configuration
│   ├── Info-prod.plist        # Production configuration
│   ├── GoogleService-Info-dev.plist
│   ├── GoogleService-Info-stg.plist
│   ├── GoogleService-Info-prod.plist
│   └── Assets.xcassets/       # App icons and assets
└── Podfile                    # CocoaPods dependencies
```

### Flavor Configuration
iOS flavors are managed through Xcode schemes and configurations.

#### Info.plist Files
Each flavor has its own Info.plist:

##### Info-dev.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>Dcore Dev</string>
    <key>CFBundleIdentifier</key>
    <string>com.eup.meup.dev</string>
    <key>CFBundleName</key>
    <string>artlexis_dev</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
</dict>
</plist>
```

##### Info-prod.plist
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>Dcore</string>
    <key>CFBundleIdentifier</key>
    <string>com.eup.meup</string>
    <key>CFBundleName</key>
    <string>meup</string>
    <key>CFBundleVersion</key>
    <string>$(FLUTTER_BUILD_NUMBER)</string>
    <key>CFBundleShortVersionString</key>
    <string>$(FLUTTER_BUILD_NAME)</string>
</dict>
</plist>
```

### App Icons and Assets
Each flavor can have different app icons:

```
ios/Runner/Assets.xcassets/
├── AppIcon-dev.appiconset/     # Development app icon
├── AppIcon-stg.appiconset/     # Staging app icon
├── AppIcon-prod.appiconset/    # Production app icon
└── LaunchImage.imageset/       # Launch screen images
```

### Code Signing
iOS builds require proper code signing configuration:

#### Development Code Signing
- Development certificates from Apple Developer account
- Development provisioning profiles
- Automatic signing (recommended for development)

#### Distribution Code Signing
- Distribution certificates
- App Store provisioning profiles
- Manual signing (recommended for production)

#### Xcode Configuration
```bash
# Set development team (replace with your team ID)
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release-dev \
  DEVELOPMENT_TEAM=YOUR_TEAM_ID \
  build
```

## Firebase Integration

### Automatic Crashlytics Upload
Build scripts automatically upload debug symbols to Firebase Crashlytics:

```bash
echo "🔥 Uploading debug symbols to Firebase Crashlytics..."
FIREBASE_SETUP_SCRIPT="tools/macos/config/firebase_setup.sh"

if [[ -f "$FIREBASE_SETUP_SCRIPT" ]]; then
    "$FIREBASE_SETUP_SCRIPT" "$FLAVOR" "ios"
    
    if [[ $? -eq 0 ]]; then
        echo "✅ Debug symbols uploaded successfully!"
    else
        echo "⚠️  Debug symbols upload failed, but iOS build was successful."
    fi
fi
```

### Firebase Configuration Files
Each flavor uses its own Firebase configuration:

```
ios/Runner/
├── GoogleService-Info-dev.plist    # Development Firebase
├── GoogleService-Info-stg.plist    # Staging Firebase
└── GoogleService-Info-prod.plist   # Production Firebase
```

### Firebase Setup in Xcode
1. Add appropriate GoogleService-Info.plist to each scheme
2. Configure build phases to select correct plist
3. Ensure Firebase SDK is properly integrated via CocoaPods

## CocoaPods Integration

### Podfile Configuration
```ruby
# ios/Podfile
platform :ios, '12.0'

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "Generated.xcconfig must exist"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in Generated.xcconfig"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # Firebase
  pod 'FirebaseCore'
  pod 'FirebaseCrashlytics'
  pod 'FirebaseAnalytics'
  
  # Additional iOS-specific pods
  pod 'GoogleSignIn'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # iOS deployment target
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
```

### Pod Installation
```bash
cd ios
pod install --repo-update
cd ..
```

## App Store Distribution

### Build for Distribution
```bash
# Build production version for App Store
sh tools/macos/build/build_ios.sh prod
```

### Archive Creation
After building, create an archive in Xcode:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select "Any iOS Device" as destination
3. Product > Archive
4. Follow App Store Connect upload process

### Automated Distribution
Use the distribution script:
```bash
sh tools/macos/distribution/upload_appstore.sh prod
```

This script:
- Builds the iOS app
- Creates an archive
- Uploads to App Store Connect
- Submits for TestFlight or App Store review

## Testing and Distribution

### Local Testing
Test iOS builds on device:
```bash
# Build and install on connected device
flutter install --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart
```

### TestFlight Distribution
1. Build production iOS app
2. Archive in Xcode
3. Upload to App Store Connect
4. Add external testers in App Store Connect
5. Submit for TestFlight review

### App Store Release
1. Build production iOS app with all optimizations
2. Test thoroughly on physical devices
3. Archive and upload to App Store Connect
4. Complete App Store Connect metadata
5. Submit for App Store review

## Troubleshooting

### Common Build Issues

#### Code Signing Issues
```bash
# Check certificates and provisioning profiles
security find-identity -v -p codesigning

# Update provisioning profiles
xcode-select --install
```

#### CocoaPods Issues  
```bash
# Clean and reinstall pods
cd ios
rm -rf Pods/
rm Podfile.lock
pod deintegrate
pod install --repo-update
cd ..
```

#### Xcode Version Issues
```bash
# Check Xcode version compatibility
xcode-select --print-path
flutter doctor
```

#### Build Configuration Issues
```bash
# Clean Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/

# Clean Flutter build
flutter clean
```

### Debug Commands
```bash
# Verbose iOS build
flutter build ios --verbose --flavor dev --dart-define-from-file=.env/.env.dev -t lib/main_dev.dart

# Check iOS setup
flutter doctor --verbose

# List iOS devices
flutter devices

# Check Xcode build settings
xcodebuild -workspace ios/Runner.xcworkspace -list
```

### Firebase Symbol Upload Issues
```bash
# Manual symbol upload
firebase crashlytics:symbols:upload --app=1:your-ios-app-id .obfuscation/

# Check Firebase project
firebase projects:list
firebase use your-project-id
```

## Performance Optimization

### Build Size Optimization
```bash
# Analyze app size
flutter build ios --analyze-size --flavor prod

# Enable tree shaking (default)
flutter build ios --tree-shake-icons --flavor prod
```

### Runtime Performance
- Enable metal rendering (default in newer iOS)
- Optimize image assets for iOS
- Use iOS-specific optimizations
- Test on older devices

### Memory Management
- Profile memory usage with Xcode Instruments
- Monitor for memory leaks
- Optimize image loading and caching
- Use proper disposal patterns

## Best Practices

### Development Workflow
- Use development builds for daily testing
- Test on multiple iOS devices and versions
- Use staging builds for pre-release testing
- Only use production builds for App Store submission

### Code Signing
- Use automatic signing for development
- Use manual signing for distribution
- Keep certificates and provisioning profiles updated
- Test signing configuration regularly

### Distribution
- Test thoroughly before App Store submission
- Use TestFlight for beta testing
- Monitor crash reports and performance metrics
- Keep App Store metadata updated

### Security
- Enable app transport security (ATS)
- Protect sensitive data with Keychain
- Implement certificate pinning for API calls
- Regular security audits and updates

### Performance
- Profile app performance regularly
- Monitor memory usage and battery impact
- Optimize for different device capabilities
- Test on oldest supported iOS version