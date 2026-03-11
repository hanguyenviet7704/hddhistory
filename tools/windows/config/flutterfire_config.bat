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
set "FLAVORS="
set "RUN_ALL=false"
set "ARGS_PROVIDED=false"
set "PLATFORMS=android"
set "WITH_IOS_REQUESTED=false"
set "FLAVOR_COUNT=0"

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="all" (
    set "ARGS_PROVIDED=true"
    set "RUN_ALL=true"
    shift
    goto :parse_args
)
if "%~1"=="dev" (
    set "ARGS_PROVIDED=true"
    call :append_flavor "%~1"
    shift
    goto :parse_args
)
if "%~1"=="stg" (
    set "ARGS_PROVIDED=true"
    call :append_flavor "%~1"
    shift
    goto :parse_args
)
if "%~1"=="prod" (
    set "ARGS_PROVIDED=true"
    call :append_flavor "%~1"
    shift
    goto :parse_args
)
if "%~1"=="--with-ios" (
    set "WITH_IOS_REQUESTED=true"
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help

call :log_error "Unknown option: %~1"
echo Use -h or --help for usage information
exit /b 1

:show_help
echo Usage: %~nx0 [all^|dev^|stg^|prod ...]
echo.
echo Arguments:
echo   all               Configure all flavors ^(default when omitted^)
echo   dev^|stg^|prod    Configure one or more specific flavors
echo   --with-ios       Ignored on Windows ^(iOS setup requires macOS^)
echo   -h, --help      Show this help message
echo.
echo This script uses centralized configuration from .info\ directory.
echo.
echo Examples:
echo   %~nx0                      Configure Firebase for all flavors (Android only)
echo   %~nx0 dev stg              Configure Firebase for multiple flavors
echo   %~nx0 prod                 Configure Firebase for one flavor
exit /b 0

:args_done

REM Validate environment and parameters
call :validate_environment
if %errorlevel% neq 0 exit /b 1

if /i "%RUN_ALL%"=="true" (
    set "FLAVORS=dev stg prod"
)

if "%FLAVORS%"=="" (
    set "FLAVORS=dev stg prod"
    if /i "%ARGS_PROVIDED%"=="false" (
        call :log_info "No flavor specified. Defaulting to all flavors: %FLAVORS%"
    )
)

if /i "%WITH_IOS_REQUESTED%"=="true" (
    call :log_warning "Ignoring --with-ios on Windows. iOS setup requires macOS."
)

call :ensure_flutterfire_cli
if %errorlevel% neq 0 exit /b 1

for %%f in (%FLAVORS%) do (
    call :validate_flavor "%%f"
    if !errorlevel! neq 0 exit /b 1
)

for %%f in (%FLAVORS%) do (
    call :configure_flavor "%%f"
    if !errorlevel! neq 0 exit /b 1
)

echo.
for %%f in (%FLAVORS%) do set "LAST_FLAVOR=%%f"
for %%f in (%FLAVORS%) do set /a FLAVOR_COUNT+=1
if %FLAVOR_COUNT% gtr 1 (
    call :log_success "Firebase configuration completed for flavors: %FLAVORS%"
) else (
    call :log_success "Firebase configuration completed for flavor: %LAST_FLAVOR%"
)

exit /b 0

:append_flavor
set "candidate=%~1"
if "%FLAVORS%"=="" (
    set "FLAVORS=%candidate%"
) else (
    echo %FLAVORS% | findstr /i /c:"%candidate%" >nul
    if errorlevel 1 (
        set "FLAVORS=%FLAVORS% %candidate%"
    )
)
exit /b 0

:ensure_flutterfire_cli
where flutterfire >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "FlutterFire CLI not found"
    call :log_error "Please install it with: dart pub global activate flutterfire_cli"
    exit /b 1
)
exit /b 0

:configure_flavor
set "FLAVOR=%~1"
call :get_android_package_name "%FLAVOR%" ANDROID_PACKAGE
call :get_firebase_project_id "%FLAVOR%" FIREBASE_PROJECT

call :log_step "Configuring Firebase for %FLAVOR% environment"
echo Firebase Project: %FIREBASE_PROJECT%
echo Android Package: %ANDROID_PACKAGE%
echo Platforms: android
echo.

REM Execute FlutterFire configuration
call :log_info "Running FlutterFire configuration..."

flutterfire config ^
    --yes ^
    --overwrite-firebase-options ^
    --project=%FIREBASE_PROJECT% ^
    --out=lib/config/services/firebase/firebase_options_%FLAVOR%.dart ^
    --android-package-name=%ANDROID_PACKAGE% ^
    --android-out=android/app/src/%FLAVOR%/google-services.json ^
    --platforms=android

if %errorlevel% neq 0 (
    call :log_error "Firebase configuration for %FLAVOR% failed"
    exit /b 1
)

call :log_success "🎉 Firebase configuration for %FLAVOR% completed successfully!"
echo.
call :log_info "Generated files:"
call :log_info "  • Android: android/app/src/%FLAVOR%/google-services.json"
call :log_info "  • Flutter: lib/config/services/firebase/firebase_options_%FLAVOR%.dart"
call :log_info "  • Platform: Android only"

exit /b 0
