#!/usr/bin/env python3
"""
Script to generate module-specific ARB files from multiple Google Sheets for Flutter localization.
Supports fetching data from multiple sheets using the same column headers from the first sheet.
"""

import json
import os
import re
import requests
import csv
import sys
from io import StringIO
from collections import defaultdict
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

def fetch_sheet_data():
    """Fetch data from multiple Google Sheets as CSV."""
    all_csv_data = []

    sheet_id = CONFIG['sheet_id']
    sheet_gids = CONFIG['sheet_gids']

    for gid in sheet_gids:
        url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/export?format=csv&gid={gid}"
        response = requests.get(url)
        response.encoding = CONFIG['generation']['encoding']
        all_csv_data.append(response.text)
        log_step(f"Fetched data from sheet GID: {gid}")

    return all_csv_data

def parse_csv_data(csv_texts):
    """Parse CSV data from multiple sheets and organize by module."""
    # Organize data by module
    modules_data = defaultdict(lambda: defaultdict(lambda: defaultdict(dict)))
    languages = set()
    headers = None
    
    for sheet_index, csv_text in enumerate(csv_texts):
        csv_file = StringIO(csv_text)
        
        if sheet_index == 0:
            # For the first sheet, read headers and data normally
            reader = csv.DictReader(csv_file)
            # Store the headers from the first sheet
            headers = reader.fieldnames
        else:
            # For subsequent sheets, use headers from the first sheet
            # Read all lines
            lines = csv_file.readlines()
            if not lines:
                continue
            
            # Skip the header line of this sheet and use headers from first sheet
            csv_file = StringIO(''.join(lines[1:]))
            reader = csv.DictReader(csv_file, fieldnames=headers)
        
        for row in reader:
            columns = CONFIG['columns']
            module = row.get(columns["screen"], "").strip()
            key = row.get(columns["key"], "").strip()
            metadata = row.get(columns["metadata"], "").strip()
            
            if not module or not key:
                continue
                
            # Normalize module name for file naming
            module_name = normalize_module_name(module)
            
            # Process each language
            for col_name, col_value in row.items():
                if col_name and col_name.startswith("Lang: "):
                    lang_name = col_name.replace("Lang: ", "").strip().lower()
                    lang_code = get_language_code(lang_name)
                    if lang_code:
                        languages.add(lang_code)
                        value = col_value.strip() if col_value else ""
                        if value:  # Only add non-empty values
                            default_lang = CONFIG['languages']['default']
                            modules_data[module_name][lang_code][key] = {
                                "value": value,
                                "metadata": metadata if lang_code == default_lang else None
                            }
    
    return modules_data, languages

def get_language_code(language_name):
    """Convert language name to locale code."""
    mapping = CONFIG['languages']['mapping']
    return mapping.get(language_name.lower())

def normalize_module_name(module):
    """Normalize module name for file naming."""
    # Remove special characters and convert to snake_case
    module = re.sub(r'[^\w\s-]', '', module)
    module = re.sub(r'[-\s]+', '_', module)
    return module.lower()

def generate_arb_content(locale, translations, is_default=False):
    """Generate ARB file content."""
    arb_data = {
        "@@locale": locale
    }
    
    if is_default:
        arb_data.update({
            "@@author": CONFIG['generation']['author'],
            "@@last_modified": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S.%fZ")
        })
    
    # Sort keys alphabetically
    sorted_keys = sorted(translations.keys())
    
    for key in sorted_keys:
        trans_data = translations[key]
        value = trans_data["value"]
        metadata = trans_data.get("metadata")
        
        # Add the translation
        arb_data[key] = value
        
        # Add metadata only for default language (English)
        if is_default and metadata:
            arb_data[f"@{key}"] = {
                "description": metadata
            }
            
            # Check for placeholders in the value
            placeholders = extract_placeholders(value)
            if placeholders:
                arb_data[f"@{key}"]["placeholders"] = create_placeholder_metadata(placeholders)
    
    return json.dumps(arb_data, ensure_ascii=False, indent=2)

def extract_placeholders(text):
    """Extract placeholders from text (e.g., {price}, {count})."""
    return re.findall(r'\{(\w+)\}', text)

def create_placeholder_metadata(placeholders):
    """Create placeholder metadata for ARB."""
    metadata = {}
    for placeholder in placeholders:
        # Determine type based on common naming patterns
        placeholder_type = "String"
        if placeholder in ["count", "quantity", "amount", "number"]:
            placeholder_type = "int"
        elif placeholder in ["price", "value", "total"]:
            placeholder_type = "double"
            
        metadata[placeholder] = {
            "type": placeholder_type
        }
    return metadata

def save_arb_file(module_name, locale, content):
    """Save ARB file to the appropriate location."""
    module_dir = CONFIG['paths']['module_dir']
    module_path = os.path.join(module_dir, module_name)
    os.makedirs(module_path, exist_ok=True)

    filename = f"{module_name}_{locale}.arb"
    filepath = os.path.join(module_path, filename)

    encoding = CONFIG['generation']['encoding']
    with open(filepath, 'w', encoding=encoding) as f:
        f.write(content)

    log_success(f"Generated: {filepath}")

def main():
    """Main function to orchestrate the ARB generation."""
    global CONFIG

    # Load configuration
    if len(sys.argv) < 2:
        log_error("Configuration file path required")
        log_info("Usage: python3 generate_arb_from_sheets.py <config_file>")
        sys.exit(1)

    config_path = sys.argv[1]
    CONFIG = load_config(config_path)

    try:
        sheet_gids = CONFIG['sheet_gids']
        log_info(f"Fetching data from {len(sheet_gids)} Google Sheets...")
        csv_data_list = fetch_sheet_data()

        log_step("Parsing CSV data from all sheets...")
        modules_data, languages = parse_csv_data(csv_data_list)

        log_info(f"Found {len(modules_data)} modules and {len(languages)} languages")
        log_info(f"Languages: {', '.join(sorted(languages))}")

        # Generate ARB files for each module and language
        default_lang = CONFIG['languages']['default']
        for module_name, module_translations in modules_data.items():
            log_step(f"Processing module: {module_name}")

            for locale in languages:
                if locale in module_translations and module_translations[locale]:
                    content = generate_arb_content(
                        locale,
                        module_translations[locale],
                        is_default=(locale == default_lang)
                    )
                    save_arb_file(module_name, locale, content)

        log_success("ARB generation completed!")

    except requests.RequestException as e:
        log_error(f"Failed to fetch data from Google Sheets: {str(e)}")
        sys.exit(1)
    except Exception as e:
        log_error(f"ARB generation failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    main() 