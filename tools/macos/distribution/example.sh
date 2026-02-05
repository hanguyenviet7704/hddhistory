#!/bin/bash

# Example usage of Firebase App Distribution tools
# This script demonstrates common workflows

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

echo "🚀 Firebase App Distribution - Example Usage"
echo ""

print_info "This script demonstrates how to use the Firebase App Distribution tools."
print_warning "This is for demonstration only - edit this file to match your needs!"
echo ""

# Example 1: First-time setup
print_info "Example 1: First-time setup"
echo "# Run this first to configure Firebase"
echo "./setup_firebase.sh"
echo ""

# Example 2: Quick development testing
print_info "Example 2: Quick development testing"
echo "# Build and distribute APK for dev environment"
echo "./distribute.sh quick-dev"
echo ""

# Example 3: Staging release
print_info "Example 3: Staging release preparation"
echo "# Build and distribute App Bundle for staging"
echo "./distribute.sh quick-stg"
echo ""

# Example 4: Production release
print_info "Example 4: Production release (both platforms)"
echo "# Build and distribute to both Android and iOS for production"
echo "./distribute.sh quick-prod"
echo ""

# Example 5: Custom Android distribution
print_info "Example 5: Custom Android distribution"
echo "# Distribute specific APK without building"
echo "./distribute_android.sh apk dev"
echo ""
echo "# Build and distribute App Bundle for staging"
echo "./distribute_android.sh appbundle stg build_first"
echo ""

# Example 6: iOS distribution
print_info "Example 6: iOS distribution"
echo "# Build and distribute IPA for production"
echo "./distribute_ios.sh prod build_first"
echo ""
echo "# Distribute existing IPA file"
echo "./distribute_ios.sh dev path/to/existing.ipa"
echo ""

# Example 7: Advanced usage
print_info "Example 7: Advanced usage"
echo "# Distribute both APK and App Bundle for dev"
echo "./distribute.sh android both dev build_first"
echo ""
echo "# Distribute both platforms for staging"
echo "./distribute.sh both appbundle stg build_first"
echo ""

# Example 8: Configuration management
print_info "Example 8: Configuration management"
echo "# Show current Firebase configuration"
echo "./setup_firebase.sh show"
echo ""
echo "# Validate Firebase configuration"
echo "./setup_firebase.sh validate"
echo ""

# Example 9: Integration with CI/CD
print_info "Example 9: CI/CD Integration"
echo "# Example CI/CD script"
echo "#!/bin/bash"
echo "# Build and distribute for different environments"
echo "if [ \"\$BRANCH\" == \"develop\" ]; then"
echo "  ./distribute.sh quick-dev"
echo "elif [ \"\$BRANCH\" == \"staging\" ]; then"
echo "  ./distribute.sh quick-stg"
echo "elif [ \"\$BRANCH\" == \"main\" ]; then"
echo "  ./distribute.sh quick-prod"
echo "fi"
echo ""

print_success "Examples completed!"
print_info "To get started:"
echo "1. Run: ./setup_firebase.sh"
echo "2. Try: ./distribute.sh quick-dev"
echo ""
print_warning "Remember to configure your Firebase project and testers first!" 