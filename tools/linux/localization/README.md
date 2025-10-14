# Flutter Localization Scripts

This directory contains scripts for managing Flutter localization files from Google Sheets.

## Overview

The localization system works in two stages:
1. **Generate module-specific ARB files** from Google Sheets data
2. **Merge module ARB files** into combined app ARB files for Flutter

## Scripts

### `generate_localization.sh`
Main script that orchestrates the entire localization generation process.

```bash
./tool/linux/localization/generate_localization.sh
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
- Sheet GID: `1063111315`

**Column mappings:**
- `Screen` → Module name
- `Translation key` → ARB key
- `Action` → Description/metadata (English only)
- `Lang: English` → English translations
- `Lang: Vietnam` → Vietnamese translations
- `Lang: Chinese` → Chinese translations

### `merge_arb_files.py`
Python script that merges all module ARB files into combined app ARB files.

### `cleanup_old_arb.sh`
Utility script to remove old ARB files after migration to the module-based structure.

## Directory Structure

```
assets/arb/
├── module/                    # Module-specific ARB files
│   ├── home/
│   │   ├── home_en.arb
│   │   ├── home_vi.arb
│   │   └── home_zh.arb
│   ├── profile/
│   │   ├── profile_en.arb
│   │   ├── profile_vi.arb
│   │   └── profile_zh.arb
│   └── ...
└── app/                       # Combined app ARB files
    ├── app_en.arb
    ├── app_vi.arb
    └── app_zh.arb
```

## Requirements

- Python 3.x
- `requests` Python package (will be auto-installed if missing)
- Flutter SDK

## Usage

1. **Update Google Sheets** with new translations
2. **Run the generation script**:
   ```bash
   cd /path/to/project
   ./tool/linux/localization/generate_localization.sh
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

### Character Encoding Issues
The scripts use UTF-8 encoding to properly handle Vietnamese and other non-ASCII characters.

### Missing Translations
Empty cells in Google Sheets are skipped. Only non-empty values are included in ARB files.

### Placeholder Handling
The script automatically detects placeholders (e.g., `{price}`, `{count}`) and generates appropriate metadata with type inference.

## Notes

- Metadata (descriptions) are only included in English ARB files
- The scripts preserve the ARB file structure compatible with Flutter's localization system
- All generated files use UTF-8 encoding 