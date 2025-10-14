# Project Information Folder (.info/)

This document explains the purpose and structure of the `.info/` folder and its role in Dcore project configuration systems.

## Overview

The `.info/` directory contains project-specific metadata and configuration files that define essential project information. This folder serves as a centralized location for project metadata that can be read by custom development tools and build scripts.

## Current Structure

```
.info/
├── app.json              # Application metadata and configuration
├── AuthKey_697CNSDLVW.p8 # Apple Developer authentication key
└── firebase_info.json    # Firebase project configuration
```

## Purpose and Vision

### Current Implementation
The `.info/` folder currently stores static configuration files that contain:
- Application name and identifiers
- Platform-specific package/bundle IDs
- Environment configurations
- Authentication keys and certificates

### Future Vision
The `.info/` folder is designed to be the foundation for **adaptive custom tooling**. In future versions, the custom tools in `/tools/` will read from this folder to automatically adapt to different projects without requiring code changes in the tools themselves.

## File Descriptions

### app.json
Contains core application metadata:

```json
{
    "appName": "Dcore",
    "android": {
        "packageName": "com.eup.meup"
    },
    "ios": {
        "bundleId": "com.eup.meup"
    },
    "environment": [
        {
            "name": "dev",
            "baseUrl": "https://dev.api.com"
        },
        {
            "name": "stg", 
            "baseUrl": "https://stg.api.com"
        },
        {
            "name": "prod",
            "baseUrl": "https://prod.api.com"
        }
    ]
}
```

#### Structure Breakdown
- **`appName`**: The display name of the application
- **`android.packageName`**: Android package identifier
- **`ios.bundleId`**: iOS bundle identifier  
- **`environment`**: Array of environment configurations with names and base URLs

### firebase_info.json
Contains Firebase project configuration:

```json
{
    "projects": {
        "dev": {
            "projectId": "meup-dev",
            "appId": {
                "android": "1:123456789:android:abcd1234",
                "ios": "1:123456789:ios:efgh5678"
            }
        },
        "stg": {
            "projectId": "meup-staging",
            "appId": {
                "android": "1:987654321:android:ijkl9012",
                "ios": "1:987654321:ios:mnop3456"
            }
        },
        "prod": {
            "projectId": "meup-prod",
            "appId": {
                "android": "1:111222333:android:qrst7890",
                "ios": "1:111222333:ios:uvwx1234"
            }
        }
    }
}
```

### Authentication Keys
- **`AuthKey_697CNSDLVW.p8`**: Apple Developer authentication key for iOS app distribution and App Store Connect API access

## Current Usage

### Build Script Integration
Currently, the build scripts have hardcoded references to project-specific values. The `.info/` folder provides the foundation for making these scripts more generic and reusable.

#### Example Current Usage (Hardcoded)
```bash
# In build scripts - current approach
APP_NAME="Dcore"
BUNDLE_ID="com.eup.meup"
```

#### Future Usage (Dynamic)
```bash
# In build scripts - future approach
APP_NAME=$(jq -r '.appName' .info/app/app.json)
BUNDLE_ID=$(jq -r '.ios.bundleId' .info/app/app.json)
```

### Firebase Configuration
The Firebase information could be dynamically read to configure builds for different environments:

```bash
# Future Firebase configuration
FIREBASE_PROJECT_ID=$(jq -r ".projects.${ENVIRONMENT}.projectId" .info/firebase_info.json)
```

## Future Enhancement Plans

### Tool Adaptability
The long-term vision is to make the custom tools in `/tools/` completely adaptable to new projects by reading configuration from the `.info/` folder.

#### Planned Enhancements
1. **Dynamic Project Detection**: Tools automatically detect project information
2. **Multi-Project Support**: Same tools work across different projects
3. **Configuration Validation**: Tools validate project setup automatically
4. **Template Generation**: Generate configuration files for new projects

#### Future Tool Behavior
```bash
# Tools will read from .info/ automatically
sh tools/macos/build/build_apk.sh dev
# Tool reads app name, bundle ID, etc. from .info/app/app.json
# No need to modify tool code for different projects
```

### Extended Metadata
Future versions may include additional metadata:

```json
{
    "appName": "Dcore",
    "version": "1.0.19",
    "buildNumber": "20",
    "platforms": ["android", "ios"],
    "minSdkVersion": {
        "android": 21,
        "ios": "12.0"
    },
    "signing": {
        "android": {
            "keyAlias": "upload",
            "storeFile": "upload-keystore.jks"
        },
        "ios": {
            "teamId": "ABC123DEF4",
            "bundleIdPrefix": "com.eup"
        }
    },
    "ci": {
        "enabled": true,
        "provider": "gitlab",
        "buildTriggers": ["develop", "main"]
    }
}
```

## Development Guidelines

### Adding New Metadata
When adding new project-specific information:

1. **Determine Scope**: Is this project-specific or environment-specific?
2. **Choose File**: Add to existing files or create new ones as needed
3. **Follow Schema**: Maintain consistent JSON structure
4. **Document Changes**: Update this documentation
5. **Plan Tool Integration**: Consider how tools will use this information

### File Naming Conventions
- Use descriptive names that indicate content purpose
- Use `.json` for structured data
- Use platform-specific extensions for platform-specific files (e.g., `.p8` for Apple keys)
- Group related information in single files when possible

### Security Considerations
- **Sensitive Files**: Files like authentication keys should be handled carefully
- **Version Control**: Consider which files should be committed vs. managed separately
- **Access Control**: Ensure proper permissions on sensitive files
- **Documentation**: Clearly document which files contain sensitive information

## Tool Integration Examples

### Reading App Metadata
```bash
#!/bin/bash
# Example: Reading app information in build scripts

# Read app name
APP_NAME=$(jq -r '.appName' .info/app/app.json)

# Read package names
ANDROID_PACKAGE=$(jq -r '.android.packageName' .info/app/app.json)
IOS_BUNDLE_ID=$(jq -r '.ios.bundleId' .info/app/app.json)

# Read environment URLs
DEV_API_URL=$(jq -r '.environment[] | select(.name=="dev") | .baseUrl' .info/app/app.json)

echo "Building $APP_NAME"
echo "Android Package: $ANDROID_PACKAGE"
echo "iOS Bundle ID: $IOS_BUNDLE_ID"
echo "Dev API URL: $DEV_API_URL"
```

### Firebase Project Selection
```bash
#!/bin/bash
# Example: Dynamic Firebase project configuration

ENVIRONMENT=$1  # dev, stg, or prod

# Read Firebase project ID for environment
FIREBASE_PROJECT_ID=$(jq -r ".projects.${ENVIRONMENT}.projectId" .info/firebase_info.json)

# Configure Firebase CLI
firebase use $FIREBASE_PROJECT_ID

echo "Using Firebase project: $FIREBASE_PROJECT_ID for environment: $ENVIRONMENT"
```

## Maintenance and Updates

### Regular Maintenance
- **Validate JSON**: Ensure all JSON files are valid and well-formed
- **Update Versions**: Keep version information current
- **Review Security**: Regularly audit sensitive file permissions
- **Documentation**: Keep documentation in sync with actual files

### When to Update
Update `.info/` files when:
- Project name or identifiers change
- New environments are added
- Firebase projects are modified
- Authentication keys are rotated
- New platforms are supported

### Validation Tools
Consider creating validation scripts:

```bash
#!/bin/bash
# validate_project_info.sh
echo "Validating project information..."

# Validate JSON files
jq empty .info/app/app.json && echo "✓ app.json is valid" || echo "✗ app.json is invalid"
jq empty .info/firebase_info.json && echo "✓ firebase_info.json is valid" || echo "✗ firebase_info.json is invalid"

# Check required keys exist
jq -e '.appName' .info/app/app.json > /dev/null && echo "✓ appName exists" || echo "✗ appName missing"
jq -e '.android.packageName' .info/app/app.json > /dev/null && echo "✓ Android package name exists" || echo "✗ Android package name missing"
jq -e '.ios.bundleId' .info/app/app.json > /dev/null && echo "✓ iOS bundle ID exists" || echo "✗ iOS bundle ID missing"
```

## Migration Strategy

When implementing dynamic tool reading:

1. **Phase 1**: Create comprehensive metadata in `.info/`
2. **Phase 2**: Update tools to read from `.info/` with fallbacks
3. **Phase 3**: Remove hardcoded values from tools
4. **Phase 4**: Add validation and error handling
5. **Phase 5**: Extend to support multiple projects

This phased approach ensures backward compatibility while enabling future enhancements.

## Best Practices

### File Management
- Keep files small and focused on specific concerns
- Use consistent formatting and indentation
- Validate JSON syntax before committing
- Document the purpose of each file

### Security
- Never commit sensitive production keys
- Use appropriate file permissions
- Implement secure key distribution processes
- Regular security audits of sensitive files

### Documentation
- Document all fields and their purposes
- Provide examples of valid values
- Explain relationships between different files
- Keep documentation updated with changes