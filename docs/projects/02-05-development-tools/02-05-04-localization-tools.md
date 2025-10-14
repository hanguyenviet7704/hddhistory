# Localization Tools

This document provides comprehensive information about the localization tools and workflow used in Dcore projects.

## Overview

The Dcore project uses a sophisticated localization system that integrates with Google Sheets for translation management and generates Flutter localization files automatically. The system supports multiple languages and modular translation organization.

## Primary Localization Script

### Main Generation Tool
**File**: `tools/macos/localization/generate_localization.sh`
**Purpose**: Complete localization workflow from Google Sheets to Flutter

### Usage
```bash
# Generate all localization files
sh tools/macos/localization/generate_localization.sh
```

### What It Does
1. **Python Environment Setup**: Creates virtual environment if needed
2. **Google Sheets Integration**: Downloads translations from Google Sheets
3. **ARB File Generation**: Creates module-specific ARB files
4. **ARB File Merging**: Combines modules into app-level ARB files
5. **Flutter Generation**: Runs `flutter gen-l10n` to create Dart files

## Localization Workflow

### Step-by-Step Process

#### 1. Google Sheets Integration
```python
# tools/macos/localization/generate_arb_from_sheets.py
import requests
import json
import os

def download_translations_from_sheets():
    """
    Downloads translations from Google Sheets and creates module ARB files.
    """
    sheet_url = "https://docs.google.com/spreadsheets/d/SHEET_ID/export?format=csv"
    
    # Download CSV data
    response = requests.get(sheet_url)
    csv_data = response.text
    
    # Parse and create ARB files by module
    translations = parse_csv_translations(csv_data)
    create_module_arb_files(translations)
```

#### 2. ARB File Generation
The script generates module-specific ARB files:
```
assets/arb/module/
├── auth_en.arb          # Authentication module - English
├── auth_es.arb          # Authentication module - Spanish
├── auth_fr.arb          # Authentication module - French
├── profile_en.arb       # Profile module - English
├── profile_es.arb       # Profile module - Spanish
├── profile_fr.arb       # Profile module - French
└── common_en.arb        # Common strings - English
    common_es.arb        # Common strings - Spanish
    common_fr.arb        # Common strings - French
```

#### 3. ARB File Merging
```python
# tools/macos/localization/merge_arb_files.py
def merge_module_arb_files():
    """
    Merges module-specific ARB files into app-level ARB files.
    """
    languages = ['en', 'es', 'fr']
    
    for language in languages:
        merged_translations = {}
        
        # Read all module files for this language
        module_files = glob.glob(f'assets/arb/module/*_{language}.arb')
        
        for module_file in module_files:
            with open(module_file, 'r') as f:
                module_translations = json.load(f)
                
            # Add module prefix to avoid conflicts
            module_name = os.path.basename(module_file).split('_')[0]
            for key, value in module_translations.items():
                if not key.startswith('@@'):
                    merged_key = f'{module_name}_{key}'
                    merged_translations[merged_key] = value
                else:
                    merged_translations[key] = value
        
        # Write merged file
        output_file = f'assets/arb/app/app_{language}.arb'
        with open(output_file, 'w') as f:
            json.dump(merged_translations, f, indent=2, ensure_ascii=False)
```

#### 4. Flutter Localization Generation
```bash
# Final step: Generate Flutter localization classes
flutter gen-l10n
```

## Generated File Structure

### ARB Files Organization
```
assets/arb/
├── module/                  # Module-specific translations
│   ├── auth_en.arb         # Authentication strings
│   ├── auth_es.arb
│   ├── auth_fr.arb
│   ├── profile_en.arb      # Profile strings
│   ├── profile_es.arb
│   ├── profile_fr.arb
│   ├── settings_en.arb     # Settings strings
│   ├── settings_es.arb
│   ├── settings_fr.arb
│   └── common_en.arb       # Common/shared strings
│       common_es.arb
│       common_fr.arb
└── app/                     # App-level merged translations
    ├── app_en.arb          # Merged English translations
    ├── app_es.arb          # Merged Spanish translations
    └── app_fr.arb          # Merged French translations
```

### Generated Flutter Files
```
lib/config/l10n/
├── app_localizations.dart          # Base localization class
├── app_localizations_en.dart       # English implementation
├── app_localizations_es.dart       # Spanish implementation
└── app_localizations_fr.dart       # French implementation
```

## ARB File Format

### Module ARB File Example
```json
// assets/arb/module/auth_en.arb
{
  "@@locale": "en",
  "@@context": "Authentication module",
  "loginTitle": "Login",
  "@loginTitle": {
    "description": "Title shown on the login screen"
  },
  "loginButton": "Sign In",
  "@loginButton": {
    "description": "Text on the login button"
  },
  "emailLabel": "Email Address",
  "@emailLabel": {
    "description": "Label for email input field"
  },
  "passwordLabel": "Password",
  "@passwordLabel": {
    "description": "Label for password input field"
  },
  "welcomeMessage": "Welcome back, {name}!",
  "@welcomeMessage": {
    "description": "Welcome message with user's name",
    "placeholders": {
      "name": {
        "type": "String",
        "example": "John"
      }
    }
  },
  "loginAttempts": "You have {count, plural, =0{no attempts} =1{one attempt} other{# attempts}} remaining",
  "@loginAttempts": {
    "description": "Remaining login attempts with pluralization",
    "placeholders": {
      "count": {
        "type": "int",
        "example": "3"
      }
    }
  }
}
```

### App-Level ARB File Example
```json
// assets/arb/app/app_en.arb
{
  "@@locale": "en",
  "@@last_modified": "2024-01-15T10:30:00Z",
  
  // Authentication module (with prefix)
  "auth_loginTitle": "Login",
  "@auth_loginTitle": {
    "description": "Title shown on the login screen"
  },
  "auth_loginButton": "Sign In",
  "auth_emailLabel": "Email Address",
  "auth_passwordLabel": "Password",
  "auth_welcomeMessage": "Welcome back, {name}!",
  "@auth_welcomeMessage": {
    "placeholders": {
      "name": {
        "type": "String"
      }
    }
  },
  
  // Profile module (with prefix)
  "profile_title": "Profile",
  "profile_editButton": "Edit Profile",
  "profile_saveButton": "Save Changes",
  
  // Common strings (with prefix)
  "common_ok": "OK",
  "common_cancel": "Cancel",
  "common_loading": "Loading...",
  "common_error": "Something went wrong"
}
```

## Python Script Details

### Virtual Environment Setup
```bash
# The script automatically creates and manages Python virtual environment
VENV_DIR="$PROJECT_ROOT/.venv_localization"

if [ ! -d "$VENV_DIR" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

# Activate virtual environment
source "$VENV_DIR/bin/activate"

# Install required packages
pip install requests
```

### Google Sheets Integration Script
```python
# tools/macos/localization/generate_arb_from_sheets.py
#!/usr/bin/env python3
import requests
import json
import csv
import os
from typing import Dict, List

class GoogleSheetsTranslationDownloader:
    def __init__(self, sheet_id: str, sheet_name: str = "Sheet1"):
        self.sheet_id = sheet_id
        self.sheet_name = sheet_name
        self.base_url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/gviz/tq"
        
    def download_translations(self) -> Dict[str, Dict[str, str]]:
        """Download translations from Google Sheets."""
        try:
            params = {
                'tqx': 'out:csv',
                'sheet': self.sheet_name
            }
            
            response = requests.get(self.base_url, params=params)
            response.raise_for_status()
            
            return self._parse_csv_data(response.text)
        except Exception as e:
            print(f"Error downloading translations: {e}")
            return {}
    
    def _parse_csv_data(self, csv_data: str) -> Dict[str, Dict[str, str]]:
        """Parse CSV data into translation dictionaries."""
        translations = {}
        reader = csv.DictReader(csv_data.splitlines())
        
        for row in reader:
            module = row.get('Module', 'common')
            key = row.get('Key', '')
            description = row.get('Description', '')
            
            if not key:
                continue
                
            for lang in ['en', 'es', 'fr']:
                if lang not in translations:
                    translations[lang] = {}
                if module not in translations[lang]:
                    translations[lang][module] = {}
                
                value = row.get(lang.upper(), '')
                if value:
                    translations[lang][module][key] = value
                    if description:
                        translations[lang][module][f"@{key}"] = {
                            "description": description
                        }
        
        return translations
    
    def create_arb_files(self, translations: Dict[str, Dict[str, str]]):
        """Create ARB files from translations."""
        os.makedirs('assets/arb/module', exist_ok=True)
        
        for language, modules in translations.items():
            for module, strings in modules.items():
                arb_data = {
                    "@@locale": language,
                    "@@context": f"{module.title()} module translations"
                }
                arb_data.update(strings)
                
                filename = f'assets/arb/module/{module}_{language}.arb'
                with open(filename, 'w', encoding='utf-8') as f:
                    json.dump(arb_data, f, indent=2, ensure_ascii=False, sort_keys=True)
                
                print(f"Generated: {filename}")

# Usage
if __name__ == "__main__":
    # Replace with your Google Sheets ID
    SHEET_ID = "your-google-sheets-id-here"
    
    downloader = GoogleSheetsTranslationDownloader(SHEET_ID)
    translations = downloader.download_translations()
    downloader.create_arb_files(translations)
```

### ARB Merging Script
```python
# tools/macos/localization/merge_arb_files.py
#!/usr/bin/env python3
import json
import glob
import os
from datetime import datetime
from typing import Dict, Any

class ARBFileMerger:
    def __init__(self, module_dir: str = 'assets/arb/module', output_dir: str = 'assets/arb/app'):
        self.module_dir = module_dir
        self.output_dir = output_dir
        
    def merge_all_languages(self):
        """Merge ARB files for all detected languages."""
        languages = self._detect_languages()
        
        for language in languages:
            self.merge_language(language)
    
    def _detect_languages(self) -> List[str]:
        """Detect available languages from module files."""
        languages = set()
        pattern = os.path.join(self.module_dir, '*_*.arb')
        
        for filepath in glob.glob(pattern):
            filename = os.path.basename(filepath)
            language = filename.split('_')[-1].replace('.arb', '')
            languages.add(language)
            
        return sorted(languages)
    
    def merge_language(self, language: str):
        """Merge all module files for a specific language."""
        merged_data = {
            "@@locale": language,
            "@@last_modified": datetime.now().isoformat()
        }
        
        pattern = os.path.join(self.module_dir, f'*_{language}.arb')
        module_files = sorted(glob.glob(pattern))
        
        for module_file in module_files:
            module_name = self._extract_module_name(module_file)
            module_data = self._load_arb_file(module_file)
            
            # Add module-prefixed keys
            for key, value in module_data.items():
                if key.startswith('@@'):
                    continue  # Skip metadata
                
                prefixed_key = f"{module_name}_{key}"
                merged_data[prefixed_key] = value
        
        # Save merged file
        os.makedirs(self.output_dir, exist_ok=True)
        output_file = os.path.join(self.output_dir, f'app_{language}.arb')
        
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(merged_data, f, indent=2, ensure_ascii=False, sort_keys=True)
        
        print(f"Merged {len(module_files)} modules into {output_file}")
    
    def _extract_module_name(self, filepath: str) -> str:
        """Extract module name from file path."""
        filename = os.path.basename(filepath)
        return filename.split('_')[0]
    
    def _load_arb_file(self, filepath: str) -> Dict[str, Any]:
        """Load ARB file content."""
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                return json.load(f)
        except Exception as e:
            print(f"Error loading {filepath}: {e}")
            return {}

# Usage
if __name__ == "__main__":
    merger = ARBFileMerger()
    merger.merge_all_languages()
```

## Using Generated Localizations

### In Flutter Code
```dart
// Access localizations in widgets
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.auth_loginTitle),
      ),
      body: Column(
        children: [
          Text(l10n.auth_welcomeMessage('John')),
          TextField(
            decoration: InputDecoration(
              labelText: l10n.auth_emailLabel,
            ),
          ),
          TextField(
            decoration: InputDecoration(
              labelText: l10n.auth_passwordLabel,
            ),
            obscureText: true,
          ),
          ElevatedButton(
            onPressed: () => _handleLogin(),
            child: Text(l10n.auth_loginButton),
          ),
        ],
      ),
    );
  }
}
```

### Extension for Easier Access
```dart
// lib/core/extensions/context_extensions.dart
extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

// Usage
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(context.l10n.common_loading);
  }
}
```

## Configuration

### Flutter Localization Configuration
```yaml
# pubspec.yaml
flutter:
  generate: true

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any
```

### l10n.yaml Configuration
```yaml
# l10n.yaml
arb-dir: assets/arb/app
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/config/l10n
preferred-supported-locales: ["en"]
```

## Development Workflow

### Adding New Translations
1. **Update Google Sheets**: Add new keys and translations
2. **Run Generation Script**: `sh tools/macos/localization/generate_localization.sh`
3. **Verify Generated Files**: Check ARB and Dart files
4. **Test in App**: Use new translation keys in Flutter code

### Adding New Languages
1. **Add Language Column**: In Google Sheets
2. **Update Scripts**: Modify language detection in Python scripts
3. **Regenerate Files**: Run localization generation
4. **Update App Configuration**: Add to supported locales

### Modular Organization
- **Module-based**: Organize translations by feature/module
- **Namespace Prevention**: Automatic prefixing prevents conflicts
- **Maintainability**: Easier to manage translations per feature team

## Troubleshooting

### Common Issues

#### Python Environment Issues
```bash
# Reset virtual environment
rm -rf .venv_localization
sh tools/macos/localization/generate_localization.sh
```

#### Google Sheets Access Issues
```bash
# Check URL accessibility
curl "https://docs.google.com/spreadsheets/d/YOUR_SHEET_ID/export?format=csv"
```

#### ARB File Format Issues
```bash
# Validate JSON format
python -m json.tool assets/arb/app/app_en.arb
```

#### Flutter Generation Issues
```bash
# Manual flutter generation
flutter gen-l10n
```

### Debug Commands
```bash
# Check Python dependencies
source .venv_localization/bin/activate
pip list

# Validate ARB files
find assets/arb -name "*.arb" -exec python -m json.tool {} \;

# Check generated Dart files
ls -la lib/config/l10n/
```

## Best Practices

### Translation Management
- Use descriptive keys with context
- Provide descriptions for all translatable strings
- Organize by logical modules/features
- Include placeholders documentation

### Workflow Efficiency
- Run localization generation after translation updates
- Test with different locales during development
- Use CI/CD integration for automatic generation
- Version control all generated files

### Quality Assurance
- Review translations before release
- Test with long translations (German, etc.)
- Verify pluralization rules
- Test right-to-left languages if supported

### Performance
- Load only needed locales
- Use efficient string interpolation
- Cache localization instances where appropriate
- Monitor app size impact of multiple locales