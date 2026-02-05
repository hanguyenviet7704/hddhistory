@echo off
setlocal enabledelayedexpansion

REM Enhanced Google Play Store Upload Script for Windows
REM This script uploads Android App Bundles to Google Play Console

REM Define directory structure with clean paths
set "SCRIPT_DIR=%~dp0"
for %%i in ("%SCRIPT_DIR%..\..\..") do set "ROOT_DIR=%%~fi"

REM Load common configuration functions
call "%SCRIPT_DIR%..\common\common.bat"
if %errorlevel% neq 0 (
    echo ❌ Failed to load common configuration library.
    echo Make sure tools\windows\common\common.bat exists and is readable.
    goto :end
)

REM Initialize variables
set "FLAVOR="
set "BUILD_FIRST=false"
set "TRACK=internal"
set "SPECIFIC_FILE="

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
if "%~1"=="--build-first" (
    set "BUILD_FIRST=true"
    shift
    goto :parse_args
)
if "%~1"=="--track" (
    set "TRACK=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--file" (
    set "SPECIFIC_FILE=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help

call :log_error "Unknown option: %~1"
goto :show_help

:show_help
echo Usage: %~nx0 [dev^|stg^|prod] [options]
echo.
echo Arguments:
echo   dev^|stg^|prod           Build flavor (required)
echo.
echo Options:
echo   --build-first           Build App Bundle before uploading
echo   --track ^<name^>          Upload track (internal, alpha, beta, production) [default: internal]
echo   --file ^<path^>           Specific App Bundle file to upload
echo   -h, --help             Show this help message
echo.
echo Examples:
echo   %~nx0 prod --build-first --track production
echo   %~nx0 stg --track beta
echo   %~nx0 dev --file build\app\outputs\bundle\dev\app-dev.aab
echo.
echo Note: This script requires proper Google Play Console API setup.
echo See documentation for setting up service account and API access.
goto :end

:args_done

REM Validate required parameters
if "%FLAVOR%"=="" (
    call :log_error "Flavor is required"
    goto :show_help
)

REM Validate environment
call :validate_environment
if %errorlevel% neq 0 goto :end

call :validate_flavor "%FLAVOR%"
if %errorlevel% neq 0 goto :end

REM Validate track
call :validate_track "%TRACK%"
if %errorlevel% neq 0 goto :end

REM Show configuration summary
call :show_config_summary "%FLAVOR%" "android"

REM Get configuration from centralized configs
call :get_app_display_name "%FLAVOR%" APP_NAME
call :get_android_package_name "%FLAVOR%" PACKAGE_NAME
call :get_pubspec_version VERSION

call :log_step "🚀 Preparing Google Play Store upload..."
echo App: %APP_NAME%
echo Package: %PACKAGE_NAME%
echo Version: %VERSION%
echo Flavor: %FLAVOR%
echo Track: %TRACK%
echo.

REM Build first if requested
if "%BUILD_FIRST%"=="true" (
    call :log_step "Building App Bundle before upload..."
    call "%SCRIPT_DIR%..\build\build_appbundle.bat" "%FLAVOR%"
    if %errorlevel% neq 0 (
        call :log_error "App Bundle build failed"
        goto :end
    )
    call :log_success "App Bundle built successfully"
    echo.
)

REM Determine App Bundle file path
if "%SPECIFIC_FILE%" neq "" (
    set "AAB_FILE=%SPECIFIC_FILE%"
) else (
    call :get_output_path "android" "appbundle" BUNDLE_OUTPUT_PATH
    set "AAB_FILE=%ROOT_DIR%\%BUNDLE_OUTPUT_PATH%\%FLAVOR%Release\app-%FLAVOR%-release.aab"
)

REM Validate App Bundle file exists
if not exist "%AAB_FILE%" (
    call :log_error "App Bundle file not found: %AAB_FILE%"
    call :log_info "Please build the App Bundle first or specify a valid file path"
    call :log_info "Build command: tools\windows\build\build_appbundle.bat %FLAVOR%"
    goto :end
)

call :log_info "Using App Bundle: %AAB_FILE%"

REM Check for Fastlane (preferred method)
where fastlane >nul 2>&1
if %errorlevel% equ 0 (
    call :upload_with_fastlane
) else (
    call :log_warning "Fastlane not found. Attempting manual upload instructions..."
    call :show_manual_upload_instructions
)

call :log_success "🎉 Upload process completed!"
echo.
echo Please check Google Play Console for upload status and review process.

goto :end

REM ============================================
REM Helper Functions
REM ============================================

:validate_track
set "track=%~1"
if "%track%"=="internal" exit /b 0
if "%track%"=="alpha" exit /b 0
if "%track%"=="beta" exit /b 0
if "%track%"=="production" exit /b 0

call :log_error "Invalid track: %track%"
call :log_info "Supported tracks: internal, alpha, beta, production"
exit /b 1

:upload_with_fastlane
call :log_step "Uploading to Google Play Store using Fastlane..."

REM Check if Fastfile exists
if not exist "%ROOT_DIR%\android\fastlane\Fastfile" (
    call :log_warning "Fastfile not found. Please set up Fastlane for this project."
    call :show_fastlane_setup_instructions
    exit /b 1
)

REM Navigate to android directory and run Fastlane
cd /d "%ROOT_DIR%\android"

REM Run Fastlane upload
fastlane upload_to_play_store aab:"%AAB_FILE%" track:%TRACK% skip_upload_apk:true skip_upload_metadata:true skip_upload_images:true skip_upload_screenshots:true

if %errorlevel% equ 0 (
    call :log_success "App Bundle uploaded successfully via Fastlane!"
) else (
    call :log_error "Fastlane upload failed. Check the output above for details."
    call :show_manual_upload_instructions
)

cd /d "%ROOT_DIR%"
exit /b 0

:show_fastlane_setup_instructions
echo.
call :log_info "To set up Fastlane for Google Play Console uploads:"
echo.
echo 1. Install Fastlane: gem install fastlane
echo 2. Navigate to android directory: cd android
echo 3. Initialize Fastlane: fastlane init
echo 4. Set up Google Play Console API access (service account JSON)
echo 5. Configure Fastfile with upload lane
echo.
echo See: https://docs.fastlane.tools/getting-started/android/setup/
exit /b 0

:show_manual_upload_instructions
echo.
call :log_info "Manual upload instructions:"
echo.
echo 1. Open Google Play Console: https://play.google.com/console
echo 2. Select your app: %PACKAGE_NAME%
echo 3. Navigate to: Release ^> %TRACK%
echo 4. Create new release
echo 5. Upload App Bundle: %AAB_FILE%
echo 6. Fill in release notes and publish
echo.
echo For API-based uploads, consider setting up:
echo - Google Play Console API
echo - Service account with proper permissions
echo - Fastlane or gradle-play-publisher plugin
exit /b 0

:end
endlocal

REM Pause for user removed for automation