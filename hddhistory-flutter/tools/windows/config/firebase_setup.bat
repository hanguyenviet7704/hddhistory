@echo off
setlocal enabledelayedexpansion

REM Enhanced Firebase Setup Script with Centralized Configuration (Windows)
REM This script sets up Firebase services using configuration from .info\ directory

REM Navigate to the root directory relative to the current script location
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\..\..\"
cd /d "%ROOT_DIR%" || (
    echo ❌ Failed to navigate to the project root directory.
    exit /b 1
)

REM Load common configuration functions
call "%SCRIPT_DIR%..\common\common.bat"
if %errorlevel% neq 0 (
    echo ❌ Failed to load common configuration library.
    echo Make sure tools\windows\common\common.bat exists and is readable.
    exit /b 1
)

REM Check for parameters immediately
if "%1"=="" (
    call :log_error "No environment specified."
    echo Usage: %0 [dev^|stg^|prod] [android]
    exit /b 1
)

set "FLAVOR=%1"
set "PLATFORM=%2"
if "%PLATFORM%"=="" set "PLATFORM=android"

REM Validate environment and parameters
call :validate_environment
if %errorlevel% neq 0 exit /b 1

call :validate_flavor "%FLAVOR%"
if %errorlevel% neq 0 exit /b 1

call :validate_platform "%PLATFORM%"
if %errorlevel% neq 0 exit /b 1

REM Get debug symbols path from centralized configuration
call :get_debug_info_path DEBUG_SYMBOLS_PATH
if "%DEBUG_SYMBOLS_PATH%"=="" set "DEBUG_SYMBOLS_PATH=.obfuscation"

REM Check if debug symbols directory exists
if not exist "%DEBUG_SYMBOLS_PATH%" (
    call :log_error "Debug symbols directory '%DEBUG_SYMBOLS_PATH%' not found."
    call :log_info "Please run a build with obfuscation first to generate debug symbols."
    call :log_info "Example: --obfuscate --split-debug-info=%DEBUG_SYMBOLS_PATH%"
    exit /b 1
)

REM Get configuration from centralized configs
call :get_android_package_name "%FLAVOR%" EXPECTED_PACKAGE
set "GOOGLE_SERVICES_FILE=android\app\src\%FLAVOR%\google-services.json"

call :log_info "Configuration loaded from centralized configs:"
call :log_info "Package name: %EXPECTED_PACKAGE%"
call :log_info "Google services file: %GOOGLE_SERVICES_FILE%"

REM Check if google-services.json exists
if not exist "%GOOGLE_SERVICES_FILE%" (
    call :log_error "Firebase configuration file '%GOOGLE_SERVICES_FILE%' not found."
    call :log_info "Please run flutterfire configuration first."
    exit /b 1
)

REM Show configuration summary
call :show_config_summary "%FLAVOR%" "%PLATFORM%"

call :log_step "Setting up Firebase services for %FLAVOR% environment on %PLATFORM% platform..."
call :log_info "Using configuration from: %GOOGLE_SERVICES_FILE%"

REM Try to get Firebase App ID from centralized config first
call :get_firebase_app_id "%PLATFORM%" "%FLAVOR%" FIREBASE_APP_ID

if "%FIREBASE_APP_ID%"=="" (
    call :log_warning "Firebase App ID not found in centralized config, extracting from google-services.json"

    REM Extract mobilesdk_app_id for Android from google-services.json using PowerShell
    call :log_info "Using PowerShell to parse JSON..."
    powershell -Command "$json = Get-Content '%GOOGLE_SERVICES_FILE%' | ConvertFrom-Json; $client = $json.client | Where-Object { $_.client_info.android_client_info.package_name -eq '%EXPECTED_PACKAGE%' }; if ($client) { $client.client_info.mobilesdk_app_id } else { '' }" > temp_app_id.txt
    set /p FIREBASE_APP_ID=<temp_app_id.txt
    del temp_app_id.txt
)

REM Validate that we found the Firebase App ID
if "%FIREBASE_APP_ID%"=="" (
    call :log_error "Could not extract Firebase App ID from '%GOOGLE_SERVICES_FILE%'"
    call :log_info "Please verify the google-services.json file contains the correct package configuration."
    exit /b 1
)

call :log_success "Found Firebase App ID: %FIREBASE_APP_ID%"

REM Check if Firebase CLI is installed
call :log_step "Checking Firebase CLI..."
firebase --version >nul 2>&1
if errorlevel 1 (
    call :log_error "Firebase CLI is not installed."
    call :log_info "Please install it with: npm install -g firebase-tools"
    exit /b 1
)

call :log_success "Firebase CLI found"

REM Check if user is logged in to Firebase
call :log_step "Verifying Firebase CLI authentication..."
firebase projects:list >nul 2>&1
if errorlevel 1 (
    call :log_error "Not logged in to Firebase CLI."
    call :log_info "Please login with: firebase login"
    exit /b 1
)

call :log_success "Firebase CLI authenticated"

REM Create a temporary directory for filtered symbols
set "TEMP_SYMBOLS_DIR=%TEMP%\firebase_symbols_%RANDOM%"
call :log_step "Creating temporary directory for filtered symbols: %TEMP_SYMBOLS_DIR%"
mkdir "%TEMP_SYMBOLS_DIR%"

REM Filter Android symbols only
call :log_info "Filtering Android symbols..."
for /r "%DEBUG_SYMBOLS_PATH%" %%f in (*.android-* app.symbols) do (
    copy "%%f" "%TEMP_SYMBOLS_DIR%\" >nul 2>&1
)

REM Get Firebase project ID from centralized config
call :get_firebase_project_id "%FLAVOR%" FIREBASE_PROJECT_ID

REM Upload debug symbols to Firebase Crashlytics
call :log_step "Uploading Flutter debug symbols to Firebase Crashlytics (Android)..."
call :log_info "Filtered symbols path: %TEMP_SYMBOLS_DIR%"
call :log_info "Firebase Project ID: %FIREBASE_PROJECT_ID%"
call :log_info "Firebase App ID: %FIREBASE_APP_ID%"

firebase crashlytics:symbols:upload --app="%FIREBASE_APP_ID%" "%TEMP_SYMBOLS_DIR%"
set "UPLOAD_RESULT=%errorlevel%"

REM Clean up temp directory
call :log_info "Cleaning up temporary directory: %TEMP_SYMBOLS_DIR%"
rd /s /q "%TEMP_SYMBOLS_DIR%" 2>nul

if %UPLOAD_RESULT% neq 0 (
    call :log_error "Failed to upload Flutter debug symbols to Firebase Crashlytics (Android)."
    exit /b 1
)

echo.
call :log_success "Firebase Crashlytics Flutter debug symbols uploaded successfully for %FLAVOR% environment on %PLATFORM% platform!"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo Next steps:
echo 1. Your Flutter symbols are now uploaded to Firebase Crashlytics
echo 2. You can view crash reports with readable stack traces in the Firebase Console
echo 3. Make sure Crashlytics is properly initialized in your Flutter app
echo.
echo Firebase Console: https://console.firebase.google.com/project/%FIREBASE_PROJECT_ID%/crashlytics
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

endlocal
exit /b 0 