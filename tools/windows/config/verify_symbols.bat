@echo off
setlocal enabledelayedexpansion

REM Enhanced Firebase Debug Symbols Verification Script with Centralized Configuration (Windows)
REM This script helps verify uploaded debug symbols in Firebase Console using configuration from .info\ directory

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
echo Usage: %~nx0 [dev^|stg^|prod] [--no-open]
echo.
echo Arguments:
echo   dev^|stg^|prod    Environment flavor (required)
echo   --no-open        Don't automatically open Firebase Console
echo   -h, --help      Show this help message
echo.
echo This script uses centralized configuration from .info\ directory.
echo It helps verify debug symbols uploaded to Firebase Crashlytics.
exit /b 0

:args_done

REM Validate environment and parameters
call :validate_environment
if %errorlevel% neq 0 exit /b 1

if "%FLAVOR%"=="" (
    call :log_error "No environment specified."
    echo Usage: %~nx0 [dev^|stg^|prod] [--no-open]
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

call :log_step "🔍 Firebase Debug Symbols Verification for %FLAVOR% environment"
echo.

echo Firebase Project: %FIREBASE_PROJECT%
echo Android Package: %ANDROID_PACKAGE%
echo Firebase App ID: %FIREBASE_APP_ID%
echo Debug Symbols Path: %DEBUG_INFO_PATH%
echo.

REM Build console URLs
set "PROJECT_URL=https://console.firebase.google.com/project/%FIREBASE_PROJECT%"
set "CONSOLE_URL=%PROJECT_URL%/crashlytics/app/android:%ANDROID_PACKAGE%"

call :log_info "📍 Firebase Console Links:"
echo   • Project Dashboard: %PROJECT_URL%
echo   • App Dashboard: %CONSOLE_URL%
echo   • Debug Symbols: %CONSOLE_URL%/settings/symbols
echo   • Issues/Crashes: %CONSOLE_URL%/issues
echo.

call :log_info "🔧 CLI Commands to check uploads:"
echo   firebase crashlytics:symbols:list --app="%FIREBASE_APP_ID%"
echo   firebase crashlytics:symbols:upload --app="%FIREBASE_APP_ID%" "%DEBUG_INFO_PATH%"
echo.

call :log_info "📁 Local debug symbols status:"
if exist "%DEBUG_INFO_PATH%" (
    call :log_success "Debug symbols directory: ✅ EXISTS"
    call :log_info "Path: %DEBUG_INFO_PATH%"
    echo Files in debug symbols directory:
    dir /b "%DEBUG_INFO_PATH%" 2>nul || echo   (No files found)
) else (
    call :log_warning "Debug symbols directory: ❌ NOT FOUND"
    call :log_info "Path: %DEBUG_INFO_PATH%"
    call :log_info "Run a build with obfuscation to generate symbols first:"
    call :log_info "  tools\windows\build\build_apk.bat %FLAVOR%"
    call :log_info "  tools\windows\build\build_appbundle.bat %FLAVOR%"
)

echo.

REM Check Firebase CLI availability
call :log_step "Checking Firebase CLI availability..."
where firebase >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "Firebase CLI is available"

    REM Check if user is logged in
    firebase projects:list >nul 2>&1
    if !errorlevel! equ 0 (
        call :log_success "Firebase CLI is authenticated"
        call :log_info "You can use the CLI commands shown above"
    ) else (
        call :log_warning "Firebase CLI not authenticated"
        call :log_info "Run 'firebase login' to authenticate"
    )
) else (
    call :log_warning "Firebase CLI not found"
    call :log_info "Install with: npm install -g firebase-tools"
)

REM Open Firebase Console if requested
if "%OPEN_CONSOLE%"=="true" (
    echo.
    call :log_info "🌐 Opening Firebase Console..."
    start "" "%CONSOLE_URL%/settings/symbols"
)

call :log_success "✅ Verification complete for %FLAVOR% environment"

endlocal
exit /b 0 