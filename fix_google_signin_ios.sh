#!/bin/bash

echo "=== Fixing Google Sign-In for iOS ==="

# 1. Clean Flutter build
echo "1. Cleaning Flutter build..."
flutter clean

# 2. Clean iOS build
echo "2. Cleaning iOS build..."
cd ios
rm -rf Pods
rm -rf Podfile.lock
rm -rf .symlinks
rm -rf Flutter/Flutter.framework
rm -rf Flutter/Flutter.podspec

# 3. Get Flutter packages
echo "3. Getting Flutter packages..."
cd ..
flutter pub get

# 4. Install pods
echo "4. Installing iOS pods..."
cd ios
pod install --repo-update

echo ""
echo "=== Done! ==="
echo ""
echo "Next steps:"
echo "1. Delete the app from your iPhone/simulator"
echo "2. Close Xcode if it's open"
echo "3. Run: flutter run"
echo "4. Test Google Sign-In"
echo ""
echo "If the issue persists, check:"
echo "- Firebase Console: Ensure iOS app is configured correctly"
echo "- Info.plist: Verify GIDClientID matches GoogleService-Info.plist"
echo "- URL Schemes: Verify REVERSED_CLIENT_ID is correct"
