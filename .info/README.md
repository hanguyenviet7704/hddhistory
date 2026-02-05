# .info Directory - Project Configuration

Centralized configuration directory for the Meup Flutter project.

## 📁 Directory Structure

```
.info/
├── app/                    # Application configuration
│   ├── app.json           # App metadata, flavors, platform configs
│   ├── firebase.json      # Firebase project and app configuration
│   ├── build.json         # Build settings and output paths
│   └── paths.json         # Project path configurations
├── distribution/          # Distribution data files (text-based)
│   ├── tester_list.txt    # Tester email addresses
│   ├── tester_group.txt   # Distribution group names
│   ├── release_note.txt   # Custom release notes
│   ├── test_device.txt    # Test devices for automation
│   └── test_password.txt  # Test account password
└── key/                   # Security keys and certificates
    └── AuthKey_*.p8       # App Store Connect API key
```

## 🔧 Configuration Files

### app/app.json
Main application configuration:
- App name and display names
- Version and build number
- Android package names and SDK versions
- iOS bundle IDs and team information
- Flavor-specific configurations

**Example:**
```json
{
  "appName": "Meup",
  "version": "1.0.0",
  "buildNumber": "1",
  "android": {
    "packageName": "com.eup.meup",
    "compileSdk": 34
  },
  "ios": {
    "bundleId": "com.eup.meup",
    "teamId": "YOUR_TEAM_ID"
  },
  "flavors": {
    "dev": { ... },
    "stg": { ... },
    "prod": { ... }
  }
}
```

### app/firebase.json
Firebase project configuration:
- Project IDs per environment
- App IDs for Android and iOS
- Distribution settings (testers, groups)
- Slack webhook configuration

**Example:**
```json
{
  "projects": {
    "dev": "project-dev",
    "stg": "project-stg",
    "prod": "project-prod"
  },
  "apps": {
    "android": { ... },
    "ios": { ... }
  },
  "distribution": {
    "testers": { ... },
    "groups": { ... },
    "releaseNotes": { ... }
  }
}
```

### app/build.json
Build configuration:
- Flutter/FVM settings
- Build arguments
- Output paths
- Optimization settings

### app/paths.json
Path configurations:
- Environment file locations
- Firebase config paths
- Output directories

## 📝 Distribution Data Files

Distribution data files use a simple text format:
- One entry per line
- Lines starting with `#` are comments
- Empty lines are ignored
- No JSON formatting required

### distribution/tester_list.txt
Email addresses of testers (one per line):
```
# Tester List
dev-team@company.com
qa-team@company.com
beta-tester@company.com
```

### distribution/tester_group.txt
Distribution group names (one per line):
```
# Distribution Groups
dev-team
qa-team
beta-testers
```

### distribution/release_note.txt
Custom release notes with variable substitution:
```
Version {{version}} - {{flavor}} Build

What's New:
- Bug fixes and improvements
- New features added

Build Date: {{date}}
```

Variables available:
- `{{version}}` - App version from pubspec.yaml
- `{{flavor}}` - Current flavor (dev/stg/prod)
- `{{date}}` - Build date and time

### distribution/test_device.txt
Test devices for automation (format: Name|ID|Platform):
```
# Test Devices
iPhone 14 Pro|00008110-001234567890001E|iOS
Pixel 7 Pro|emulator-5554|Android
```

### distribution/test_password.txt
Test account password (no comments, plain text):
```
your-test-password-here
```

⚠️ **Security Note**: Add this file to `.gitignore`!

## 🔐 Key Directory

Store security keys and certificates:
- `AuthKey_*.p8` - App Store Connect API key
- `keystore.jks` - Android keystore (if not in android/app/)
- Other security certificates

**Important**: These files should be in `.gitignore`

## 🛠️ Managing Distribution Data

### Using the Management Tool

```bash
# Initialize distribution data files
./tools/macos/distribution/manage_distribution_data.sh init

# Show all distribution data
./tools/macos/distribution/manage_distribution_data.sh show

# Add a tester
./tools/macos/distribution/manage_distribution_data.sh add-tester user@example.com

# Add a distribution group
./tools/macos/distribution/manage_distribution_data.sh add-group qa-team

# Edit a file
./tools/macos/distribution/manage_distribution_data.sh edit tester-list

# Validate all files
./tools/macos/distribution/manage_distribution_data.sh validate

# Sync to Firebase
./tools/macos/distribution/manage_distribution_data.sh sync-to-firebase --flavor dev
```

### Data Priority

When using both JSON configuration and text files:

1. **Testers**: Combines JSON config + text file (duplicates removed)
2. **Groups**: Combines JSON config + text file (duplicates removed)
3. **Release Notes**: Text file takes priority, falls back to JSON template

This allows you to:
- Keep permanent testers/groups in JSON config
- Add temporary testers/groups in text files
- Override release notes per build

## 📖 Usage in Scripts

All build and distribution scripts automatically read from both sources:

```bash
# Build with distribution
./tools/macos/build/build_apk.sh dev --distribute

# Distribution uses combined data:
# - Testers from app/firebase.json + distribution/tester_list.txt
# - Groups from app/firebase.json + distribution/tester_group.txt
# - Release notes from distribution/release_note.txt (or JSON template)
```

### Accessing in Shell Scripts

```bash
# Source common configuration
source tools/macos/common/common.sh

# Get all testers (JSON + text file)
testers=$(get_all_testers "dev")

# Get all groups (JSON + text file)
groups=$(get_all_groups "dev")

# Get release notes (text file or JSON template)
notes=$(get_all_release_notes "dev" "1.0.0")

# Get test devices
devices=$(get_test_devices_from_file)

# Get test password
password=$(get_test_password_from_file)
```

## 🔄 Migration Guide

If you have existing configuration:

### 1. JSON Configuration (Permanent Data)
Move to `.info/app/`:
```bash
mv .info/app.json .info/app/app.json
mv .info/firebase.json .info/app/firebase.json
mv .info/build.json .info/app/build.json
mv .info/paths.json .info/app/paths.json
```

### 2. Distribution Data (Temporary/Variable Data)
Create text files:
```bash
./tools/macos/distribution/manage_distribution_data.sh init
```

Then add your data:
- Testers → `distribution/tester_list.txt`
- Groups → `distribution/tester_group.txt`  
- Custom release notes → `distribution/release_note.txt`

### 3. Update Scripts
All tools are already updated to use the new structure. Just ensure:
```bash
# Test configuration reading
source tools/macos/common/common.sh
show_config_summary dev android
```

## 📋 Best Practices

### 1. JSON vs Text Files

**Use JSON (app/firebase.json) for:**
- Permanent testers and groups
- Default configurations
- Version-controlled settings

**Use Text Files (distribution/*.txt) for:**
- Temporary testers
- Build-specific release notes
- Local test configurations
- Sensitive data (with .gitignore)

### 2. Security

```gitignore
# .gitignore
.info/key/
.info/distribution/test_password.txt
```

### 3. Version Control

**Commit:**
- `app/*.json` files
- Example/template distribution files
- Documentation

**Don't Commit:**
- Actual passwords
- Private keys
- Personal tester emails (if sensitive)

### 4. Team Collaboration

1. Keep team-wide config in JSON
2. Use text files for personal testing
3. Document custom configurations
4. Validate before committing

```bash
./tools/macos/distribution/manage_distribution_data.sh validate
```

## 🔍 Troubleshooting

### Configuration Not Loading

```bash
# Check file paths
ls -la .info/app/
ls -la .info/distribution/

# Validate structure
source tools/macos/common/common.sh
validate_environment
```

### Distribution Data Not Working

```bash
# Validate files
./tools/macos/distribution/manage_distribution_data.sh validate

# Check combined data
source tools/macos/common/common.sh
echo "Testers: $(get_all_testers dev)"
echo "Groups: $(get_all_groups dev)"
```

### Keys Not Found

```bash
# Check key directory
ls -la .info/key/

# Verify paths in app.json
cat .info/app/app.json | jq '.ios.appStoreConnectAPIKeyPath'
```

## 📚 Related Documentation

- [Build Tools README](../tools/macos/build/README.md)
- [Distribution Tools README](../tools/macos/distribution/README.md)
- [Common Configuration](../tools/macos/common/common.sh)

---

For questions or issues, refer to the main project documentation.