# Distribution Data Files Guide

Quick reference for using distribution data files with Firebase App Distribution.

## 🎯 Quick Start

### 1. Initialize Data Files
```bash
./tools/macos/distribution/manage_distribution_data.sh init
```

### 2. Add Your Data

**Add Testers:**
```bash
# Method 1: Using command
./tools/macos/distribution/manage_distribution_data.sh add-tester user@example.com

# Method 2: Edit file directly
./tools/macos/distribution/manage_distribution_data.sh edit tester-list
```

**Add Groups:**
```bash
# Method 1: Using command
./tools/macos/distribution/manage_distribution_data.sh add-group qa-team

# Method 2: Edit file directly
./tools/macos/distribution/manage_distribution_data.sh edit tester-group
```

**Custom Release Notes:**
```bash
./tools/macos/distribution/manage_distribution_data.sh edit release-note
```

### 3. Validate
```bash
./tools/macos/distribution/manage_distribution_data.sh validate
```

### 4. Distribute
```bash
# Build and distribute with combined data
./tools/macos/build/build_apk.sh dev --distribute
```

## 📁 File Formats

### tester_list.txt
One email per line, comments with `#`:
```
# Dev Team
dev1@company.com
dev2@company.com

# QA Team
qa@company.com
```

### tester_group.txt
One group per line:
```
dev-team
qa-team
beta-testers
```

### release_note.txt
Markdown with variables:
```
Version {{version}} - {{flavor}}

Changes:
- New feature X
- Bug fix Y

Released: {{date}}
```

### test_device.txt
Format: `Name|DeviceID|Platform`
```
iPhone 14 Pro|00008110-001234567890001E|iOS
Pixel 7|emulator-5554|Android
```

### test_password.txt
Plain text password (add to `.gitignore`):
```
your-test-password
```

## 🔄 How It Works

### Data Combination

**Testers & Groups:**
1. Reads from `app/firebase.json` (permanent config)
2. Reads from `distribution/*.txt` (temporary/local)
3. Combines and removes duplicates
4. Uses in distribution

**Release Notes:**
1. Checks `distribution/release_note.txt` first
2. Falls back to `app/firebase.json` template
3. Replaces variables ({{version}}, {{flavor}}, {{date}})

### Priority

```
Text File Data + JSON Config = Final Distribution List
```

**Example:**
- JSON has: `["dev@company.com", "qa@company.com"]`
- Text file has: `temp-tester@company.com`
- Result: `["dev@company.com", "qa@company.com", "temp-tester@company.com"]`

## 💡 Use Cases

### 1. Temporary Tester
Add a tester for one build without modifying JSON:
```bash
echo "temp-tester@example.com" >> .info/distribution/tester_list.txt
./tools/macos/build/build_apk.sh dev --distribute
```

### 2. Custom Release Notes Per Build
```bash
cat > .info/distribution/release_note.txt <<EOF
Hotfix Build {{version}}

Critical Fixes:
- Fixed crash on startup
- Fixed payment issue

Build: {{date}}
EOF

./tools/macos/build/build_apk.sh prod --distribute
```

### 3. Local Testing Configuration
```bash
# Add your test devices (not in version control)
echo "My iPhone|device-id|iOS" >> .info/distribution/test_device.txt

# Set test password (not in version control)
echo "test123" > .info/distribution/test_password.txt

# Use in automated testing
devices=$(get_test_devices_from_file)
password=$(get_test_password_from_file)
```

### 4. Sync Groups to Firebase
```bash
# Edit groups
./tools/macos/distribution/manage_distribution_data.sh edit tester-group

# Sync to Firebase
./tools/macos/distribution/manage_distribution_data.sh sync-to-firebase --flavor dev
```

## 🛠️ Commands Reference

### Management Commands

| Command | Description |
|---------|-------------|
| `init` | Initialize all data files with templates |
| `show [file]` | Display file contents |
| `edit <file>` | Edit a specific file |
| `validate` | Validate all files |
| `add-tester <email>` | Add tester to list |
| `add-group <name>` | Add group to list |
| `add-device <info>` | Add test device |
| `set-password` | Set test password interactively |
| `set-release-note` | Set release notes from stdin |
| `sync-to-firebase --flavor <f>` | Sync data to Firebase |

### File Types

| File Type | File |
|-----------|------|
| `tester-list` | tester_list.txt |
| `tester-group` | tester_group.txt |
| `release-note` | release_note.txt |
| `test-device` | test_device.txt |
| `test-password` | test_password.txt |

## 📖 Integration Examples

### Shell Script Integration

```bash
#!/bin/bash

# Source common config
source tools/macos/common/common.sh

# Get combined testers
all_testers=$(get_all_testers "dev")
echo "Distributing to: $all_testers"

# Get combined groups
all_groups=$(get_all_groups "dev")
echo "Groups: $all_groups"

# Get release notes (text file or template)
notes=$(get_all_release_notes "dev" "1.0.0")
echo "Release notes: $notes"

# Get test configuration
devices=$(get_test_devices_from_file)
password=$(get_test_password_from_file)
```

### Distribution Flow

```bash
# 1. Update release notes for this build
cat > .info/distribution/release_note.txt <<EOF
Version {{version}} - Hotfix Release

Critical Fixes:
- Database migration issue
- Memory leak in image cache

Build: {{date}}
EOF

# 2. Add temporary beta tester
echo "beta-user@example.com" >> .info/distribution/tester_list.txt

# 3. Build and distribute
./tools/macos/build/build_apk.sh prod --distribute

# 4. Clean up temporary data
> .info/distribution/tester_list.txt
> .info/distribution/release_note.txt
```

### CI/CD Integration

```yaml
# GitHub Actions example
- name: Setup Distribution Data
  run: |
    # Initialize files
    ./tools/macos/distribution/manage_distribution_data.sh init
    
    # Add CI-specific testers
    echo "${{ secrets.CI_TESTER_EMAILS }}" >> .info/distribution/tester_list.txt
    
    # Set release notes from git log
    git log --oneline -5 > .info/distribution/release_note.txt

- name: Build and Distribute
  run: |
    ./tools/macos/build/build_apk.sh ${{ matrix.flavor }} --distribute
```

## ⚠️ Important Notes

### Security

1. **Never commit passwords:**
   ```gitignore
   .info/distribution/test_password.txt
   ```

2. **Sensitive tester emails:**
   - Use JSON for public/team emails
   - Use text files for sensitive/temporary emails
   - Add to `.gitignore` if needed

### Data Persistence

- **Text files** are local and build-specific
- **JSON config** is version-controlled and permanent
- Text files override/extend JSON config

### Validation

Always validate before distribution:
```bash
./tools/macos/distribution/manage_distribution_data.sh validate
```

## 🔍 Troubleshooting

### Testers Not Receiving Invites

```bash
# Check combined list
source tools/macos/common/common.sh
get_all_testers "dev"

# Validate email formats
./tools/macos/distribution/manage_distribution_data.sh validate
```

### Release Notes Not Showing

```bash
# Check if text file exists and has content
cat .info/distribution/release_note.txt

# Show processed notes
source tools/macos/common/common.sh
get_all_release_notes "dev" "1.0.0"
```

### Groups Not Syncing

```bash
# List configured groups
./tools/macos/distribution/manage_distribution_data.sh show tester-group

# Sync to Firebase
./tools/macos/distribution/manage_distribution_data.sh sync-to-firebase --flavor dev

# Verify in Firebase
firebase appdistribution:groups:list --project <project-id>
```

## 📚 Related Documentation

- [Main Distribution README](README.md)
- [.info Directory Guide](../../../.info/README.md)
- [Build Tools Documentation](../build/README.md)

---

**Quick Help:**
```bash
./tools/macos/distribution/manage_distribution_data.sh --help
```