@echo off
setlocal enabledelayedexpansion

REM Enhanced APK Build Script with Centralized Configuration (Windows)
REM This script builds Android APK files using configuration from .info\ directory

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
set "DISTRIBUTE=false"
set "DISTRIBUTION_GROUP="
set "DISTRIBUTION_TESTERS="

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="--no-tree-shake-icons" (
    set "NO_TREE_SHAKE=--no-tree-shake-icons"
    shift
    goto :parse_args
)
if "%~1"=="--distribute" (
    set "DISTRIBUTE=true"
    shift
    goto :parse_args
)
if "%~1"=="--group" (
    set "DISTRIBUTION_GROUP=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--testers" (
    set "DISTRIBUTION_TESTERS=%~2"
    shift
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
echo Usage: %~nx0 [dev^|stg^|prod] [options]
echo.
echo Arguments:
echo   dev^|stg^|prod           Build flavor (required)
echo.
echo Options:
echo   --no-tree-shake-icons  Disable tree shaking for icons
echo   --distribute           Distribute to Firebase App Distribution after build
echo   --group ^<name^>         Override distribution group (uses config by default)
echo   --testers ^<emails^>     Override testers list (comma-separated)
echo   -h, --help            Show this help message
echo.
echo Examples:
echo   %~nx0 dev
echo   %~nx0 prod --distribute
echo   %~nx0 stg --distribute --group qa-team
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

REM Get configuration from centralized configs
call :get_app_display_name "%FLAVOR%" APP_NAME
call :get_android_package_name "%FLAVOR%" PACKAGE_NAME
call :get_env_file_path "%FLAVOR%" ENV_FILE
call :get_output_path "android" "apk" APK_OUTPUT_PATH
call :get_debug_info_path DEBUG_INFO_PATH
call :get_flutter_command FLUTTER_CMD

REM Validate required files
if not exist "%ENV_FILE%" (
    call :log_error "Environment file not found: %ENV_FILE%"
    goto :end
)

REM Create output directory if it doesn't exist
if not exist "%APK_OUTPUT_PATH%" mkdir "%APK_OUTPUT_PATH%"

REM Show configuration summary
call :show_config_summary "%FLAVOR%" "android"

REM Display environment file contents
call :log_step "Environment Configuration"
echo Using environment variables from: %ENV_FILE%
echo Contents:
type "%ENV_FILE%"
echo.

REM Build APK with dynamic configuration
call :log_step "Building APK for %FLAVOR% flavor..."

REM Construct build command
set "BUILD_CMD=%FLUTTER_CMD% build apk --release --flavor %FLAVOR% --dart-define-from-file=%ENV_FILE% -t lib/main_%FLAVOR%.dart --obfuscate --split-debug-info=%DEBUG_INFO_PATH%"

REM Add optional arguments
if "%NO_TREE_SHAKE%" neq "" (
    set "BUILD_CMD=%BUILD_CMD% %NO_TREE_SHAKE%"
)

REM Print the complete command that will be executed
echo.
call :log_step "Executing build command:"
echo Command: %BUILD_CMD%
echo.

REM Execute build command
%BUILD_CMD%

if %errorlevel% neq 0 (
    call :log_error "APK build failed for %FLAVOR% flavor."
    goto :end
)

call :log_success "APK built successfully for %FLAVOR% flavor."
echo Output location: %APK_OUTPUT_PATH%

REM Automatically upload debug symbols to Firebase Crashlytics
echo.
call :log_step "Uploading debug symbols to Firebase Crashlytics..."
set "FIREBASE_SETUP_SCRIPT=%~dp0..\config\firebase_setup.bat"

if exist "%FIREBASE_SETUP_SCRIPT%" (
    call "%FIREBASE_SETUP_SCRIPT%" "%FLAVOR%" "android"

    if %errorlevel% equ 0 (
        call :log_success "Debug symbols uploaded successfully!"
    ) else (
        call :log_warning "Debug symbols upload failed, but APK build was successful."
        echo You can manually upload later with: %FIREBASE_SETUP_SCRIPT% %FLAVOR% android
    )
) else (
    call :log_warning "Firebase setup script not found at: %FIREBASE_SETUP_SCRIPT%"
    echo Debug symbols were not uploaded automatically.
)

REM Open the folder in Explorer
echo.
call :log_step "Opening APK output folder..."
start explorer "%APK_OUTPUT_PATH%"

REM Display build summary
echo.
call :log_success "Build completed successfully!"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo App: %APP_NAME%
echo Package: %PACKAGE_NAME%
echo Flavor: %FLAVOR%
echo Output: %APK_OUTPUT_PATH%
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REM Distribute to Firebase App Distribution if requested
if "%DISTRIBUTE%"=="true" (
    echo.
    call :log_step "Distributing to Firebase App Distribution..."

    REM Prepare distribution command
    set "DIST_CMD=%~dp0..\distribution\distribute_android.bat apk %FLAVOR%"

    REM Add custom group if specified
    if "%DISTRIBUTION_GROUP%" neq "" (
        set "FIREBASE_DISTRIBUTION_GROUP=%DISTRIBUTION_GROUP%"
    )

    REM Add custom testers if specified
    if "%DISTRIBUTION_TESTERS%" neq "" (
        set "FIREBASE_DISTRIBUTION_TESTERS=%DISTRIBUTION_TESTERS%"
    )

    REM Execute distribution
    call %DIST_CMD%
    if %errorlevel% equ 0 (
        call :log_success "APK distributed to Firebase App Distribution!"
    ) else (
        call :log_warning "Distribution failed but APK build was successful"
    )
)

:end
endlocal

REM Pause for user removed for automation
