#!/usr/bin/env python3
"""
Script to merge all module ARB files into combined app ARB files.
"""

import json
import os
import glob
import sys
from datetime import datetime, timezone

# ANSI color codes for consistent logging
class Colors:
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    BLUE = '\033[0;34m'
    PURPLE = '\033[0;35m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'  # No Color

def log_info(message):
    print(f"{Colors.BLUE}ℹ️  {message}{Colors.NC}")

def log_success(message):
    print(f"{Colors.GREEN}✅ {message}{Colors.NC}")

def log_warning(message):
    print(f"{Colors.YELLOW}⚠️  {message}{Colors.NC}")

def log_error(message):
    print(f"{Colors.RED}❌ {message}{Colors.NC}")

def log_step(message):
    print(f"{Colors.PURPLE}🔸 {message}{Colors.NC}")

def load_config(config_path):
    """Load configuration from JSON file."""
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        log_error(f"Failed to load configuration: {str(e)}")
        sys.exit(1)

# Global configuration - will be loaded from config file
CONFIG = None

def find_all_locales():
    """Find all available locales from module ARB files."""
    locales = set()

    module_dir = CONFIG['paths']['module_dir']
    # Search for all ARB files in module subdirectories
    pattern = os.path.join(module_dir, "*", "*.arb")
    for filepath in glob.glob(pattern):
        filename = os.path.basename(filepath)
        # Extract locale from filename (e.g., "module_en.arb" -> "en")
        parts = filename.rsplit('_', 1)
        if len(parts) == 2:
            locale = parts[1].replace('.arb', '')
            locales.add(locale)

    return sorted(locales)

def load_arb_file(filepath):
    """Load and parse an ARB file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        log_error(f"Error loading {filepath}: {e}")
        return {}

def merge_module_files(locale):
    """Merge all module ARB files for a specific locale."""
    merged_data = {
        "@@locale": locale
    }

    default_lang = CONFIG['languages']['default']
    # Add metadata only for default locale
    if locale == default_lang:
        merged_data.update({
            "@@author": CONFIG['generation']['author'],
            "@@context": "Merged from all modules",
            "@@comment": "This file is generated from module ARB files - DCore",
            "@@last_modified": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ"),
            "@@x-template": "lib/config/l10n/app_en.arb"
        })
    
    # Find all module directories
    module_dir = CONFIG['paths']['module_dir']
    module_dirs = [d for d in os.listdir(module_dir)
                   if os.path.isdir(os.path.join(module_dir, d))]

    # Process each module
    all_keys = []
    for module_name in sorted(module_dirs):
        module_file = os.path.join(module_dir, module_name, f"{module_name}_{locale}.arb")
        
        if os.path.exists(module_file):
            print(f"  - Merging {module_name}_{locale}.arb")
            module_data = load_arb_file(module_file)
            
            # Copy all entries except locale metadata
            for key, value in module_data.items():
                if not key.startswith("@@"):
                    merged_data[key] = value
                    if not key.startswith("@"):
                        all_keys.append(key)
    
    # Sort all translation keys alphabetically
    sorted_data = {
        "@@locale": merged_data["@@locale"]
    }
    
    # Add other metadata for default language
    default_lang = CONFIG['languages']['default']
    if locale == default_lang:
        for key in ["@@author", "@@context", "@@comment", "@@last_modified", "@@x-template"]:
            if key in merged_data:
                sorted_data[key] = merged_data[key]
    
    # Add all translations and their metadata in alphabetical order
    for key in sorted(all_keys):
        sorted_data[key] = merged_data[key]
        # Add metadata if it exists
        metadata_key = f"@{key}"
        if metadata_key in merged_data:
            sorted_data[metadata_key] = merged_data[metadata_key]
    
    return sorted_data

def save_app_arb(locale, content):
    """Save the merged ARB content to app directory."""
    app_dir = CONFIG['paths']['app_dir']
    os.makedirs(app_dir, exist_ok=True)

    filename = f"app_{locale}.arb"
    filepath = os.path.join(app_dir, filename)

    # Save with proper formatting
    encoding = CONFIG['generation']['encoding']
    with open(filepath, 'w', encoding=encoding) as f:
        json.dump(content, f, ensure_ascii=False, indent=2)
        f.write('\n')  # Add newline at end of file

    log_success(f"Generated: {filepath}")
    return filepath

def count_translations(arb_data):
    """Count the number of translations in ARB data."""
    return sum(1 for key in arb_data.keys() 
               if not key.startswith("@") and not key.startswith("@@"))

def main():
    """Main function to merge all module ARB files."""
    global CONFIG

    # Load configuration
    if len(sys.argv) < 2:
        log_error("Configuration file path required")
        log_info("Usage: python3 merge_arb_files.py <config_file>")
        sys.exit(1)

    config_path = sys.argv[1]
    CONFIG = load_config(config_path)

    try:
        log_step("Starting ARB file merging...")

        # Find all available locales
        locales = find_all_locales()

        if not locales:
            log_warning("No module ARB files found!")
            return

        log_info(f"Found locales: {', '.join(locales)}")
        print()

        # Process each locale
        for locale in locales:
            log_step(f"Processing locale: {locale}")
            merged_data = merge_module_files(locale)

            if len(merged_data) > 1:  # More than just @@locale
                filepath = save_app_arb(locale, merged_data)
                count = count_translations(merged_data)
                log_info(f"Total translations: {count}")
            else:
                log_warning(f"No translations found for {locale}")

            print()

        log_success("ARB merging completed!")

    except Exception as e:
        log_error(f"ARB merging failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 