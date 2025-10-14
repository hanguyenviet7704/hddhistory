# Flutter Localization Scripts (Windows)

This directory contains Windows batch and Python scripts for managing Flutter localization files from Google Sheets.

## Overview

The localization system works in two stages:
1. **Generate module-specific ARB files** from Google Sheets data
2. **Merge module ARB files** into combined app ARB files for Flutter

## Scripts

### `generate_localization.bat`
Main Windows batch script that orchestrates the entire localization generation process.

```cmd
.\tools\windows\localization\generate_localization.bat
```

This script:
1. Fetches data from Google Sheets
2. Generates module-specific ARB files
3. Merges them into app ARB files
4. Runs Flutter's localization generation

### `generate_arb_from_sheets.py`
Python script that reads Google Sheets data and generates module-specific ARB files.

**Configuration:**
- Google Sheets ID: `1AvcLhnoNk1ARxk68a53tHOidPPq-sIBYk7ov_UcUeVs`
- Sheet GIDs: `["1935022875"]` (supports multiple sheets)

**Column mappings:**
- `Screen` → Module name
- `Translation key` → ARB key
- `Action` → Description/metadata (English only)
- `Lang: English` → English translations
- `Lang: Vietnam` → Vietnamese translations
- `Lang: Chinese` → Chinese translations

### `merge_arb_files.py`
Python script that merges all module ARB files into combined app ARB files.

### `cleanup_old_arb.bat`
Windows batch utility script to remove old ARB files after migration to the module-based structure.

### `test_sheets_connection.py`
Python script to test the connection to Google Sheets and display sample data.

## Directory Structure

```
assets\arb\
├── module\                    # Module-specific ARB files
│   ├── home\
│   │   ├── home_en.arb
│   │   ├── home_vi.arb
│   │   └── home_zh.arb
│   ├── profile\
│   │   ├── profile_en.arb
│   │   ├── profile_vi.arb
│   │   └── profile_zh.arb
│   └── ...
└── app\                       # Combined app ARB files
    ├── app_en.arb
    ├── app_vi.arb
    └── app_zh.arb
```

## Requirements

- Python 3.x (installable from [python.org](https://python.org))
- `requests` Python package (will be auto-installed if missing)
- Flutter SDK

### Installing Python on Windows:
1. Download Python from [python.org](https://python.org/downloads/)
2. During installation, make sure to check "Add Python to PATH"
3. Verify installation by opening Command Prompt and running:
   ```cmd
   python --version
   ```

## Usage

1. **Update Google Sheets** with new translations
2. **Run the generation script**:
   ```cmd
   cd \path\to\project
   .\tools\windows\localization\generate_localization.bat
   ```
3. **Commit the changes** to version control

## Adding New Languages

To add a new language:
1. Add a new column in Google Sheets with format: `Lang: <Language Name>`
2. Update the language mapping in `generate_arb_from_sheets.py` if needed
3. Run the generation script

## Module Naming

Module names are normalized for file naming:
- Special characters are removed
- Spaces and hyphens are converted to underscores
- Names are converted to lowercase

Example: `User Profile` → `user_profile`

## Troubleshooting

### Python Not Found
If you get "Python is not recognized as an internal or external command":
1. Make sure Python is installed
2. Add Python to your system PATH environment variable
3. Restart Command Prompt

### Character Encoding Issues
The scripts use UTF-8 encoding to properly handle Vietnamese and other non-ASCII characters.

### Missing Translations
Empty cells in Google Sheets are skipped. Only non-empty values are included in ARB files.

### Placeholder Handling
The script automatically detects placeholders (e.g., `{price}`, `{count}`) and generates appropriate metadata with type inference.

### Permission Issues
If you encounter permission issues, try running Command Prompt as Administrator.

## Windows-Specific Notes

- Scripts use Windows batch files (.bat) instead of shell scripts (.sh)
- Path separators use backslashes (\) instead of forward slashes (/)
- Color output may vary depending on your Command Prompt or PowerShell configuration
- The scripts include `pause` statements to keep the window open after completion

## Notes

- Metadata (descriptions) are only included in English ARB files
- The scripts preserve the ARB file structure compatible with Flutter's localization system
- All generated files use UTF-8 encoding 