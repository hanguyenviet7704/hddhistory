# Environment Files (.env folder)

This document explains the purpose and structure of the `.env/` folder and its configuration files in the DCore Flutter project.

## Overview

The `.env/` directory contains environment-specific configuration files that define settings for different deployment environments. These files are used by the build system through the `--dart-define-from-file` flag to provide runtime configuration to the Flutter application.

## Directory Structure

```
.env/
├── .env.dev     # Development environment configuration
├── .env.stg     # Staging environment configuration
├── .env.prod    # Production environment configuration
└── .env.tmp     # Temporary configuration (if present)
```

## Environment Files Purpose

### Development Environment (`.env.dev`)
Contains configuration for local development:
- Local/development API endpoints
- Debug-enabled features
- Development Firebase project settings
- Enhanced logging and debugging options
- Developer-specific feature flags

### Staging Environment (`.env.stg`) 
Contains configuration for pre-production testing:
- Staging API endpoints that mirror production
- Production-like Firebase project settings
- Limited debug features
- Beta feature testing flags
- Performance monitoring for testing

### Production Environment (`.env.prod`)
Contains configuration for live production deployment:
- Production API endpoints
- Production Firebase project settings
- Optimized performance settings
- Minimal logging
- Production feature flags only

## Configuration File Format

### Standard Format
Each environment file follows the standard `.env` format:
```env
# Comments start with hash
KEY=value
ANOTHER_KEY=another_value
API_URL=https://api.example.com
ENABLE_DEBUG=true
```

### Key-Value Rules
- Each line contains one key-value pair
- No spaces around the equals sign
- Values can be strings, numbers, or booleans
- Comments start with `#`
- Empty lines are ignored

## Common Configuration Categories

### API Configuration
```env
# Base API URLs
BASE_URL=https://dev-api.meup.com
BASE_URL_STORAGE=https://dev-storage.meup.com
API_BASE_URL=https://dev-api.meup.com/api
GRAPHQL_BASE_URL=https://dev-api.meup.com/graphql
AI_SERVICE_BASE_URL=https://dev-ai.meup.com

# API Configuration
API_KEY=dev_api_key_here
CONNECT_TIMEOUT=30000
RECEIVE_TIMEOUT=30000
```

### Environment Identification
```env
# Environment Metadata
APP_ENVIRONMENT=dev
```

### Supabase Configuration
```env
# Supabase Settings
SUPABASE_URL=https://dev-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

### Google OAuth Configuration
```env
# Google Authentication
GOOGLE_WEB_CLIENT_ID=your_web_client_id.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=your_ios_client_id.googleusercontent.com
GOOGLE_ANDROID_CLIENT_ID=your_android_client_id.googleusercontent.com
```

## Build Integration

### Usage with --dart-define-from-file

The environment files are consumed by Flutter's build system using the `--dart-define-from-file` flag:

```bash
# Development build
flutter build apk --flavor dev --dart-define-from-file=.env/.env.dev

# Staging build  
flutter build apk --flavor stg --dart-define-from-file=.env/.env.stg

# Production build
flutter build apk --flavor prod --dart-define-from-file=.env/.env.prod
```

### Script Integration
Our custom build scripts automatically select the appropriate environment file:

```bash
# This script automatically uses .env/.env.dev
sh tools/macos/build/build_apk.sh dev

# This script automatically uses .env/.env.stg
sh tools/macos/build/build_apk.sh stg

# This script automatically uses .env/.env.prod
sh tools/macos/build/build_apk.sh prod
```

## Accessing Configuration in Code

### Environment Configuration Classes
The DCore project uses a structured approach to manage environment variables:

```dart
// lib/core/constants/manual/env.dart
mixin EnvKey {
  static const String baseUrl = 'BASE_URL';
  static const String baseUrlStorage = 'BASE_URL_STORAGE';
  static const String apiBaseUrl = 'API_BASE_URL';
  static const String graphqlBaseUrl = 'GRAPHQL_BASE_URL';
  static const String aiServiceBaseUrl = 'AI_SERVICE_BASE_URL';
  static const String apiKey = 'API_KEY';
  static const String connectTimeout = 'CONNECT_TIMEOUT';
  static const String receiveTimeout = 'RECEIVE_TIMEOUT';
  static const String appEnv = 'APP_ENVIRONMENT';

  // Supabase Keys
  static const String supabaseUrl = 'SUPABASE_URL';
  static const String supabaseAnonKey = 'SUPABASE_ANON_KEY';

  // Google OAuth Keys
  static const String googleWebClientId = 'GOOGLE_WEB_CLIENT_ID';
  static const String googleIosClientId = 'GOOGLE_IOS_CLIENT_ID';
  static const String googleAndroidClientId = 'GOOGLE_ANDROID_CLIENT_ID';
}

mixin EnvMode {
  static const String dev = 'dev';
  static const String stg = 'stg';
  static const String prod = 'prod';
}

class EnvConstant {
  static const String baseUrl = String.fromEnvironment(EnvKey.baseUrl);
  static const String baseUrlStorage = String.fromEnvironment(EnvKey.baseUrlStorage);
  static const String apiBaseUrl = String.fromEnvironment(EnvKey.apiBaseUrl);
  static const String graphqlBaseUrl = String.fromEnvironment(EnvKey.graphqlBaseUrl);
  static const String aiServiceBaseUrl = String.fromEnvironment(EnvKey.aiServiceBaseUrl);
  static const String apiKey = String.fromEnvironment(EnvKey.apiKey);
  static const String connectTimeout = String.fromEnvironment(EnvKey.connectTimeout);
  static const String receiveTimeout = String.fromEnvironment(EnvKey.receiveTimeout);
  static const String appEnv = String.fromEnvironment(EnvKey.appEnv);

  // Supabase Constants
  static const String supabaseUrl = String.fromEnvironment(EnvKey.supabaseUrl);
  static const String supabaseAnonKey = String.fromEnvironment(EnvKey.supabaseAnonKey);

  // Google OAuth Constants
  static const String googleWebClientId = String.fromEnvironment(EnvKey.googleWebClientId);
  static const String googleIosClientId = String.fromEnvironment(EnvKey.googleIosClientId);
  static const String googleAndroidClientId = String.fromEnvironment(EnvKey.googleAndroidClientId);

  // Environment Helper Methods
  static bool get isDevelopment => appEnv == EnvMode.dev;
  static bool get isStaging => appEnv == EnvMode.stg;
  static bool get isProduction => appEnv == EnvMode.prod;
}
```

### Usage in Dependency Injection
The environment constants are integrated with the dependency injection system:

```dart
// lib/config/di/network_di.dart
@module
abstract class NetworkModule {
  @Named(DIKey.baseUrl)
  @lazySingleton
  String get baseUrl => EnvConstant.baseUrl;

  @Named(DIKey.apiBaseUrl)
  @lazySingleton
  String get apiBaseUrl => EnvConstant.apiBaseUrl;

  @Named(DIKey.connectTimeout)
  int get connectTimeout => int.parse(EnvConstant.connectTimeout);

  @Named(DIKey.receiveTimeout)
  int get receiveTimeout => int.parse(EnvConstant.receiveTimeout);

  @Named(DIKey.appDio)
  @lazySingleton
  Dio appDio(RestfulService networkService, @Named(DIKey.appInterceptor) Interceptor interceptor) {
    final dio = networkService.createDio();
    dio.interceptors.add(interceptor);
    return dio;
  }
}
```

### Usage in Services
```dart
// Using environment constants in services
class RestfulService {
  Dio createDio() {
    return Dio(BaseOptions(
      baseUrl: EnvConstant.baseUrl,
      connectTimeout: Duration(milliseconds: int.parse(EnvConstant.connectTimeout)),
      receiveTimeout: Duration(milliseconds: int.parse(EnvConstant.receiveTimeout)),
    ));
  }
}

// Environment-specific behavior
class DebugService {
  static void log(String message) {
    if (EnvConstant.isDevelopment) {
      print('[DEV] $message');
    }
  }

  static bool get showDebugTools => EnvConstant.isDevelopment || EnvConstant.isStaging;
}
```

## Security Considerations

### Sensitive Information Handling
- **DO NOT** commit sensitive information like API keys, passwords, or tokens
- Use placeholder values for sensitive data in committed files
- Provide secure configurations separately to developers
- Consider using CI/CD systems to inject sensitive values

### Example of Safe Configuration
```env
# Safe - Generic configuration
BASE_URL=https://api.meup.com
API_BASE_URL=https://api.meup.com/api
APP_ENVIRONMENT=dev
CONNECT_TIMEOUT=30000
RECEIVE_TIMEOUT=30000

# AVOID - Sensitive information (use placeholders)
API_KEY=REPLACE_WITH_ACTUAL_API_KEY
SUPABASE_ANON_KEY=REPLACE_WITH_ACTUAL_SUPABASE_KEY
GOOGLE_WEB_CLIENT_ID=REPLACE_WITH_ACTUAL_CLIENT_ID
```

## Environment File Management

### Version Control
- Environment files with placeholder values should be committed
- Actual sensitive values should be provided through secure channels
- Use `.env.template` files to document required variables

### Local Development Setup
1. Copy template files to actual environment files
2. Replace placeholder values with actual development values
3. Ensure files are properly configured before running build scripts

### Team Coordination
- Document all required environment variables
- Provide clear instructions for obtaining sensitive values
- Maintain consistency across team member configurations

## Troubleshooting

### Common Issues

#### Missing Environment Variables
**Error**: `String.fromEnvironment` returns empty string
**Solution**: 
1. Verify the key exists in the environment file
2. Ensure no typos in key names
3. Check that build command uses correct `--dart-define-from-file` path

#### Build Script Not Using Correct Environment
**Error**: Application uses wrong configuration
**Solution**:
1. Verify build script is called with correct flavor parameter
2. Check that environment file path mapping is correct in build script
3. Ensure environment file is properly formatted

#### Environment File Format Issues
**Error**: Variables not loading correctly
**Solution**:
1. Check file encoding (should be UTF-8)
2. Ensure no spaces around `=` in key=value pairs
3. Verify no trailing whitespace or special characters

### Validation Commands

#### Check Environment File Content
```bash
# View environment file contents
cat .env/.env.dev

# Check for hidden characters
hexdump -C .env/.env.dev | head
```

#### Test Environment Loading
```bash
# Test build with verbose output
flutter build apk --flavor dev --dart-define-from-file=.env/.env.dev --verbose
```

#### Verify Configuration in App
Add debug logging to verify configuration is loaded correctly:
```dart
void printEnvironmentConfig() {
  print('Environment: ${EnvConstant.appEnv}');
  print('Base URL: ${EnvConstant.baseUrl}');
  print('API URL: ${EnvConstant.apiBaseUrl}');
  print('GraphQL URL: ${EnvConstant.graphqlBaseUrl}');
  print('Supabase URL: ${EnvConstant.supabaseUrl}');
  print('Is Development: ${EnvConstant.isDevelopment}');
  print('Is Staging: ${EnvConstant.isStaging}');
  print('Is Production: ${EnvConstant.isProduction}');
}
```

## Best Practices

### File Organization
- Keep related configuration grouped together
- Use clear, descriptive variable names
- Include comments for complex or non-obvious settings
- Maintain consistent formatting across all environment files

### Configuration Management
- Document all required variables
- Use sensible default values where possible
- Validate configuration at application startup
- Implement fallback behavior for missing configuration

### Development Workflow
- Always test builds with all three environments
- Verify configuration changes work across all environments
- Update documentation when adding new configuration options
- Review environment files during code review process