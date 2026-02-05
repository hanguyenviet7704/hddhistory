@echo off
setlocal enabledelayedexpansion

REM Enhanced APK Installation Script with Centralized Configuration (Windows)
REM This script installs Android APK files using configuration from .info\ directory

REM Navigate to the root directory relative to the current script location
set "ROOT_DIR=%~dp0..\..\.."
cd /d "%ROOT_DIR%"
if %errorlevel% neq 0 (
    echo ❌ Failed to navigate to the project root directory.
    goto :end
)

REM Load common configuration functions
call "%~dp0..\common\common.bat"
if %errorlevel% neq 0 (
    echo ❌ Failed to load common configuration library.
    echo Make sure tools\windows\common\common.bat exists and is readable.
    goto :end
)

REM Initialize variables
set "FLAVOR="
set "DEVICE_ID="

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
if "%~1"=="-d" (
    set "DEVICE_ID=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--device" (
    set "DEVICE_ID=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help

call :log_error "Unknown option: %~1"
echo Use -h or --help for usage information
goto :end

:show_help
echo Usage: %~nx0 [dev^|stg^|prod] [-d DEVICE_ID]
echo.
echo Arguments:
echo   dev^|stg^|prod           Build flavor (required)
echo   -d, --device DEVICE_ID  Specific device ID to install to (optional)
echo   -h, --help             Show this help message
echo.
echo This script uses centralized configuration from .info\ directory.
goto :end

:args_done

REM Validate environment and parameters
call :validate_environment
if %errorlevel% neq 0 goto :end

if "%FLAVOR%"=="" (
    call :log_error "No flavor specified."
    echo Usage: %~nx0 [dev^|stg^|prod] [-d DEVICE_ID]
    echo Use -h or --help for more information
    goto :end
)

call :validate_flavor "%FLAVOR%"
if %errorlevel% neq 0 goto :end

REM Get configuration from centralized system
call :get_app_display_name "%FLAVOR%" APP_DISPLAY_NAME
call :get_android_package_name "%FLAVOR%" ANDROID_PACKAGE_NAME
call :get_output_path "android" "apk" APK_OUTPUT_PATH
call :get_flutter_command FLUTTER_CMD

call :log_step "Installing Android APK for %FLAVOR% flavor"
echo App Name: %APP_DISPLAY_NAME%
echo Package: %ANDROID_PACKAGE_NAME%
echo APK Path: %APK_OUTPUT_PATH%
echo Flutter Command: %FLUTTER_CMD%

REM Check if APK file exists
set "APK_FILE=%APK_OUTPUT_PATH%\app-%FLAVOR%-release.apk"
if not exist "%APK_FILE%" (
    call :log_error "APK file not found: %APK_FILE%"
    call :log_error "Please build the APK first with: tools\windows\build\build_apk.bat %FLAVOR%"
    goto :end
)

call :log_success "Found APK file: %APK_FILE%"

REM Build device argument if device ID is provided
set "DEVICE_ARG="
if not "%DEVICE_ID%"=="" (
    set "DEVICE_ARG=-d %DEVICE_ID%"
    call :log_info "Installing to specific device: %DEVICE_ID%"
)

REM Install the APK using Flutter
call :log_step "Installing APK using Flutter..."
%FLUTTER_CMD% install --flavor "%FLAVOR%" %DEVICE_ARG%

if %errorlevel% neq 0 (
    call :log_error "Failed to install APK for %FLAVOR% flavor"
    goto :end
)

call :log_success "APK installed successfully for %FLAVOR% flavor!"
call :log_info "Package: %ANDROID_PACKAGE_NAME%"

:end
endlocal

REM Pause for user removed for automation
