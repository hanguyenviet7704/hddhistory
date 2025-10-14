# Migration Guide: Enhanced Tools for New Projects

## 🎯 Overview

This guide helps you migrate the enhanced tools system to a new Flutter project. The tools are now completely configurable through the `.info/` directory, eliminating hardcoded values.

## 📋 Prerequisites

Before starting, ensure you have:
- ✅ Flutter SDK installed
- ✅ jq installed (`brew install jq`)
- ✅ Firebase CLI installed (optional: `npm install -g firebase-tools`)
- ✅ Your new Flutter project initialized

## 🚀 Quick Migration (5 minutes)

### Step 1: Copy Tools and Configuration

```bash
# Navigate to your new project
cd /path/to/your-new-project

# Copy the enhanced tools
cp -r /path/to/artlexis-flutter/tools .
cp -r /path/to/artlexis-flutter/.info .

# Set executable permissions
find tools/macos -name "*.sh" -type f -exec chmod +x {} \;
```

### Step 2: Configure Your Project

Edit `.info/app/app.json` with your project details:

```json
{
    "appName": "YourAppName",
    "appDisplayName": "Your App Name",
    "version": "1.0.0",
    "buildNumber": "1",
    "android": {
        "packageName": "com.yourcompany.yourapp",
        "compileSdk": 34,
        "minSdk": 21,
        "targetSdk": 34
    },
    "ios": {
        "bundleId": "com.yourcompany.yourapp",
        "teamId": "YOUR_TEAM_ID",
        "issuerId": "YOUR_ISSUER_ID",
        "keyId": "YOUR_KEY_ID",
        "appStoreConnectAPIKeyPath": ".info/AuthKey_YOUR_KEY_ID.p8"
    },
    "flavors": {
        "dev": {
            "displayName": "Your App Dev",
            "android": {
                "packageName": "com.yourcompany.yourapp.dev"
            },
            "ios": {
                "bundleId": "com.yourcompany.yourapp.dev"
            }
        },
        "stg": {
            "displayName": "Your App Staging",
            "android": {
                "packageName": "com.yourcompany.yourapp.stg"
            },
            "ios": {
                "bundleId": "com.yourcompany.yourapp.stg"
            }
        },
        "prod": {
            "displayName": "Your App",
            "android": {
                "packageName": "com.yourcompany.yourapp"
            },
            "ios": {
                "bundleId": "com.yourcompany.yourapp"
            }
        }
    }
}
```

### Step 3: Configure Firebase

Edit `.info/app/firebase.json` with your Firebase project:

```json
{
  "projectId": "your-firebase-project-id",
  "apps": {
    "android": {
      "dev": {
        "appId": "1:123456789:android:your-dev-app-id",
        "packageName": "com.yourcompany.yourapp.dev"
      },
      "stg": {
        "appId": "1:123456789:android:your-stg-app-id",
        "packageName": "com.yourcompany.yourapp.stg"
      },
      "prod": {
        "appId": "1:123456789:android:your-prod-app-id",
        "packageName": "com.yourcompany.yourapp"
      }
    },
    "ios": {
      "dev": {
        "appId": "1:123456789:ios:your-dev-app-id",
        "bundleId": "com.yourcompany.yourapp.dev"
      },
      "stg": {
        "appId": "1:123456789:ios:your-stg-app-id",
        "bundleId": "com.yourcompany.yourapp.stg"
      },
      "prod": {
        "appId": "1:123456789:ios:your-prod-app-id",
        "bundleId": "com.yourcompany.yourapp"
      }
    }
  }
}
```

### Step 4: Test Configuration

```bash
# Test the configuration
./tools/macos/config/test_config.sh
```

### Step 5: Run Setup

```bash
# Run the automated setup
./tools/macos/config/setup_project.sh
```

## 🔧 Detailed Configuration

### Environment Files

Create your environment files in `.env/`:

```bash
# .env/.env.dev
API_BASE_URL=https://dev-api.yourcompany.com
APP_ENVIRONMENT=dev
DEBUG_MODE=true

# .env/.env.stg
API_BASE_URL=https://staging-api.yourcompany.com
APP_ENVIRONMENT=stg
DEBUG_MODE=false

# .env/.env.prod
API_BASE_URL=https://api.yourcompany.com
APP_ENVIRONMENT=prod
DEBUG_MODE=false
```

### iOS Certificates

If you're using iOS:

1. Add your App Store Connect API key to `.info/`
2. Update the key information in `app.json`
3. Ensure your provisioning profiles are in place

### Android Signing

For Android release builds:

1. Place your keystore file in `android/app/`
2. Update keystore information in `app.json`
3. Create keystore properties file if needed

## 📱 Usage Examples

### Build Commands

```bash
# Build development APK
./tools/macos/build/build_apk.sh dev

# Build production App Bundle
./tools/macos/build/build_appbundle.sh prod

# Build staging iOS
./tools/macos/build/build_ios.sh stg

# Configure Firebase for all environments
./tools/macos/config/flutterfire_config.sh dev
./tools/macos/config/flutterfire_config.sh stg
./tools/macos/config/flutterfire_config.sh prod
```

### Help and Documentation

```bash
# Get help for any command
./tools/macos/build/build_apk.sh --help
./tools/macos/config/setup_project.sh --help

# Test your configuration
./tools/macos/config/test_config.sh
```

## 🔍 Troubleshooting

### Common Issues

**"jq: command not found"**
```bash
brew install jq
```

**"Permission denied"**
```bash
find tools/macos -name "*.sh" -type f -exec chmod +x {} \;
```

**"Configuration file not found"**
```bash
# Ensure all required files exist
ls -la .info/
# Should show: app.json, firebase.json, build.json, paths.json, common.sh
```

**"Flutter command not found"**
- Install Flutter SDK
- Add Flutter to your PATH
- Or install FVM and update `.info/app/build.json` to use FVM

### Validation

Run the test script to validate everything is working:

```bash
./tools/macos/config/test_config.sh
```

This will check:
- ✅ Configuration files are readable
- ✅ Required tools are installed
- ✅ All flavors are properly configured
- ✅ Environment files exist
- ✅ Scripts have correct permissions

## 🎉 Success!

Once you've completed the migration:

1. **Your project is portable** - No hardcoded values
2. **Easy to maintain** - All configuration in one place
3. **Team-friendly** - Consistent build process
4. **CI/CD ready** - Automated builds supported

## 📚 Next Steps

- Review the main [README.md](README.md) for detailed usage
- Customize build configurations in `.info/app/build.json`
- Set up your CI/CD pipeline using these scripts
- Explore distribution scripts for automated deployment

## 🤝 Support

If you encounter issues:

1. Run `./tools/macos/config/test_config.sh` for diagnostics
2. Check the logs for specific error messages
3. Verify all configuration files are properly formatted JSON
4. Ensure required tools are installed and accessible

Happy building! 🚀