#!/bin/bash

# Navigate to the root directory relative to the current script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="${SCRIPT_DIR}/../../.."
cd "${ROOT_DIR}" || {
    echo "Failed to navigate to the project root directory."
    exit 1
}

# Display a colorful header
echo -e "\033[1;34m"
echo "🔍 Firebase Crashlytics Debug Symbols Checker 🔍"
echo "================================================"
echo -e "\033[0m"

# Check for parameters
if [[ -z "$1" ]]; then
    echo "Usage: $0 [dev|stg|prod] [android|ios]"
    echo "  This tool helps verify Firebase Crashlytics debug symbol configuration"
    exit 1
fi

# Validate input environment
if [[ "$1" != "dev" && "$1" != "stg" && "$1" != "prod" ]]; then
    echo -e "\033[1;31mError: Invalid environment '$1'.\033[0m"
    echo "Supported environments: dev, stg, prod"
    exit 1
fi

# Set default platform to android if not specified
PLATFORM=${2:-"android"}
if [[ "$PLATFORM" != "android" && "$PLATFORM" != "ios" ]]; then
    echo -e "\033[1;31mError: Invalid platform '$PLATFORM'.\033[0m"
    echo "Supported platforms: android, ios"
    exit 1
fi

# Set environment-specific configurations
CONFIG_FILE=""
BUNDLE_ID=""
PROJECT_ID="artlexis-4ba70"

if [[ "$PLATFORM" == "android" ]]; then
    # Android configuration
    if [[ "$1" == "dev" ]]; then
        CONFIG_FILE="android/app/src/dev/google-services.json"
        BUNDLE_ID="com.eup.artlexis.dev"
    elif [[ "$1" == "stg" ]]; then
        CONFIG_FILE="android/app/src/stg/google-services.json"
        BUNDLE_ID="com.eup.artlexis.stg"
    elif [[ "$1" == "prod" ]]; then
        CONFIG_FILE="android/app/src/prod/google-services.json"
        BUNDLE_ID="com.eup.artlexis"
    fi
else
    # iOS configuration
    if [[ "$1" == "dev" ]]; then
        CONFIG_FILE="ios/Runner/dev/GoogleService-Info.plist"
        BUNDLE_ID="com.eup.artlexis.dev"
    elif [[ "$1" == "stg" ]]; then
        CONFIG_FILE="ios/Runner/stg/GoogleService-Info.plist"
        BUNDLE_ID="com.eup.artlexis.stg"
    elif [[ "$1" == "prod" ]]; then
        CONFIG_FILE="ios/Runner/GoogleService-Info.plist"
        BUNDLE_ID="com.eup.artlexis"
    fi
fi

echo -e "\033[1;36mChecking Firebase Crashlytics configuration for:\033[0m"
echo "• Environment: $1"
echo "• Platform: $PLATFORM"
echo "• Bundle ID: $BUNDLE_ID"
echo "• Config file: $CONFIG_FILE"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "\033[1;31mError: Firebase CLI is not installed.\033[0m"
    echo "Please install it with: npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in to Firebase
if ! firebase projects:list &> /dev/null; then
    echo -e "\033[1;31mError: Not logged in to Firebase CLI.\033[0m"
    echo "Please login with: firebase login"
    exit 1
fi

# Extract Firebase App ID
echo "Extracting Firebase App ID..."
FIREBASE_APP_ID=""

if [[ "$PLATFORM" == "android" ]]; then
    # Android - Extract mobilesdk_app_id from google-services.json
    if command -v jq &> /dev/null; then
        echo "Using jq to parse JSON..."
        FIREBASE_APP_ID=$(jq -r --arg pkg "$BUNDLE_ID" '.client[] | select(.client_info.android_client_info.package_name == $pkg) | .client_info.mobilesdk_app_id' "$CONFIG_FILE")
    else
        echo "jq not found, using grep/sed method..."
        FIREBASE_APP_ID=$(grep -A 10 "\"package_name\": \"$BUNDLE_ID\"" "$CONFIG_FILE" | grep -B 10 "mobilesdk_app_id" | grep "mobilesdk_app_id" | head -1 | sed 's/.*"mobilesdk_app_id": "\([^"]*\)".*/\1/')
    fi
else
    # iOS - Extract GOOGLE_APP_ID from GoogleService-Info.plist
    if command -v plutil &> /dev/null; then
        echo "Using plutil to parse plist..."
        FIREBASE_APP_ID=$(plutil -extract "GOOGLE_APP_ID" xml1 -o - "$CONFIG_FILE" | sed -n "s/.*<string>\(.*\)<\/string>.*/\1/p")
    else
        echo "plutil not found, using grep/sed method..."
        FIREBASE_APP_ID=$(grep -A 1 "GOOGLE_APP_ID" "$CONFIG_FILE" | grep "<string>" | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    fi
fi

# Validate that we found the Firebase App ID
if [[ -z "$FIREBASE_APP_ID" ]]; then
    echo -e "\033[1;31mError: Could not extract Firebase App ID from '$CONFIG_FILE'\033[0m"
    echo "Please verify the configuration file contains the correct information."
    exit 1
fi

echo -e "\033[1;32mFound Firebase App ID: $FIREBASE_APP_ID\033[0m"
echo ""

# Check if there are debug symbols in the local directory
DEBUG_SYMBOLS_PATH=".obfuscation"
if [[ -d "$DEBUG_SYMBOLS_PATH" ]]; then
    echo -e "\033[1;32mLocal debug symbols directory found: $DEBUG_SYMBOLS_PATH\033[0m"
    
    # Count relevant files
    if [[ "$PLATFORM" == "android" ]]; then
        SYMBOL_FILES=$(find "$DEBUG_SYMBOLS_PATH" -name "*.android-*" -o -name "app.symbols" | wc -l)
    else
        SYMBOL_FILES=$(find "$DEBUG_SYMBOLS_PATH" -name "*.ios-*" -o -name "*.iOS-*" | wc -l)
    fi
    
    echo "Found $SYMBOL_FILES relevant symbol files locally"
    
    # Show some example files
    if [[ "$SYMBOL_FILES" -gt 0 ]]; then
        echo "Example files:"
        if [[ "$PLATFORM" == "android" ]]; then
            find "$DEBUG_SYMBOLS_PATH" -name "*.android-*" -o -name "app.symbols" | head -n 5
        else
            find "$DEBUG_SYMBOLS_PATH" -name "*.ios-*" -o -name "*.iOS-*" | head -n 5
        fi
    fi
else
    echo -e "\033[1;33mLocal debug symbols directory not found.\033[0m"
    echo "This is normal if you haven't built the app with obfuscation enabled yet."
    echo "To generate debug symbols, build with: --obfuscate --split-debug-info=\"$DEBUG_SYMBOLS_PATH\""
fi
echo ""

# For iOS, check the dSYM files
if [[ "$PLATFORM" == "ios" ]]; then
    echo -e "\033[1;36mChecking for iOS dSYM files...\033[0m"
    
    # Common locations for dSYM files
    DSYM_LOCATIONS=("build/ios/archive" "build/ios/ipa" "build/ios")
    FOUND_DSYMS=0
    
    for LOCATION in "${DSYM_LOCATIONS[@]}"; do
        if [[ -d "$LOCATION" ]]; then
            DSYM_COUNT=$(find "$LOCATION" -name "*.dSYM" | wc -l)
            if [[ "$DSYM_COUNT" -gt 0 ]]; then
                FOUND_DSYMS=1
                echo -e "\033[1;32mFound dSYM files in: $LOCATION\033[0m"
                echo "Example dSYM files:"
                find "$LOCATION" -name "*.dSYM" | head -n 3
            fi
        fi
    done
    
    if [[ "$FOUND_DSYMS" -eq 0 ]]; then
        echo -e "\033[1;33mNo dSYM files found in common build directories.\033[0m"
        echo "This is normal if you haven't built the iOS app yet."
        echo "To generate dSYM files, build with: flutter build ipa"
    fi
    
    # Check the upload script configuration in the Xcode project
    echo -e "\033[1;36m\nChecking Xcode project for Crashlytics build phases...\033[0m"
    CRASHLYTICS_PHASE=$(grep -A 3 "FlutterFire.*upload-crashlytics-symbols" ios/Runner.xcodeproj/project.pbxproj || echo "Not found")
    
    if [[ "$CRASHLYTICS_PHASE" == *"upload-crashlytics-symbols"* ]]; then
        echo -e "\033[1;32m✓ Crashlytics upload-crashlytics-symbols build phase is properly configured in Xcode project\033[0m"
        echo "This means debug symbols will be automatically uploaded during iOS builds"
    else
        echo -e "\033[1;31m✗ Crashlytics upload-crashlytics-symbols build phase not found in Xcode project\033[0m"
        echo "Please verify your Xcode project configuration"
    fi
fi
echo ""

# Available Firebase Crashlytics commands
echo -e "\033[1;36mAvailable Firebase Crashlytics commands:\033[0m"
firebase --help | grep -A 3 crashlytics || echo "No crashlytics commands found"
echo ""

# Display useful links and console URLs
echo -e "\033[1;36mFirebase Console Links:\033[0m"
echo "• Project Overview:"
echo "  https://console.firebase.google.com/project/$PROJECT_ID"
echo ""
echo "• Crashlytics Dashboard:"
echo "  https://console.firebase.google.com/project/$PROJECT_ID/crashlytics/issues?state=open&time=last-seven-days&tag=all"
echo ""
if [[ "$PLATFORM" == "android" ]]; then
    echo "• Android App Crashlytics:"
    echo "  https://console.firebase.google.com/project/$PROJECT_ID/crashlytics/app/android:$BUNDLE_ID"
else
    echo "• iOS App Crashlytics:"
    echo "  https://console.firebase.google.com/project/$PROJECT_ID/crashlytics/app/ios:$BUNDLE_ID"
fi
echo ""

# Open Firebase Console
echo "Would you like to open Firebase Crashlytics Console in your browser? (y/n)"
read -r OPEN_BROWSER

if [[ "$OPEN_BROWSER" == "y" || "$OPEN_BROWSER" == "Y" ]]; then
    echo "Opening Firebase Crashlytics Console..."
    open "https://console.firebase.google.com/project/$PROJECT_ID/crashlytics/issues?state=open&time=last-seven-days&tag=all"
fi

echo -e "\033[1;33m\nNOTE: Firebase CLI doesn't have a command to directly list uploaded debug symbols.\033[0m"
echo "You need to check the Firebase Console to view uploaded symbols status."
echo "Look for the 'Debug symbols' or 'Symbol files' section in the app settings."

exit 0 