# IntelliJ IDEA / Android Studio Setup

This document provides comprehensive guidance for setting up and using IntelliJ IDEA or Android Studio for Dcore Flutter development.

## Pre-configured Setup

The project includes pre-configured run configurations in the `.idea/runConfigurations/` directory for immediate development.

### Included Configuration Files
- `.idea/runConfigurations/main_dart.xml` - Default configuration
- `.idea/runConfigurations/main_dev_dart.xml` - Development environment
- `.idea/runConfigurations/main_stg_dart.xml` - Staging environment  
- `.idea/runConfigurations/main_prod_dart.xml` - Production environment

## Required Plugins

### Essential Plugins
Install these plugins via Settings > Plugins:

1. **Flutter** 
   - Complete Flutter framework support
   - Includes Dart language support
   - Widget inspector integration
   - Hot reload and hot restart
   - Flutter-specific refactoring tools

2. **Dart** (usually included with Flutter plugin)
   - Dart language support
   - Syntax highlighting and completion
   - Debugging capabilities
   - Code analysis and linting

### Recommended Plugins
These plugins enhance the development experience:

3. **GitToolBox**
   - Enhanced Git integration
   - Inline blame information
   - Branch management tools
   - Commit status tracking

4. **Rainbow Brackets**
   - Color-coded bracket matching
   - Better code readability in nested structures
   - Customizable color schemes

5. **Material Theme UI**
   - Modern UI theme
   - Better visual experience
   - Multiple theme variants

6. **String Manipulation**
   - Text transformation utilities
   - Case conversion tools
   - Useful for naming conventions

## Run Configurations

The project includes pre-configured run configurations for all environments.

### Available Configurations

#### main_dev_dart.xml
- **Environment**: Development
- **Target**: `lib/main_dev.dart`
- **Flavor**: dev
- **Environment File**: `.env/.env.dev`

#### main_stg_dart.xml  
- **Environment**: Staging
- **Target**: `lib/main_stg.dart`
- **Flavor**: stg
- **Environment File**: `.env/.env.stg`

#### main_prod_dart.xml
- **Environment**: Production
- **Target**: `lib/main_prod.dart`
- **Flavor**: prod
- **Environment File**: `.env/.env.prod`

### Configuration Structure

Each run configuration includes:
```xml
<component name="ProjectRunConfigurationManager">
  <configuration name="main_dev.dart" type="FlutterRunConfigurationType">
    <option name="filePath" value="$PROJECT_DIR$/lib/main_dev.dart" />
    <option name="additionalArgs" value="--flavor dev --dart-define-from-file .env/.env.dev" />
    <method v="2" />
  </configuration>
</component>
```

Key elements:
- **Target file**: Environment-specific main.dart file
- **Flavor**: Build flavor for multi-environment support
- **Environment variables**: Loaded from `.env` files via `--dart-define-from-file`

## Project Setup

### Opening the Project

#### First-Time Setup
1. Open IntelliJ IDEA or Android Studio
2. Choose "Open" from start screen
3. Navigate to project root directory
4. Select the directory (not pubspec.yaml)
5. Wait for project indexing to complete

#### Verify Setup
After opening, verify:
- Flutter SDK is detected and configured
- Dart plugin is enabled
- Run configurations are available
- Project structure is recognized

### Flutter SDK Configuration

#### Automatic Detection
IntelliJ should automatically detect Flutter SDK if:
- Flutter is properly installed
- Flutter is in system PATH
- Flutter plugin is installed and enabled

#### Manual Configuration
If automatic detection fails:
1. Go to File > Settings (or IntelliJ IDEA > Preferences on macOS)
2. Navigate to Languages & Frameworks > Flutter
3. Set Flutter SDK path (e.g., `/path/to/flutter`)
4. Verify Dart SDK path is automatically set
5. Apply and restart if needed

#### FVM Integration
If using Flutter Version Management (FVM):
1. Set Flutter SDK path to `.fvm/flutter_sdk` in project directory
2. This ensures consistent Flutter version across team
3. May require absolute path: `/full/path/to/project/.fvm/flutter_sdk`

## Running the Application

### Using Run Configurations

#### Method 1: Toolbar Dropdown
1. Look for run configuration dropdown in toolbar
2. Select desired configuration (e.g., "main_dev.dart")
3. Click the green run button (▶️) or debug button (🐛)
4. Application launches with selected environment

#### Method 2: Run Menu
1. Go to Run menu in menu bar
2. Select "Run..." or "Debug..."
3. Choose from list of available configurations
4. Application starts with hot reload enabled

#### Method 3: Right-Click Context Menu
1. Right-click on main_dev.dart (or other main file) in project view
2. Select "Run main_dev.dart" or "Debug main_dev.dart"
3. Uses default configuration for that file

### Device Selection
1. Look for device selector in toolbar
2. Click to see available devices/emulators
3. Select target device
4. Run configuration will use selected device

## Development Features

### Hot Reload and Hot Restart

#### Hot Reload
- **Action**: Click hot reload button (🔄) or press Ctrl/Cmd + \
- **Keyboard shortcut**: Ctrl/Cmd + S (if enabled in settings)
- **Usage**: Apply code changes without losing app state
- **Best for**: UI changes, styling updates

#### Hot Restart  
- **Action**: Click hot restart button (⚡) or press Ctrl/Cmd + Shift + \
- **Usage**: Restart app completely while maintaining debug connection
- **Best for**: State structure changes, adding new dependencies

### Debugging Features

#### Breakpoints
- **Setting**: Click in gutter next to line number
- **Conditional**: Right-click breakpoint > Add condition
- **Logging**: Right-click breakpoint > Evaluate and log
- **Managing**: View > Tool Windows > Breakpoints

#### Debug Windows
- **Variables**: View current variable values
- **Watches**: Monitor specific expressions
- **Call Stack**: Navigate through function calls
- **Console**: Execute expressions at runtime

#### Flutter Inspector
- **Access**: During debug session, Flutter Inspector tab appears
- **Features**: Visual widget tree, property inspection
- **Usage**: Debug layout issues, understand widget hierarchy
- **Integration**: Real-time sync with running app

### Flutter-Specific Tools

#### Widget Refactoring
- **Wrap with Widget**: Alt + Enter on widget > Wrap with...
- **Extract Widget**: Alt + Enter > Extract Flutter Widget
- **Add/Remove Properties**: Quick fixes for common widget modifications

#### Code Generation
- **Build Runner**: Tools > Flutter > Flutter Pub Run Build Runner
- **Asset Generation**: Automatic recognition of asset changes
- **Localization**: Integration with Flutter's l10n tools

#### Package Management
- **Pub Get**: Tools > Flutter > Flutter Pub Get
- **Pub Upgrade**: Tools > Flutter > Flutter Pub Upgrade
- **Pub Outdated**: Shows outdated dependencies

## Project-Specific Configuration

### Code Style Settings
Configure Dart code style:
1. Settings > Editor > Code Style > Dart
2. Set tab size to 2 spaces
3. Enable "Format code on save"
4. Configure line length (usually 80)

### File Templates
Create custom file templates:
1. Settings > Editor > File and Code Templates
2. Create templates for common Flutter patterns
3. Include standard imports and structure

### Live Templates
Set up code snippets:
1. Settings > Editor > Live Templates
2. Add Flutter-specific templates
3. Create shortcuts for common patterns

## Build and Distribution

### Building APKs
While run configurations are for development, for building release artifacts:

#### Using Terminal
Access built-in terminal and use project scripts:
```bash
# Build development APK
sh tools/macos/build/build_apk.sh dev

# Build staging APK
sh tools/macos/build/build_apk.sh stg

# Build production APK  
sh tools/macos/build/build_apk.sh prod
```

#### Using Flutter Build
Access via terminal or external tools:
```bash
flutter build apk --flavor dev --dart-define-from-file=.env/.env.dev
```

### External Tools Integration
Configure custom external tools:
1. Settings > Tools > External Tools
2. Add custom tools for build scripts
3. Configure shortcuts and output handling

## Troubleshooting

### Common Issues

#### Flutter Not Detected
**Symptoms**: No Flutter run configurations, Flutter menu missing
**Solution**:
1. Verify Flutter plugin is installed and enabled
2. Check Flutter SDK path in settings
3. Ensure Flutter is properly installed and in PATH
4. Restart IDE and reopen project

#### Run Configurations Missing
**Symptoms**: No pre-configured run options available
**Solution**:
1. Verify `.idea/runConfigurations/` directory exists
2. Check XML files are present and valid
3. Refresh project structure (File > Reload Gradle/Maven Project)
4. Manually import configurations if needed

#### Environment Variables Not Loading
**Symptoms**: App uses wrong configuration, missing environment values
**Solution**:
1. Verify environment files exist and contain proper format
2. Check run configuration includes correct `--dart-define-from-file` path
3. Ensure no typos in file paths or variable names
4. Restart run configuration after environment changes

#### Hot Reload Not Working
**Symptoms**: Changes not reflected in running app
**Solution**:
1. Ensure app is running in debug mode (not profile or release)
2. Verify changes are in Dart files (not assets or pubspec.yaml)
3. Try hot restart instead of hot reload
4. Check for compilation errors in event log

#### Performance Issues
**Symptoms**: Slow IDE performance, high memory usage
**Solution**:
1. Increase IDE memory allocation in Help > Change Memory Settings
2. Exclude build directories from indexing
3. Close unused projects and files
4. Disable unused plugins
5. Clear caches and restart (File > Invalidate Caches and Restart)

### Debug Log Access
- **Event Log**: View > Tool Windows > Event Log
- **Flutter Console**: During debug session, console tab shows Flutter output
- **Build Output**: Build tool window shows compilation details

## Advanced Configuration

### Custom Run Configurations
Create additional run configurations:
1. Run > Edit Configurations
2. Click + to add new Flutter configuration
3. Configure target file, additional arguments, environment variables
4. Save with descriptive name

### Environment Variables in IDE
Set IDE-level environment variables:
1. Run > Edit Configurations
2. Select configuration to modify
3. Expand Environment Variables section
4. Add variables as needed (though .env files are preferred)

### Integration with Version Control
- **Git Integration**: Built-in Git support with diff views
- **Change Tracking**: Visual indication of modified files
- **Commit Tools**: Integrated commit and push functionality
- **Blame Information**: View commit history for specific lines

### Multi-Module Projects
For complex projects with multiple modules:
1. Configure project structure properly
2. Set up module dependencies
3. Use project-wide search and navigation
4. Configure build settings per module

## Best Practices

### Development Workflow
1. **Use debug configurations** for daily development
2. **Test with different environments** regularly
3. **Use hot reload** for rapid iteration
4. **Profile performance** with profile builds
5. **Test release builds** before deployment

### IDE Organization
- **Keep project structure clean** with proper file organization
- **Use meaningful run configuration names**
- **Configure shortcuts** for frequently used actions
- **Organize tool windows** for optimal workflow

### Team Collaboration
- **Share run configurations** via version control
- **Document custom setup** requirements
- **Use consistent IDE settings** across team
- **Maintain plugin compatibility** across team members

### Performance Optimization
- **Close unused projects** to reduce memory usage
- **Use power save mode** when not actively developing
- **Regular cache cleanup** to maintain performance
- **Monitor memory usage** and adjust settings as needed