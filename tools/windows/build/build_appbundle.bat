@echo off
setlocal enabledelayedexpansion

REM Enhanced App Bundle Build Script with Centralized Configuration (Windows)
REM This script builds Android App Bundle files using configuration from .info\ directory

REM Navigate to the root directory relative to the current script location
set "ROOT_DIR=%~dp0..\..\..\"
cd /d "%ROOT_DIR%"
if %errorlevel% neq 0 (
    echo ❌ Failed to navigate to the project root directory.
    goto :end
)

REM Load common configuration functions
call "%~dp0\..\common\common.bat"
if %errorlevel% neq 0 (
    echo ❌ Failed to load common configuration library.
    echo Make sure tools\windows\common\common.bat exists and is readable.
    goto :end
)

REM Initialize variables
set "NO_TREE_SHAKE="
set "FLAVOR="

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="--no-tree-shake-icons" (
    set "NO_TREE_SHAKE=--no-tree-shake-icons"
    shift
    goto :parse_args
)
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
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help

call :log_error "Unknown option: %~1"
echo Use -h or --help for usage information
goto :end

:show_help
echo Usage: %~nx0 [dev^|stg^|prod] [--no-tree-shake-icons]
echo.
echo Arguments:
echo   dev^|stg^|prod           Build flavor (required)
echo   --no-tree-shake-icons  Disable tree shaking for icons (optional)
echo   -h, --help            Show this help message
echo.
echo This script uses centralized configuration from .info\ directory.
goto :end

:args_done

REM Validate environment and parameters
call :validate_environment
if %errorlevel% neq 0 goto :end

if "%FLAVOR%"=="" (
    call :log_error "No flavor specified."
    echo Usage: %~nx0 [dev^|stg^|prod] [--no-tree-shake-icons]
    echo Use -h or --help for more information
    goto :end
)

call :validate_flavor "%FLAVOR%"
if %errorlevel% neq 0 goto :end

REM Get configuration from centralized system
call :get_app_display_name "%FLAVOR%" APP_DISPLAY_NAME
call :get_android_package_name "%FLAVOR%" ANDROID_PACKAGE_NAME
call :get_env_file_path "%FLAVOR%" ENV_FILE
call :get_output_path "android" "appbundle" BUNDLE_OUTPUT_PATH
call :get_debug_info_path DEBUG_INFO_OUTPUT_PATH
call :get_flutter_command FLUTTER_CMD

REM Create output directories
if not exist "%BUNDLE_OUTPUT_PATH%" mkdir "%BUNDLE_OUTPUT_PATH%" 2>nul
if not exist "%DEBUG_INFO_OUTPUT_PATH%" mkdir "%DEBUG_INFO_OUTPUT_PATH%" 2>nul

call :log_step "Building Android App Bundle for %FLAVOR% flavor"
echo App Name: %APP_DISPLAY_NAME%
echo Package: %ANDROID_PACKAGE_NAME%
echo Environment: %ENV_FILE%
echo Output: %BUNDLE_OUTPUT_PATH%
echo Debug Info: %DEBUG_INFO_OUTPUT_PATH%
echo Flutter Command: %FLUTTER_CMD%
echo.

REM Check if environment file exists
if not exist "%ENV_FILE%" (
    call :log_error "Environment file not found: %ENV_FILE%"
    call :log_error "Please ensure the environment configuration exists for %FLAVOR% flavor"
    goto :end
)

call :log_info "Environment file contents:"
type "%ENV_FILE%"
echo.

REM Build App Bundle with centralized configuration
call :log_step "Running Flutter build appbundle..."
%FLUTTER_CMD% build appbundle ^
    --release ^
    %NO_TREE_SHAKE% ^
    --obfuscate ^
    --split-debug-info="%DEBUG_INFO_OUTPUT_PATH%" ^
    --flavor "%FLAVOR%" ^
    --dart-define-from-file="%ENV_FILE%" ^
    -t "lib/main_%FLAVOR%.dart"

if %errorlevel% neq 0 (
    call :log_error "App Bundle build failed for %FLAVOR% flavor"
    goto :end
)

call :log_success "App Bundle built successfully for %FLAVOR% flavor!"
echo Output directory: %BUNDLE_OUTPUT_PATH%

REM Automatically upload debug symbols to Firebase Crashlytics
echo.
call :log_step "Uploading debug symbols to Firebase Crashlytics..."
set "FIREBASE_SETUP_SCRIPT=%~dp0..\config\firebase_setup.bat"

if exist "%FIREBASE_SETUP_SCRIPT%" (
    call "%FIREBASE_SETUP_SCRIPT%" "%FLAVOR%" "android"

    if !errorlevel! equ 0 (
        call :log_success "Debug symbols uploaded successfully!"
    ) else (
        call :log_warning "Debug symbols upload failed, but App Bundle build was successful"
        call :log_info "You can manually upload later with: %FIREBASE_SETUP_SCRIPT% %FLAVOR% android"
    )
) else (
    call :log_warning "Firebase setup script not found at: %FIREBASE_SETUP_SCRIPT%"
    call :log_info "Debug symbols were not uploaded automatically"
)

REM Show build summary
echo.
call :show_build_summary "%FLAVOR%" "android" "appbundle" "%BUNDLE_OUTPUT_PATH%"

REM Open output directory in Explorer
echo.
call :log_info "Opening App Bundle directory in Explorer..."
start explorer "%BUNDLE_OUTPUT_PATH%"

:end
popd
endlocal

REM Pause for user removed for automation
