@echo off
setlocal enabledelayedexpansion

REM Enhanced Firebase Crashlytics Debug Symbols Checker with Centralized Configuration (Windows)
REM This script helps verify Firebase Crashlytics debug symbol configuration using configuration from .info\ directory

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
set "PLATFORM=android"
set "OPEN_CONSOLE=true"

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
if "%~1"=="android" (
    set "PLATFORM=%~1"
    shift
    goto :parse_args
)
if "%~1"=="--no-open" (
    set "OPEN_CONSOLE=false"
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help

call :log_error "Unknown option: %~1"
echo Use -h or --help for usage information
exit /b 1

:show_help
echo Usage: %~nx0 [dev^|stg^|prod] [android] [--no-open]
echo.
echo Arguments:
echo   dev^|stg^|prod    Environment flavor (required)
echo   android          Platform (default: android, iOS not supported on Windows)
echo   --no-open        Don't automatically open Firebase Console
echo   -h, --help      Show this help message
echo.
echo This script uses centralized configuration from .info\ directory.
echo It helps verify Firebase Crashlytics debug symbol configuration.
echo.
echo Examples:
echo   %~nx0 dev                 Check dev environment (Android only)
echo   %~nx0 prod --no-open     Check prod environment without opening browser
exit /b 0

:args_done

REM Validate environment and parameters
call :validate_environment
if %errorlevel% neq 0 exit /b 1

if "%FLAVOR%"=="" (
    call :log_error "No environment specified."
    echo Usage: %~nx0 [dev^|stg^|prod] [android] [--no-open]
    echo Use -h or --help for more information
    exit /b 1
)

call :validate_flavor "%FLAVOR%"
if %errorlevel% neq 0 exit /b 1

REM Get configuration from centralized system
call :get_android_package_name "%FLAVOR%" ANDROID_PACKAGE
call :get_firebase_project_id "%FLAVOR%" FIREBASE_PROJECT
call :get_firebase_app_id "%FLAVOR%" FIREBASE_APP_ID
call :get_debug_info_path DEBUG_INFO_PATH

call :log_step "🔍 Firebase Crashlytics Debug Symbols Checker"
echo.

echo Environment: %FLAVOR%
echo Platform: %PLATFORM% (iOS not supported on Windows)
echo Bundle ID: %ANDROID_PACKAGE%
echo Firebase Project: %FIREBASE_PROJECT%
echo Firebase App ID: %FIREBASE_APP_ID%
echo Debug Symbols Path: %DEBUG_INFO_PATH%
echo.

REM Check if Firebase CLI is installed
call :log_step "Checking Firebase CLI availability..."
where firebase >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "Firebase CLI is not installed"
    call :log_error "Please install it with: npm install -g firebase-tools"
    exit /b 1
)

call :log_success "Firebase CLI is available"

REM Check if user is logged in to Firebase
call :log_step "Checking Firebase authentication..."
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "Not logged in to Firebase CLI"
    call :log_error "Please login with: firebase login"
    exit /b 1
)

call :log_success "Firebase CLI is authenticated"

REM Check local debug symbols
echo.
call :log_step "Checking local debug symbols..."
if exist "%DEBUG_INFO_PATH%" (
    call :log_success "Local debug symbols directory found: %DEBUG_INFO_PATH%"

    REM Count symbol files
    set "SYMBOL_COUNT=0"
    for /f %%i in ('dir /b "%DEBUG_INFO_PATH%\*.android-*" 2^>nul ^| find /c /v ""') do set "SYMBOL_COUNT=%%i"
    if !SYMBOL_COUNT! equ 0 (
        for /f %%i in ('dir /b "%DEBUG_INFO_PATH%\app.symbols" 2^>nul ^| find /c /v ""') do set "SYMBOL_COUNT=%%i"
    )

    call :log_info "Found !SYMBOL_COUNT! relevant symbol files locally"

    if !SYMBOL_COUNT! gtr 0 (
        call :log_info "Example files:"
        dir /b "%DEBUG_INFO_PATH%\*.android-*" 2>nul | head -n 5
        if not exist "%DEBUG_INFO_PATH%\*.android-*" (
            dir /b "%DEBUG_INFO_PATH%\app.symbols" 2>nul
        )
    )
) else (
    call :log_warning "Local debug symbols directory not found"
    call :log_info "Path: %DEBUG_INFO_PATH%"
    call :log_info "This is normal if you haven't built the app with obfuscation enabled yet"
    call :log_info "To generate debug symbols, run:"
    call :log_info "  tools\windows\build\build_apk.bat %FLAVOR%"
    call :log_info "  tools\windows\build\build_appbundle.bat %FLAVOR%"
)

REM Check Firebase Crashlytics CLI commands
echo.
call :log_step "Available Firebase Crashlytics commands..."
firebase --help | findstr /C:"crashlytics" >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "Firebase Crashlytics commands are available"
    call :log_info "Key commands:"
    echo   firebase crashlytics:symbols:upload --app="%FIREBASE_APP_ID%" "%DEBUG_INFO_PATH%"
    echo   firebase crashlytics:mappings:upload --app="%FIREBASE_APP_ID%" mappings.txt
) else (
    call :log_warning "Firebase Crashlytics commands not found"
    call :log_info "This might be normal depending on your Firebase CLI version"
)

REM Build console URLs
set "PROJECT_URL=https://console.firebase.google.com/project/%FIREBASE_PROJECT%"
set "CRASHLYTICS_URL=%PROJECT_URL%/crashlytics/issues?state=open&time=last-seven-days&tag=all"
set "APP_URL=%PROJECT_URL%/crashlytics/app/android:%ANDROID_PACKAGE%"

echo.
call :log_info "🌐 Firebase Console Links:"
echo   • Project Overview: %PROJECT_URL%
echo   • Crashlytics Dashboard: %CRASHLYTICS_URL%
echo   • Android App Crashlytics: %APP_URL%
echo   • Debug Symbols Settings: %APP_URL%/settings/symbols
echo.

call :log_step "Symbol Upload Commands"
echo Manual upload commands:
echo   firebase crashlytics:symbols:upload --app="%FIREBASE_APP_ID%" "%DEBUG_INFO_PATH%"
echo   tools\windows\config\firebase_setup.bat %FLAVOR%
echo.

call :log_warning "📋 Important Notes:"
echo • Firebase CLI doesn't have a direct command to list uploaded debug symbols
echo • You need to check the Firebase Console to view uploaded symbols status
echo • Look for the 'Debug symbols' or 'Symbol files' section in the app settings
echo • Symbols are automatically uploaded during builds if firebase_setup.bat runs successfully
echo.

REM Open Firebase Console if requested
if "%OPEN_CONSOLE%"=="true" (
    call :log_info "🌐 Opening Firebase Crashlytics Console..."
    start "" "%CRASHLYTICS_URL%"
)

call :log_success "✅ Firebase Crashlytics debug symbols check complete for %FLAVOR% environment"

endlocal
exit /b 0