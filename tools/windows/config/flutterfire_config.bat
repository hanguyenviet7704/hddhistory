@echo off
setlocal enabledelayedexpansion

REM Enhanced FlutterFire Configuration Script with Centralized Configuration (Windows)
REM This script configures Firebase for different environments using configuration from .info\ directory

REM Navigate to the root directory relative to the current script location
set "ROOT_DIR=%~dp0..\..\.."
cd /d "%ROOT_DIR%"
if %errorlevel% neq 0 (
    echo ❌ Failed to navigate to the project root directory.
    exit /b 1
)

REM Load common configuration functions
call "%~dp0..\common\common.bat"
if %errorlevel% neq 0 (
    echo ❌ Failed to load common configuration library.
    echo Make sure tools\windows\common\common.bat exists and is readable.
    exit /b 1
)

REM Initialize variables
set "FLAVOR="
set "PLATFORMS=android"

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="dev" (
    set "FLAVOR=%~1"
    shift
    goto :parse_args
)
if "%~1"=="stg" (
    set "FLAVOR=%~1"
    shift
    goto :parse_args
)
if "%~1"=="prod" (
    set "FLAVOR=%~1"
    shift
    goto :parse_args
)
if "%~1"=="--with-ios" (
    set "PLATFORMS=ios,android"
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help

call :log_error "Unknown option: %~1"
echo Use -h or --help for usage information
exit /b 1

:show_help
echo Usage: %~nx0 [dev^|stg^|prod] [--with-ios]
echo.
echo Arguments:
echo   dev^|stg^|prod    Environment flavor (required)
echo   --with-ios       Include iOS configuration (optional, not recommended on Windows)
echo   -h, --help      Show this help message
echo.
echo This script uses centralized configuration from .info\ directory.
echo.
echo Examples:
echo   %~nx0 dev                  Configure Firebase for dev environment (Android only)
echo   %~nx0 prod --with-ios     Configure Firebase for prod environment (Android + iOS)
exit /b 0

:args_done

REM Validate environment and parameters
call :validate_environment
if %errorlevel% neq 0 exit /b 1

if "%FLAVOR%"=="" (
    call :log_error "No environment specified."
    echo Usage: %~nx0 [dev^|stg^|prod] [--with-ios]
    echo Use -h or --help for more information
    exit /b 1
)

call :validate_flavor "%FLAVOR%"
if %errorlevel% neq 0 exit /b 1

REM Get configuration from centralized system
call :get_android_package_name "%FLAVOR%" ANDROID_PACKAGE
call :get_firebase_project_id "%FLAVOR%" FIREBASE_PROJECT

REM Check if FlutterFire CLI is available
where flutterfire >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "FlutterFire CLI not found"
    call :log_error "Please install it with: dart pub global activate flutterfire_cli"
    exit /b 1
)

call :log_step "Configuring Firebase for %FLAVOR% environment"
echo Firebase Project: %FIREBASE_PROJECT%
echo Android Package: %ANDROID_PACKAGE%
echo Platforms: %PLATFORMS%
echo.

REM Execute FlutterFire configuration
call :log_info "Running FlutterFire configuration..."

REM Build the command based on platforms
if "%PLATFORMS%"=="android" (
    flutterfire config ^
        --overwrite-firebase-options ^
        --project=%FIREBASE_PROJECT% ^
        --out=lib/config/services/firebase/firebase_options_%FLAVOR%.dart ^
        --android-package-name=%ANDROID_PACKAGE% ^
        --android-out=android/app/src/%FLAVOR%/google-services.json ^
        --platforms=android
) else (
    REM Include iOS configuration (requires iOS bundle ID from config)
    call :get_ios_bundle_id "%FLAVOR%" IOS_BUNDLE_ID
    if "!IOS_BUNDLE_ID!"=="" (
        call :log_warning "iOS bundle ID not configured for %FLAVOR%, using Android-only configuration"
        flutterfire config ^
            --overwrite-firebase-options ^
            --project=%FIREBASE_PROJECT% ^
            --out=lib/config/services/firebase/firebase_options_%FLAVOR%.dart ^
            --android-package-name=%ANDROID_PACKAGE% ^
            --android-out=android/app/src/%FLAVOR%/google-services.json ^
            --platforms=android
    ) else (
        flutterfire config ^
            --overwrite-firebase-options ^
            --project=%FIREBASE_PROJECT% ^
            --out=lib/config/services/firebase/firebase_options_%FLAVOR%.dart ^
            --ios-bundle-id=!IOS_BUNDLE_ID! ^
            --ios-out=ios/Runner/%FLAVOR%/GoogleService-Info.plist ^
            --android-package-name=%ANDROID_PACKAGE% ^
            --android-out=android/app/src/%FLAVOR%/google-services.json ^
            --platforms=ios,android
    )
)

if %errorlevel% neq 0 (
    call :log_error "Firebase configuration for %FLAVOR% failed"
    exit /b 1
)

call :log_success "🎉 Firebase configuration for %FLAVOR% completed successfully!"
echo.
call :log_info "Generated files:"
call :log_info "  • Android: android/app/src/%FLAVOR%/google-services.json"
call :log_info "  • Flutter: lib/config/services/firebase/firebase_options_%FLAVOR%.dart"
if not "%PLATFORMS%"=="android" (
    call :log_info "  • iOS: ios/Runner/%FLAVOR%/GoogleService-Info.plist"
)

exit /b 0 