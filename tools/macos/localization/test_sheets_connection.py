#!/usr/bin/env python3
"""
Test script to validate Google Sheets connection and show sample data.
"""

import requests
import csv
import sys
import json
from io import StringIO

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

def test_connection():
    """Test connection to Google Sheets and display sample data."""
    try:
        sheet_id = CONFIG['sheet_id']
        sheet_gids = CONFIG['sheet_gids']
        columns = CONFIG['columns']

        log_step("Testing Google Sheets connection...")
        log_info(f"Sheet ID: {sheet_id}")
        log_info(f"Sheet GIDs: {sheet_gids}")
        print()

        # Test first GID
        gid = sheet_gids[0] if sheet_gids else None
        if not gid:
            log_error("No sheet GIDs configured")
            return

        # Fetch data
        url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/export?format=csv&gid={gid}"
        response = requests.get(url)
        response.encoding = CONFIG['generation']['encoding']

        if response.status_code != 200:
            log_error(f"HTTP {response.status_code}")
            return

        log_success("Successfully connected to Google Sheets")
        print()

        # Parse CSV
        reader = csv.DictReader(StringIO(response.text))
        rows = list(reader)

        log_info(f"Total rows: {len(rows)}")
        print()

        # Show column headers
        if rows:
            log_step("Column headers:")
            for i, header in enumerate(reader.fieldnames, 1):
                print(f"  {i}. {header}")
            print()

            # Show first 5 rows
            log_step("Sample data (first 5 rows):")
            for i, row in enumerate(rows[:5], 1):
                print(f"\nRow {i}:")
                print(f"  Screen: {row.get(columns['screen'], 'N/A')}")
                print(f"  Translation key: {row.get(columns['key'], 'N/A')}")
                print(f"  Action: {row.get(columns['action'], 'N/A')}")
                print(f"  Lang: English: {row.get(columns['en'], 'N/A')}")
                print(f"  Lang: Vietnam: {row.get(columns['vi'], 'N/A')}")
                print(f"  Lang: Chinese: {row.get(columns['zh'], 'N/A')}")
        else:
            log_warning("No data found in the sheet")

    except requests.RequestException as e:
        log_error(f"Network error: {str(e)}")
        sys.exit(1)
    except Exception as e:
        log_error(f"Connection test failed: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    # Load configuration
    if len(sys.argv) < 2:
        log_error("Configuration file path required")
        log_info("Usage: python3 test_sheets_connection.py <config_file>")
        sys.exit(1)

    config_path = sys.argv[1]
    CONFIG = load_config(config_path)

    test_connection() 