# CI/CD Setup Guide for Android

This guide helps you configure CI/CD for Android builds using GitHub Actions and GitLab CI.

## Required Secrets and Environment Variables

### GitHub Actions Secrets

Go to your GitHub repository → Settings → Secrets and variables → Actions → New repository secret

#### Android Signing (Required for production builds)
- `ANDROID_KEYSTORE_BASE64`: Base64 encoded keystore file
- `ANDROID_KEY_ALIAS`: Key alias from your keystore
- `ANDROID_STORE_PASSWORD`: Keystore password
- `ANDROID_KEY_PASSWORD`: Key password

#### Firebase App Distribution
- `FIREBASE_TOKEN`: Firebase CLI token for deployment
- `FIREBASE_ANDROID_APP_ID_DEV`: Firebase App ID for dev flavor
- `FIREBASE_ANDROID_APP_ID_STG`: Firebase App ID for staging flavor

#### Google Play Store (Optional - for production deployment)
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`: Service account JSON for Play Store API

### GitLab CI/CD Variables

Go to your GitLab project → Settings → CI/CD → Variables

#### Android Signing (Required for production builds)
- `ANDROID_KEYSTORE_BASE64`: Base64 encoded keystore file (Type: Variable, Protected: Yes)
- `ANDROID_KEY_ALIAS`: Key alias from your keystore (Type: Variable, Protected: Yes)
- `ANDROID_STORE_PASSWORD`: Keystore password (Type: Variable, Protected: Yes, Masked: Yes)
- `ANDROID_KEY_PASSWORD`: Key password (Type: Variable, Protected: Yes, Masked: Yes)

#### Firebase App Distribution
- `FIREBASE_TOKEN`: Firebase CLI token for deployment (Type: Variable, Protected: Yes, Masked: Yes)
- `FIREBASE_ANDROID_APP_ID_DEV`: Firebase App ID for dev flavor (Type: Variable, Protected: No)
- `FIREBASE_ANDROID_APP_ID_STG`: Firebase App ID for staging flavor (Type: Variable, Protected: No)

#### Google Play Store (Optional - for production deployment)
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`: Service account JSON for Play Store API (Type: File or Variable, Protected: Yes)

## Setup Instructions

### 1. Generate Android Keystore (if you don't have one)

```bash
keytool -genkey -v -keystore android/app/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias your-key-alias
```

### 2. Convert Keystore to Base64

```bash
# On macOS/Linux
base64 -i android/app/keystore.jks | pbcopy

# On Windows
certutil -encode android/app/keystore.jks keystore.txt
# Then copy the content between -----BEGIN CERTIFICATE----- and -----END CERTIFICATE-----
```

### 3. Get Firebase Token

```bash
# Install Firebase CLI if you haven't
npm install -g firebase-tools

# Login and get token
firebase login:ci
```

### 4. Setup Google Play Store API (Optional)

1. Go to [Google Play Console](https://play.google.com/console)
2. Navigate to Settings → Developer account → API access
3. Create or link a Google Cloud project
4. Create a service account with "Service Account User" role
5. Download the JSON key file
6. Convert to base64 or use as-is depending on your CI platform

### 5. Get Firebase App IDs

```bash
# List your Firebase apps
firebase apps:list

# The App ID format is usually: 1:123456789:android:abcdef123456
```

## Workflow Triggers

### GitHub Actions

- **Test**: Runs on every push and pull request to `develop`, `main`, `master`
- **Build Dev**: Runs on push to `develop` branch
- **Build Staging**: Runs on push to `main` or `release/*` branches
- **Build Production**: Runs on tags containing `prod`
- **Deploy Dev**: Auto-deploys dev builds from `develop`
- **Deploy Staging**: Auto-deploys staging builds from `main` or release branches
- **Deploy Production**: Deploys to Play Store on production tags (manual approval)

### GitLab CI

- **Test**: Runs on every commit
- **Build Dev**: Runs on `develop` and merge requests
- **Build Staging**: Runs on `main`, `release/*` branches, and merge requests
- **Build Production**: Runs on tags and `prod/*` branches
- **Deploy**: All deployments are manual (can be changed to automatic)

## Build Artifacts

### APK Builds
- **Location**: `build/app/outputs/flutter-apk/`
- **Naming**: `app-{flavor}-release.apk`
- **Retention**: 30 days (GitHub), 1 week (GitLab)

### App Bundle Builds
- **Location**: `build/app/outputs/bundle/{flavor}Release/`
- **Naming**: `app-{flavor}-release.aab`
- **Retention**: 30 days (GitHub), 1 month (GitLab)

### Debug Symbols
- **Location**: `.obfuscation/`
- **Purpose**: Crash reporting and debugging
- **Uploaded**: Automatically to Firebase Crashlytics

## Environment Configuration

The CI/CD workflows automatically create environment files for each flavor:

### Dev Environment (`.env/.env.dev`)
```
API_BASE_URL=https://dev.venusshop.top/api/v1
ENVIRONMENT=development
DEBUG_MODE=true
```

### Staging Environment (`.env/.env.stg`)
```
API_BASE_URL=https://dev.venusshop.top/api/v1
ENVIRONMENT=staging
DEBUG_MODE=true
```

### Production Environment (`.env/.env.prod`)
```
API_BASE_URL=https://venusshop.top/api/v1
ENVIRONMENT=production
DEBUG_MODE=false
```

## Deployment Targets

### Development (Dev Flavor)
- **Target**: Firebase App Distribution
- **Groups**: internal-testers
- **Trigger**: Automatic on `develop` branch

### Staging (Stg Flavor)
- **Target**: Firebase App Distribution
- **Groups**: qa-testers, stakeholders
- **Trigger**: Automatic on `main` branch or release branches

### Production (Prod Flavor)
- **Target**: Google Play Store (Internal Track)
- **Review**: Manual approval required
- **Trigger**: Tags containing `prod`

## Troubleshooting

### Common Issues

1. **Build fails with keystore error**
   - Ensure `ANDROID_KEYSTORE_BASE64` is correctly encoded
   - Check that keystore passwords are correct
   - Verify key alias exists in the keystore

2. **Firebase deployment fails**
   - Verify `FIREBASE_TOKEN` is valid (tokens expire)
   - Check Firebase App IDs are correct
   - Ensure Firebase project has App Distribution enabled

3. **Play Store upload fails**
   - Verify service account has proper permissions
   - Check package name matches exactly
   - Ensure version code is higher than existing releases

4. **Code generation fails**
   - Run `flutter clean` and `flutter pub get`
   - Check for syntax errors in model files
   - Ensure all dependencies are properly installed

### Getting Help

1. Check the CI/CD logs for specific error messages
2. Verify all secrets and variables are correctly set
3. Test builds locally using the same commands as CI
4. Consult Flutter's official CI/CD documentation

## Security Best Practices

1. **Never commit secrets to the repository**
2. **Use masked variables for passwords and tokens**
3. **Enable branch protection for production deployments**
4. **Regularly rotate Firebase tokens and service account keys**
5. **Use separate Firebase projects for different environments**
6. **Enable required reviews for production releases**

## Manual Deployment

You can trigger manual deployments using:

### GitHub Actions
- Go to Actions tab → Select workflow → Run workflow → Choose parameters

### GitLab CI
- Go to CI/CD → Pipelines → Run pipeline or use manual jobs in existing pipelines

## Next Steps

1. Set up the required secrets and environment variables
2. Test the workflows with a small change
3. Configure branch protection rules
4. Set up Firebase App Distribution groups
5. Configure Google Play Store internal testing track
6. Document your release process for the team