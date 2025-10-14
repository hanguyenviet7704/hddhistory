#!/bin/bash

# Enable strict error handling
set -e

# Define directory structure with clean paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ROOT_DIR="$(cd "${TOOLS_DIR}/.." && pwd)"

# Use clean path references
MACOS_TOOLS_DIR="${TOOLS_DIR}/macos"
DISTRIBUTION_DIR="${MACOS_TOOLS_DIR}/distribution"
FIREBASE_INFO_FILE="${ROOT_DIR}/.info/firebase_info.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print colored output
print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

# Function to prompt for input with default value
prompt_input() {
    local prompt="$1"
    local default="$2"
    local response
    
    if [[ -n "$default" ]]; then
        read -p "$prompt [$default]: " response
        echo "${response:-$default}"
    else
        read -p "$prompt: " response
        echo "$response"
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if Firebase CLI is installed
    if ! command -v firebase &> /dev/null; then
        print_error "Firebase CLI is not installed. Please install it first:"
        echo "npm install -g firebase-tools"
        exit 1
    fi
    
    # Check if jq is installed for JSON parsing
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed. Please install it first:"
        echo "brew install jq"
        exit 1
    fi
    
    print_success "All prerequisites are met!"
}

# Function to login to Firebase
firebase_login() {
    print_info "Checking Firebase authentication..."
    
    if ! firebase projects:list > /dev/null 2>&1; then
        print_info "Please login to Firebase..."
        firebase login
    else
        print_success "Already logged in to Firebase!"
    fi
}

# Function to list Firebase projects
list_firebase_projects() {
    print_info "Available Firebase projects:"
    firebase projects:list
}

# Function to get Firebase project info
get_project_info() {
    local project_id="$1"
    
    print_info "Getting project information for: $project_id"
    
    # Validate project exists
    if ! firebase projects:list | grep -q "$project_id"; then
        print_error "Project '$project_id' not found in your Firebase account"
        return 1
    fi
    
    # Set current project
    firebase use "$project_id" > /dev/null 2>&1
    
    print_success "Project '$project_id' selected successfully!"
}

# Function to get Firebase apps for the project
get_firebase_apps() {
    local project_id="$1"
    
    print_info "Getting Firebase apps for project: $project_id"
    
    # Get Android apps
    print_info "Android apps:"
    firebase apps:list ANDROID --project "$project_id" 2>/dev/null || print_warning "No Android apps found or unable to fetch"
    
    echo ""
    
    # Get iOS apps
    print_info "iOS apps:"
    firebase apps:list IOS --project "$project_id" 2>/dev/null || print_warning "No iOS apps found or unable to fetch"
}

# Function to setup interactive configuration
setup_interactive() {
    echo ""
    print_info "🔥 Firebase App Distribution Setup"
    echo "This script will help you configure Firebase App Distribution for your Flutter project."
    echo ""
    
    # Check prerequisites
    check_prerequisites
    
    # Firebase login
    firebase_login
    
    # List projects
    list_firebase_projects
    echo ""
    
    # Get project ID
    PROJECT_ID=$(prompt_input "Enter your Firebase Project ID")
    
    if [[ -z "$PROJECT_ID" ]]; then
        print_error "Project ID is required!"
        exit 1
    fi
    
    # Validate and get project info
    get_project_info "$PROJECT_ID"
    
    # Show available apps
    get_firebase_apps "$PROJECT_ID"
    echo ""
    
    print_info "Please provide the App IDs for each platform and flavor:"
    print_warning "You can find these in Firebase Console > Project Settings > Apps"
    echo ""
    
    # Android App IDs
    print_info "📱 Android App Configuration:"
    ANDROID_DEV_APP_ID=$(prompt_input "Android Dev App ID (1:xxxxx:android:xxxxx)")
    ANDROID_DEV_PACKAGE=$(prompt_input "Android Dev Package Name" "com.yourcompany.artlexis.dev")
    
    ANDROID_STG_APP_ID=$(prompt_input "Android Staging App ID (1:xxxxx:android:xxxxx)")
    ANDROID_STG_PACKAGE=$(prompt_input "Android Staging Package Name" "com.yourcompany.artlexis.stg")
    
    ANDROID_PROD_APP_ID=$(prompt_input "Android Production App ID (1:xxxxx:android:xxxxx)")
    ANDROID_PROD_PACKAGE=$(prompt_input "Android Production Package Name" "com.yourcompany.artlexis")
    
    echo ""
    
    # iOS App IDs
    print_info "🍎 iOS App Configuration:")
    IOS_DEV_APP_ID=$(prompt_input "iOS Dev App ID (1:xxxxx:ios:xxxxx)")
    IOS_DEV_BUNDLE=$(prompt_input "iOS Dev Bundle ID" "com.yourcompany.artlexis.dev")
    
    IOS_STG_APP_ID=$(prompt_input "iOS Staging App ID (1:xxxxx:ios:xxxxx)")
    IOS_STG_BUNDLE=$(prompt_input "iOS Staging Bundle ID" "com.yourcompany.artlexis.stg")
    
    IOS_PROD_APP_ID=$(prompt_input "iOS Production App ID (1:xxxxx:ios:xxxxx)")
    IOS_PROD_BUNDLE=$(prompt_input "iOS Production Bundle ID" "com.yourcompany.artlexis")
    
    echo ""
    
    # Testers configuration
    print_info "👥 Testers Configuration:")
    print_info "Enter email addresses separated by commas (optional):"
    
    DEV_TESTERS=$(prompt_input "Dev Environment Testers" "dev-team@yourcompany.com,qa-team@yourcompany.com")
    STG_TESTERS=$(prompt_input "Staging Environment Testers" "staging-testers@yourcompany.com,stakeholders@yourcompany.com")
    PROD_TESTERS=$(prompt_input "Production Environment Testers" "beta-testers@yourcompany.com")
    
    echo ""
    
    # Groups configuration
    print_info "👥 Groups Configuration:")
    print_info "Enter group names separated by commas (optional):"
    
    DEV_GROUPS=$(prompt_input "Dev Environment Groups" "dev-team,qa-team")
    STG_GROUPS=$(prompt_input "Staging Environment Groups" "staging-testers,stakeholders")
    PROD_GROUPS=$(prompt_input "Production Environment Groups" "beta-testers")
    
    echo ""
    
    # Slack configuration
    print_info "💬 Slack Integration (Optional):")
    SLACK_WEBHOOK=$(prompt_input "Slack Webhook URL (optional)")
    
    if [[ -n "$SLACK_WEBHOOK" ]]; then
        DEV_CHANNEL=$(prompt_input "Dev Channel" "#dev-builds")
        STG_CHANNEL=$(prompt_input "Staging Channel" "#staging-builds")
        PROD_CHANNEL=$(prompt_input "Production Channel" "#releases")
    else
        DEV_CHANNEL=""
        STG_CHANNEL=""
        PROD_CHANNEL=""
    fi
    
    # Generate configuration file
    generate_config_file
}

# Function to generate configuration file
generate_config_file() {
    print_info "Generating Firebase configuration file..."
    
    # Create .info directory if it doesn't exist
    mkdir -p "$(dirname "$FIREBASE_INFO_FILE")"
    
    # Convert comma-separated strings to JSON arrays
    DEV_TESTERS_JSON=$(echo "$DEV_TESTERS" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')
    STG_TESTERS_JSON=$(echo "$STG_TESTERS" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')
    PROD_TESTERS_JSON=$(echo "$PROD_TESTERS" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')
    
    DEV_GROUPS_JSON=$(echo "$DEV_GROUPS" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')
    STG_GROUPS_JSON=$(echo "$STG_GROUPS" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')
    PROD_GROUPS_JSON=$(echo "$PROD_GROUPS" | sed 's/,/","/g' | sed 's/^/"/' | sed 's/$/"/')
    
    # Generate JSON configuration
    cat > "$FIREBASE_INFO_FILE" <<EOF
{
  "projectId": "$PROJECT_ID",
  "apps": {
    "android": {
      "dev": {
        "appId": "$ANDROID_DEV_APP_ID",
        "packageName": "$ANDROID_DEV_PACKAGE"
      },
      "stg": {
        "appId": "$ANDROID_STG_APP_ID",
        "packageName": "$ANDROID_STG_PACKAGE"
      },
      "prod": {
        "appId": "$ANDROID_PROD_APP_ID",
        "packageName": "$ANDROID_PROD_PACKAGE"
      }
    },
    "ios": {
      "dev": {
        "appId": "$IOS_DEV_APP_ID",
        "bundleId": "$IOS_DEV_BUNDLE"
      },
      "stg": {
        "appId": "$IOS_STG_APP_ID",
        "bundleId": "$IOS_STG_BUNDLE"
      },
      "prod": {
        "appId": "$IOS_PROD_APP_ID",
        "bundleId": "$IOS_PROD_BUNDLE"
      }
    }
  },
  "distribution": {
    "testers": {
      "dev": [$DEV_TESTERS_JSON],
      "stg": [$STG_TESTERS_JSON],
      "prod": [$PROD_TESTERS_JSON]
    },
    "groups": {
      "dev": [$DEV_GROUPS_JSON],
      "stg": [$STG_GROUPS_JSON],
      "prod": [$PROD_GROUPS_JSON]
    },
    "releaseNotes": {
      "template": "Release notes for version {{version}} - {{flavor}} environment\n\nChanges:\n- Bug fixes and improvements\n- New features added\n\nBuild date: {{date}}"
    }
  },
  "slack": {
    "webhookUrl": "$SLACK_WEBHOOK",
    "channels": {
      "dev": "$DEV_CHANNEL",
      "stg": "$STG_CHANNEL",
      "prod": "$PROD_CHANNEL"
    }
  }
}
EOF

    print_success "Configuration file created successfully!"
    print_info "File location: $FIREBASE_INFO_FILE"
    
    # Validate the JSON
    if jq . "$FIREBASE_INFO_FILE" > /dev/null 2>&1; then
        print_success "JSON configuration is valid!"
    else
        print_error "Generated JSON is invalid. Please check the file manually."
        exit 1
    fi
}

# Function to show current configuration
show_current_config() {
    if [[ -f "$FIREBASE_INFO_FILE" ]]; then
        print_info "Current Firebase configuration:"
        jq . "$FIREBASE_INFO_FILE"
    else
        print_warning "No Firebase configuration found."
    fi
}

# Function to validate configuration
validate_config() {
    if [[ ! -f "$FIREBASE_INFO_FILE" ]]; then
        print_error "Firebase configuration file not found!"
        return 1
    fi
    
    print_info "Validating Firebase configuration..."
    
    # Check if JSON is valid
    if ! jq . "$FIREBASE_INFO_FILE" > /dev/null 2>&1; then
        print_error "Invalid JSON in configuration file!"
        return 1
    fi
    
    # Check required fields
    local project_id=$(jq -r '.projectId' "$FIREBASE_INFO_FILE")
    if [[ "$project_id" == "null" || "$project_id" == "your-firebase-project-id" ]]; then
        print_error "Project ID not configured properly!"
        return 1
    fi
    
    print_success "Configuration is valid!"
    
    # Show summary
    print_info "Configuration Summary:"
    echo "  Project ID: $project_id"
    echo "  Android Apps: $(jq -r '.apps.android | keys | length' "$FIREBASE_INFO_FILE")"
    echo "  iOS Apps: $(jq -r '.apps.ios | keys | length' "$FIREBASE_INFO_FILE")"
}

# Main function
main() {
    case "${1:-setup}" in
        "setup"|"configure")
            setup_interactive
            ;;
        "show"|"display")
            show_current_config
            ;;
        "validate"|"check")
            validate_config
            ;;
        "help"|"--help"|"-h")
            echo "Firebase App Distribution Setup Script"
            echo ""
            echo "Usage: $(basename "$0") [command]"
            echo ""
            echo "Commands:"
            echo "  setup, configure    Interactive setup (default)"
            echo "  show, display       Show current configuration"
            echo "  validate, check     Validate current configuration"
            echo "  help               Show this help message"
            ;;
        *)
            print_error "Unknown command: $1"
            echo "Use '$(basename "$0") help' for usage information."
            exit 1
            ;;
    esac
}

# Navigate to root directory
cd "$ROOT_DIR" || {
    print_error "Failed to navigate to the project root directory."
    exit 1
}

# Run main function
main "$@" 