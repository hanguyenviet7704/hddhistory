# VS Code Setup and Configuration

This document provides comprehensive guidance for setting up and using VS Code (or VSCodium) for Dcore Flutter development.

## Pre-configured Setup

The project includes pre-configured VS Code settings and launch configurations for immediate development without additional setup.

### Included Configuration Files
- `.vscode/launch.json` - Debug and run configurations
- `.vscode/settings.json` - Project-specific settings (if present)

## Required Extensions

### Essential Extensions
Install these extensions for full Flutter development support:

1. **Flutter** (by Dart Code)
   - Flutter framework support
   - Hot reload functionality  
   - Widget inspector
   - Command palette integration

2. **Dart** (by Dart Code)
   - Dart language support
   - Syntax highlighting
   - Code completion
   - Debugging support

### Recommended Extensions
These extensions enhance the development experience:

3. **GitLens** (by GitKraken)
   - Enhanced Git integration
   - Blame annotations
   - Commit history visualization
   - Branch comparison tools

4. **Bracket Pair Colorizer 2** (by CoenraadS)
   - Color-coded matching brackets
   - Better code readability
   - Nested structure visualization

5. **Material Icon Theme** (by Philipp Kief)
   - Better file and folder icons
   - Improved project navigation
   - Flutter-specific icons

6. **Error Lens** (by Alexander)
   - Inline error and warning display
   - Improved error visibility
   - Faster bug identification

## Launch Configurations

The project includes comprehensive launch configurations for all environments and modes.

### Available Configurations

#### Development Environment
- **dev Debug**: Development environment in debug mode
  - Fast hot reload
  - Debug console access
  - Development API endpoints
  - Enhanced logging

- **dev Profile**: Development environment in profile mode
  - Performance profiling enabled
  - Reduced debug overhead
  - Production-like performance

- **dev Release**: Development environment in release mode
  - Fully optimized build
  - No debug information
  - Production performance

#### Staging Environment
- **stg Debug**: Staging environment in debug mode
- **stg Profile**: Staging environment in profile mode  
- **stg Release**: Staging environment in release mode

#### Production Environment
- **prod Debug**: Production environment in debug mode
- **prod Profile**: Production environment in profile mode
- **prod Release**: Production environment in release mode

### Launch Configuration Details

Each configuration includes:
```json
{
  "name": "dev Debug",
  "request": "launch",
  "type": "dart",
  "flutterMode": "debug",
  "args": [
    "--flavor",
    "dev",
    "--dart-define-from-file",
    ".env/.env.dev"
  ],
  "program": "lib/main_dev.dart"
}
```

Key features:
- **Flavor specification**: Correct build flavor for environment
- **Environment file**: Automatic loading of environment variables
- **Target file**: Environment-specific main file
- **Flutter mode**: Appropriate mode for use case

## Using VS Code for Development

### Running the Application

#### Method 1: Run and Debug Panel
1. Open Run and Debug view (Ctrl/Cmd + Shift + D)
2. Select desired configuration from dropdown
3. Press F5 or click the run button
4. Application launches with selected configuration

#### Method 2: Command Palette
1. Open Command Palette (Ctrl/Cmd + Shift + P)
2. Type "Flutter: Select Device" to choose target device
3. Type "Flutter: Run Flutter" and select configuration
4. Application launches with hot reload enabled

#### Method 3: Status Bar
1. Ensure device is connected and visible in status bar
2. Click device name to select different device
3. Use F5 to run with current configuration
4. Use Ctrl/Cmd + F5 to run without debugging

### Hot Reload and Hot Restart

#### Hot Reload
- **Shortcut**: r (in terminal) or Ctrl/Cmd + F5
- **Usage**: Apply code changes without losing app state
- **Best for**: UI updates, minor logic changes
- **Limitations**: Cannot reload after changing app state structure

#### Hot Restart
- **Shortcut**: R (in terminal) or Ctrl/Cmd + Shift + F5
- **Usage**: Restart app completely while maintaining debug connection
- **Best for**: State management changes, dependency updates
- **Effect**: Clears app state and restarts from main()

### Debugging Features

#### Breakpoints
- **Set breakpoints**: Click in gutter or press F9
- **Conditional breakpoints**: Right-click breakpoint, add condition
- **Logpoints**: Right-click breakpoint, convert to logpoint
- **Function breakpoints**: Debug > Add Function Breakpoint

#### Debug Console
- **Access**: Debug Console tab during debugging session
- **Features**: Execute Dart expressions at runtime
- **Commands**: Print variables, call functions, inspect objects
- **Hot expressions**: Watch expressions update in real-time

#### Variable Inspection
- **Variables panel**: View all in-scope variables
- **Watch expressions**: Monitor specific values
- **Call stack**: Navigate through function calls
- **Debug hover**: Hover over variables to see values

### Flutter-Specific Features

#### Widget Inspector
- **Access**: Debug > Open Widget Inspector (during debug session)
- **Features**: Visual widget tree exploration
- **Usage**: Identify widget hierarchy, debug layout issues
- **Integration**: Automatically syncs with running application

#### Performance Profiling
- **Access**: Command Palette > "Flutter: Open DevTools"
- **Features**: CPU profiler, memory profiler, network inspector
- **Usage**: Analyze app performance, identify bottlenecks
- **Modes**: Works best with profile builds

#### Outline View
- **Access**: Explorer > Outline section
- **Features**: Shows widget structure of current file
- **Navigation**: Click to jump to specific widgets
- **Refactoring**: Right-click for refactoring options

## Project-Specific Configuration

### FVM Integration
If using Flutter Version Management (FVM):

#### Settings Configuration
```json
{
  "dart.flutterSdkPath": ".fvm/flutter_sdk",
  "flutter.sdkPath": ".fvm/flutter_sdk"
}
```

#### Benefits
- Consistent Flutter version across team
- Project-specific Flutter SDK
- Easier version management

### File Exclusions
Recommended settings to hide generated files:

```json
{
  "search.exclude": {
    "**/*.freezed.dart": true,
    "**/*.g.dart": true,
    "**/*.gr.dart": true,
    "**/build/": true,
    "**/.dart_tool/": true
  },
  "files.exclude": {
    "**/*.g.dart": true,
    "**/*.freezed.dart": true
  }
}
```

Benefits:
- Cleaner file explorer
- Faster search results
- Focus on source files only

### Code Formatting
Automatic formatting configuration:

```json
{
  "editor.formatOnSave": true,
  "editor.formatOnType": true,
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.tabSize": 2,
    "editor.insertSpaces": true
  }
}
```

## Workflow Tips and Tricks

### Keyboard Shortcuts

#### Flutter-Specific
- **F5**: Start debugging
- **Ctrl/Cmd + F5**: Start without debugging
- **Shift + F5**: Stop debugging
- **Ctrl/Cmd + Shift + P**: Command Palette
- **Ctrl/Cmd + Shift + D**: Open Run and Debug

#### Code Navigation
- **Ctrl/Cmd + P**: Quick file open
- **Ctrl/Cmd + Shift + O**: Go to symbol in file
- **F12**: Go to definition
- **Alt + F12**: Peek definition
- **Shift + F12**: Find all references

#### Editing
- **Ctrl/Cmd + D**: Select word (repeat to select more)
- **Ctrl/Cmd + Shift + L**: Select all occurrences
- **Alt + Click**: Multi-cursor editing
- **Ctrl/Cmd + /**: Toggle line comment
- **Shift + Alt + F**: Format document

### Code Snippets
VS Code includes built-in Flutter snippets:

- **stl**: Create StatelessWidget
- **stf**: Create StatefulWidget
- **scaf**: Create Scaffold
- **container**: Create Container
- **column**: Create Column
- **row**: Create Row

### Terminal Integration
- **Access**: Terminal > New Terminal
- **Usage**: Run build scripts, Flutter commands
- **Benefits**: Stay in VS Code while using command-line tools

```bash
# Run build scripts from integrated terminal
sh tools/macos/build/build_apk.sh dev
sh tools/macos/resource/generate_file.sh
```

## Troubleshooting

### Common Issues

#### Flutter Not Detected
**Solution**:
1. Install Flutter and Dart extensions
2. Ensure Flutter is in PATH
3. Run "Flutter: Select Device" from Command Palette
4. Check VS Code Flutter SDK setting

#### Launch Configurations Not Working
**Solution**:
1. Verify `.vscode/launch.json` exists
2. Check environment files exist (.env/.env.dev, etc.)
3. Ensure main_dev.dart, main_stg.dart, main_prod.dart exist
4. Reload VS Code window

#### Hot Reload Not Working
**Solution**:
1. Ensure debug mode is selected (not release)
2. Check that changes are in Dart files (not assets)
3. Try hot restart instead
4. Restart debug session if needed

#### Environment Variables Not Loading
**Solution**:
1. Verify environment files exist and contain proper format
2. Check launch configuration includes `--dart-define-from-file`
3. Ensure no typos in environment file paths
4. Restart debug session after environment changes

### Performance Issues

#### Slow IntelliSense
**Solutions**:
- Exclude generated files from search
- Close unused files and windows
- Increase VS Code memory allocation
- Update Flutter and Dart extensions

#### Large Project Handling
**Optimizations**:
- Use workspace settings for large projects
- Exclude build directories from file watcher
- Disable unused extensions
- Use outline view for navigation

## Advanced Configuration

### Custom Tasks
Create build tasks in `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Build APK Dev",
      "type": "shell",
      "command": "sh",
      "args": ["tools/macos/build/build_apk.sh", "dev"],
      "group": "build",
      "presentation": {
        "echo": true,
        "reveal": "always"
      }
    }
  ]
}
```

### Multi-root Workspaces
For managing multiple Flutter projects:

```json
{
  "folders": [
    {
      "name": "Dcore",
      "path": "."
    },
    {
      "name": "Shared Libraries",
      "path": "../shared"
    }
  ]
}
```

### Extension Recommendations
Create `.vscode/extensions.json`:

```json
{
  "recommendations": [
    "dart-code.flutter",
    "dart-code.dart-code",
    "eamodio.gitlens",
    "coenraads.bracket-pair-colorizer-2"
  ]
}
```

## Best Practices

### Development Workflow
1. **Start with debug mode** for development
2. **Use profile mode** for performance testing
3. **Test release mode** before deployment
4. **Switch environments** to test different APIs
5. **Use hot reload** for rapid UI development

### Code Organization
- Keep main files (main_dev.dart, etc.) minimal
- Use proper imports and exports
- Follow Dart/Flutter style guidelines
- Leverage VS Code refactoring tools

### Project Maintenance
- Keep extensions updated
- Review launch configurations periodically
- Update VS Code settings as project evolves
- Share configuration with team members