# Project Folder Structure

This document explains the detailed folder structure and organization of the DCore Flutter project.

## Root Directory Structure

```
meup-flutter/
├── .env/                           # Environment configuration files
├── .idea/                          # IntelliJ IDEA/Android Studio settings
├── .vscode/                        # VS Code settings and launch configurations
├── android/                        # Android-specific code and configuration
├── assets/                         # Application assets (images, fonts, etc.)
├── build/                          # Build output directory (generated)
├── docs/                           # Project documentation
├── ios/                            # iOS-specific code and configuration
├── lib/                            # Main Flutter application code
├── test/                           # Test files
├── tools/                          # Custom development tools and scripts
├── web/                            # Web-specific configuration
├── windows/                        # Windows-specific configuration
├── linux/                          # Linux-specific configuration
├── macos/                          # macOS-specific configuration
├── .cursorrules                    # Cursor IDE commit message generation rules
├── .fvmrc                          # Flutter Version Management configuration
├── .gitflow.config                 # GitFlow workflow configuration
├── .gitignore                      # Git ignore patterns
├── build.yaml                      # Build runner configuration
├── CLAUDE.md                       # Project overview and quick start guide
├── firebase.json                   # Firebase multi-flavor configuration
├── flavorizr.yaml                  # Multi-flavor configuration (dev/stg/prod)
├── flutter_launcher_icons.yaml    # App icon generation configuration
├── l10n.yaml                       # Localization configuration
├── LICENSE.md                      # Apache 2.0 License
├── pubspec.yaml                    # Project dependencies and configuration
├── analysis_options.yaml          # Dart analyzer configuration
└── README.md                       # Project overview
```

## Root Configuration Files

### Development and Build Configuration

#### `.cursorrules`
Cursor IDE configuration for automated commit message generation:
- Defines GitFlow commit message format: `type-TICKET-ID: subject`
- Valid types: feature, fix, refactor, style, docs, test, chore, perf
- Branch name pattern extraction for ticket IDs
- Context-aware commit suggestions based on file changes

#### `.fvmrc` 
Flutter Version Management configuration:
```json
{
  "flutter": "stable"
}
```

#### `.gitflow.config`
GitFlow workflow configuration defining:
- Branch prefixes (feature/, fix/, release/, hotfix/)
- Branch naming conventions with ticket IDs
- Merge strategies and validation rules
- Team workflow settings

#### `.gitignore`
Git ignore patterns for:
- Generated files (`**.g.dart`, `**.freezed.dart`, `**.config.dart`)
- Build artifacts (`/build/`, `.dart_tool/`)
- IDE files (`.idea/`, `.vscode/`)
- Platform-specific files (iOS, Android build artifacts)
- Cache and logs directories

#### `build.yaml`
Build runner configuration for code generation:
- **GoRouter**: Route generation with type-safe parameters
- **Retrofit**: REST API client generation
- **JSON Serializable**: Model serialization with snake_case field naming
- **Freezed**: Immutable classes with copyWith and equality
- **Injectable**: Dependency injection code generation
- **GraphQL Codegen**: GraphQL client generation
- **Flutter Gen**: Asset reference generation

### Multi-Flavor Configuration

#### `flavorizr.yaml`
Multi-flavor configuration for dev/stg/prod environments:
- **App Configuration**: Different app names and icons per flavor
- **Android**: Separate application IDs and Firebase configs
- **iOS**: Different bundle IDs and build settings  
- **Firebase Integration**: Flavor-specific Google Services configuration
- **Build Variables**: Environment-specific API URLs and debug flags

#### `firebase.json`
Firebase multi-platform configuration:
- **Android**: Flavor-specific google-services.json files
- **iOS**: Build configuration-specific GoogleService-Info.plist files
- **Dart**: Firebase options generation for each flavor
- **Debug Symbol Upload**: Automatic crashlytics symbol upload

### UI and Localization

#### `flutter_launcher_icons.yaml`
App icon generation configuration:
- **Multi-platform**: Android, iOS, Web, Windows, macOS icons
- **Adaptive Icons**: Background and foreground for Android
- **iOS Specific**: Alpha channel removal and tinted variants
- **Web**: PWA icon generation with theme colors

#### `l10n.yaml`
Localization configuration:
- **ARB Files**: Located in `assets/arb/app/`
- **Output**: Generated to `lib/config/l10n/`
- **Features**: Deferred loading, escaping, named parameters
- **Logging**: Untranslated messages tracking

### Project Information

#### `CLAUDE.md`
Comprehensive project guide containing:
- **Quick Start**: Setup, build, and test commands
- **Architecture**: Clean Architecture explanation
- **Libraries**: Key dependencies and tools
- **Environment**: Multi-flavor configuration
- **Workflow**: Development and testing strategies
- **Troubleshooting**: Common issues and solutions

#### `LICENSE.md`
Apache License Version 2.0 - Open source license terms and conditions.

## Core Application Structure (`lib/`)

### High-Level Organization
```
lib/
├── config/                         # Application configuration
├── core/                           # Shared utilities and constants
├── src/                            # Clean Architecture layers
├── main_dev.dart                   # Development environment entry point
├── main_stg.dart                   # Staging environment entry point
└── main_prod.dart                  # Production environment entry point
```

### Configuration Directory (`lib/config/`)
```
lib/config/
├── di/                             # Dependency Injection
│   ├── di.dart                     # Main DI configuration
│   ├── di.config.dart              # Generated DI configuration
│   ├── app_di_config.dart          # AppDI mixin and initialization
│   ├── cache_di.dart               # Cache managers configuration
│   ├── network_di.dart             # Network services (Dio, GraphQL)
│   ├── route_observer_di.dart      # Navigation observers
│   ├── supabase_di.dart            # Supabase configuration
│   └── tracking_di.dart            # Analytics and tracking services
├── l10n/                           # Localization (Generated)
│   ├── app_localizations.dart      # Base localization class
│   ├── app_localizations_en.dart   # English localizations
│   ├── app_localizations_vi.dart   # Vietnamese localizations
│   └── app_localizations_zh.dart   # Chinese localizations
├── routes/                         # Navigation and Routing
│   ├── routes.dart                 # Main route configuration
│   ├── routes.g.dart               # Generated route definitions
│   ├── app_pages.dart              # Page definitions
│   ├── app_routes.dart             # Route constants
│   ├── app_routes_config.dart      # Router configuration
│   └── app_routes_data.dart        # Route data classes
├── services/                       # Global Services
│   ├── ads/                        # Advertisement services
│   ├── app/                        # Core app services
│   ├── cache/                      # Caching services
│   ├── connectivity/               # Network connectivity
│   ├── device/                     # Device information and storage
│   ├── deeplink/                   # Deep linking
│   ├── file/                       # File handling
│   ├── firebase/                   # Firebase configuration files
│   ├── graphql/                    # GraphQL services and interceptors
│   ├── iap/                        # In-app purchase
│   ├── notification/               # Push notifications
│   ├── remote_config/              # Firebase remote config
│   ├── restful/                    # REST API services and interceptors
│   ├── supabase/                   # Supabase integration
│   ├── tracking/                   # Analytics and tracking
│   └── services.dart               # Services barrel file
├── share/                          # Shared Configuration
│   ├── share.dart                  # Shared utilities
│   └── app_global_value.dart       # Global application values
└── themes/                         # Application Themes
    ├── themes.dart                 # Main theme barrel file
    ├── theme_collection.dart       # Theme collections
    ├── util_theme.dart             # Theme utilities
    ├── material_theme.dart         # Material Design theme
    ├── text_theme.dart             # Text styling theme
    └── colors.dart                 # Color definitions
```

### Core Utilities (`lib/core/`)
```
lib/core/
├── constants/                      # Application Constants
│   ├── gen/                        # Generated constants (assets, fonts, colors)
│   │   ├── assets.gen.dart         # Generated asset references
│   │   ├── colors.gen.dart         # Generated color constants
│   │   └── fonts.gen.dart          # Generated font references
│   ├── api_constants.dart          # API endpoint constants
│   ├── app_constants.dart          # General app constants
│   └── storage_keys.dart           # Local storage key constants
├── extensions/                     # Dart Extensions
│   ├── context_extensions.dart     # BuildContext extensions
│   ├── datetime_extensions.dart    # DateTime utility extensions
│   ├── string_extensions.dart      # String utility extensions
│   └── widget_extensions.dart      # Widget utility extensions
├── network/                        # Network Layer
│   ├── api_client.dart             # Base API client
│   ├── dio_interceptors.dart       # HTTP interceptors
│   ├── network_info.dart           # Network connectivity
│   └── api_endpoints.dart          # API endpoint definitions
├── utils/                          # Utility Functions
│   ├── app_utils.dart              # General app utilities
│   ├── date_utils.dart             # Date formatting utilities
│   ├── file_utils.dart             # File handling utilities
│   ├── image_utils.dart            # Image processing utilities
│   ├── validation_utils.dart       # Form validation utilities
│   └── logger.dart                 # Logging utilities
└── widgets/                        # Reusable UI Components
    ├── buttons/                    # Custom button widgets
    │   ├── custom_elevated_button.dart
    │   ├── custom_outlined_button.dart
    │   └── loading_button.dart
    ├── dialogs/                    # Dialog widgets
    │   ├── confirmation_dialog.dart
    │   ├── error_dialog.dart
    │   └── loading_dialog.dart
    ├── forms/                      # Form-related widgets
    │   ├── custom_text_field.dart
    │   ├── dropdown_field.dart
    │   └── date_picker_field.dart
    └── indicators/                 # Progress and loading indicators
        ├── custom_loading_indicator.dart
        ├── empty_state_widget.dart
        └── error_state_widget.dart
```

### Source Code (`lib/src/`)
Following Clean Architecture principles:

```
lib/src/
├── domain/                         # Domain Layer (Business Logic)
│   ├── entities/                   # Core Business Objects
│   │   ├── user_entity.dart
│   │   ├── product_entity.dart
│   │   ├── order_entity.dart
│   │   └── settings_entity.dart
│   ├── repositories/               # Repository Interfaces
│   │   ├── user_repository.dart
│   │   ├── product_repository.dart
│   │   ├── order_repository.dart
│   │   └── auth_repository.dart
│   └── usecases/                   # Business Use Cases
│       ├── auth/                   # Authentication use cases
│       │   ├── login_usecase.dart
│       │   ├── logout_usecase.dart
│       │   ├── register_usecase.dart
│       │   └── refresh_token_usecase.dart
│       ├── user/                   # User management use cases
│       │   ├── get_user_usecase.dart
│       │   ├── update_user_usecase.dart
│       │   └── delete_user_usecase.dart
│       └── product/                # Product use cases
│           ├── get_products_usecase.dart
│           ├── get_product_details_usecase.dart
│           └── search_products_usecase.dart
├── data/                           # Data Layer (Data Sources)
│   ├── datasources/                # Data Source Interfaces & Implementations
│   │   ├── local/                  # Local data sources
│   │   │   ├── user_local_datasource.dart
│   │   │   ├── product_local_datasource.dart
│   │   │   └── cache_datasource.dart
│   │   └── remote/                 # Remote data sources
│   │       ├── user_remote_datasource.dart
│   │       ├── product_remote_datasource.dart
│   │       └── auth_remote_datasource.dart
│   ├── models/                     # Data Transfer Objects
│   │   ├── user_model.dart
│   │   ├── user_model.g.dart       # Generated JSON serialization
│   │   ├── product_model.dart
│   │   ├── product_model.g.dart
│   │   ├── order_model.dart
│   │   └── order_model.g.dart
│   └── repositories/               # Repository Implementations
│       ├── user_repository_impl.dart
│       ├── product_repository_impl.dart
│       ├── order_repository_impl.dart
│       └── auth_repository_impl.dart
└── presentation/                   # Presentation Layer (UI)
    ├── blocs/                      # BLoC State Management
    │   ├── auth/                   # Authentication BLoC
    │   │   ├── auth_bloc.dart
    │   │   ├── auth_event.dart
    │   │   ├── auth_state.dart
    │   │   └── auth_bloc.freezed.dart
    │   ├── user/                   # User management BLoC
    │   │   ├── user_cubit.dart
    │   │   ├── user_state.dart
    │   │   └── user_state.freezed.dart
    │   └── products/               # Product BLoC
    │       ├── product_bloc.dart
    │       ├── product_event.dart
    │       ├── product_state.dart
    │       └── product_bloc.freezed.dart
    ├── pages/                      # Full Screen Pages
    │   ├── auth/                   # Authentication pages
    │   │   ├── login_page.dart
    │   │   ├── register_page.dart
    │   │   └── forgot_password_page.dart
    │   ├── home/                   # Home and dashboard pages
    │   │   ├── home_page.dart
    │   │   ├── dashboard_page.dart
    │   │   └── search_page.dart
    │   ├── profile/                # User profile pages
    │   │   ├── profile_page.dart
    │   │   ├── edit_profile_page.dart
    │   │   └── settings_page.dart
    │   └── products/               # Product-related pages
    │       ├── product_list_page.dart
    │       ├── product_detail_page.dart
    │       └── product_search_page.dart
    └── widgets/                    # Feature-Specific Widgets
        ├── auth/                   # Authentication widgets
        │   ├── login_form.dart
        │   ├── register_form.dart
        │   └── social_login_buttons.dart
        ├── user/                   # User-related widgets
        │   ├── user_avatar.dart
        │   ├── user_info_card.dart
        │   └── user_stats_widget.dart
        └── products/               # Product widgets
            ├── product_card.dart
            ├── product_grid.dart
            ├── product_list_item.dart
            └── product_search_bar.dart
```

## Test Structure (`test/`)

```
test/
├── fixtures/                       # Test data and mock responses
│   ├── user_fixture.json
│   ├── product_fixture.json
│   └── api_responses/
├── helpers/                        # Test helper utilities
│   ├── test_helper.dart
│   ├── mock_data_factory.dart
│   └── test_extensions.dart
├── integration/                    # Integration tests
│   ├── features/
│   │   ├── authentication_test.dart
│   │   └── product_browsing_test.dart
│   └── app_test.dart
├── unit/                           # Unit tests
│   ├── domain/                     # Domain layer tests
│   │   ├── entities/
│   │   ├── repositories/
│   │   └── usecases/
│   ├── data/                       # Data layer tests
│   │   ├── datasources/
│   │   ├── models/
│   │   └── repositories/
│   └── presentation/               # Presentation layer tests
│       ├── blocs/
│       └── cubits/
└── widget/                         # Widget tests
    ├── pages/
    └── widgets/
```

## Assets Structure (`assets/`)

```
assets/
├── arb/                            # Localization files
│   ├── app/                        # App-level translations
│   │   ├── app_en.arb
│   │   ├── app_es.arb
│   │   └── app_fr.arb
│   └── module/                     # Module-specific translations
│       ├── auth_en.arb
│       ├── auth_es.arb
│       └── auth_fr.arb
├── fonts/                          # Custom fonts
│   └── Nunito/
│       ├── Nunito-Regular.ttf
│       ├── Nunito-Bold.ttf
│       ├── Nunito-Light.ttf
│       ├── Nunito-Medium.ttf
│       └── Nunito-SemiBold.ttf
├── icons/                          # App icons
│   ├── ic_launcher.png
│   ├── ic_launcher_dev.png
│   ├── ic_launcher_stg.png
│   └── splash_icon.png
├── images/                         # Static images
│   ├── logo.png
│   ├── placeholder.png
│   ├── onboarding/
│   └── backgrounds/
├── json/                           # JSON data files
│   ├── countries.json
│   └── app_config.json
├── lottie/                         # Lottie animations
│   ├── loading.json
│   ├── success.json
│   └── error.json
└── svg/                            # SVG graphics
    ├── app/                        # App-specific SVGs
    └── common/                     # Common/shared SVGs
```

## Tools Structure (`tools/`)

```
tools/
├── macos/                          # macOS development tools (FUNCTIONAL)
│   ├── build/                      # Build scripts
│   │   ├── build_apk.sh
│   │   ├── build_appbundle.sh
│   │   ├── build_ios.sh
│   │   └── reset_app.sh
│   ├── config/                     # Configuration scripts
│   │   └── firebase_setup.sh
│   ├── distribution/               # Distribution tools
│   │   └── upload_appstore.sh
│   ├── git/                        # Git workflow tools
│   ├── key/                        # Key management tools
│   ├── localization/               # Localization tools
│   │   ├── generate_localization.sh
│   │   ├── generate_arb_from_sheets.py
│   │   └── merge_arb_files.py
│   └── resource/                   # Resource generation
│       └── generate_file.sh
├── windows/                        # Windows tools (PLACEHOLDER)
│   ├── build/
│   ├── config/
│   ├── git/
│   ├── key/
│   └── localization/
└── linux/                         # Linux tools (localization active)
    ├── build/
    ├── config/
    ├── git/
    ├── key/
    └── localization/              # slang + sheets tooling
        ├── localization.sh
        ├── localization_cli.py
        ├── localization_common.sh
        └── README.md
```

## Documentation Structure (`docs/`)

```
docs/
├── common/                      # Cross-project documentation
│   ├── 01-01-git-workflow.md
│   ├── 01-02-coding-standards.md
│   ├── 01-03-commit-conventions.md
│   └── 01-04-flutter-best-practices.md
└── projects/                    # Project-specific documentation
    ├── 02-01-getting-started/
    ├── 02-02-project-architecture/
    ├── 02-03-build-process/
    ├── 02-04-environment-configuration/
    ├── 02-05-development-tools/
    ├── 02-06-ide-configuration/
    ├── 02-07-project-metadata/
    └── 02-08-testing-deployment/
```

## Platform-Specific Structures

### Android (`android/`)
```
android/
├── app/
│   ├── src/
│   │   ├── main/                   # Common Android configuration
│   │   ├── dev/                    # Development flavor
│   │   │   ├── res/
│   │   │   └── google-services.json
│   │   ├── stg/                    # Staging flavor
│   │   │   ├── res/
│   │   │   └── google-services.json
│   │   └── prod/                   # Production flavor
│   │       ├── res/
│   │       └── google-services.json
│   ├── build.gradle                # App-level build configuration
│   └── proguard-rules.pro         # ProGuard configuration
├── build.gradle                    # Project-level build configuration
└── gradle/                         # Gradle wrapper files
```

### iOS (`ios/`)
```
ios/
├── Runner/
│   ├── Info-dev.plist             # Development configuration
│   ├── Info-stg.plist             # Staging configuration
│   ├── Info-prod.plist            # Production configuration
│   ├── GoogleService-Info-dev.plist
│   ├── GoogleService-Info-stg.plist
│   ├── GoogleService-Info-prod.plist
│   └── Assets.xcassets/           # iOS assets and icons
├── Runner.xcodeproj/              # Xcode project
├── Runner.xcworkspace/            # Xcode workspace
└── Podfile                        # CocoaPods dependencies
```

## Key Naming Conventions

### File Naming
- **Dart files**: `snake_case.dart`
- **Test files**: `*_test.dart`
- **Generated files**: `*.g.dart`, `*.freezed.dart`
- **Configuration files**: Use descriptive names with extensions

### Directory Naming
- **Feature directories**: Use domain names (e.g., `auth`, `user`, `products`)
- **Layer directories**: Use architecture layer names (`domain`, `data`, `presentation`)
- **Type directories**: Use type plurals (`entities`, `repositories`, `usecases`)

### Class Naming
- **Entities**: `*Entity` (e.g., `UserEntity`)
- **Models**: `*Model` (e.g., `UserModel`)
- **Repositories**: `*Repository` or `*RepositoryImpl`
- **Use Cases**: `*UseCase` (e.g., `GetUserUseCase`)
- **BLoCs**: `*Bloc` or `*Cubit`
- **Pages**: `*Page` (e.g., `LoginPage`)
- **Widgets**: Descriptive names (e.g., `UserAvatar`, `ProductCard`)

## Generated Files

### Build Runner Generated
- `*.g.dart`: JSON serialization, dependency injection
- `*.freezed.dart`: Immutable classes with copyWith, equality
- `*.gr.dart`: Route definitions
- `*.config.dart`: Configuration files

### Flutter Generated
- `lib/config/l10n/`: Localization classes
- `lib/core/constants/gen/`: Asset references, fonts, colors

### Best Practices for Organization

#### Code Organization
- Group related functionality together
- Use consistent naming conventions
- Separate generated files appropriately
- Follow Clean Architecture boundaries

#### File Management
- Keep files focused and single-purpose
- Use proper imports and exports
- Organize dependencies logically
- Maintain clean folder structures

#### Documentation
- Document complex folder structures
- Explain architectural decisions
- Provide examples of proper usage
- Keep documentation updated with changes
