@echo off
setlocal enabledelayedexpansion

REM Project Setup Script - Configure new project with centralized configuration (Windows)
REM This script helps set up all necessary configurations for a new Flutter project

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

REM Configuration validation
set "INTERACTIVE_MODE=true"

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="--non-interactive" (
    set "INTERACTIVE_MODE=false"
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help

call :log_error "Unknown option: %~1"
echo Use -h or --help for usage information
exit /b 1

:show_help
echo Usage: %~nx0 [--non-interactive]
echo.
echo Arguments:
echo   --non-interactive     Run without user prompts (use existing config)
echo   -h, --help           Show this help message
echo.
echo This script sets up the project configuration from .info\ directory.
echo Note: iOS-specific setup is not available on Windows.
exit /b 0

:args_done

call :log_info "🚀 Starting project setup with centralized configuration (Windows)..."

REM Validate environment
call :validate_environment
if %errorlevel% neq 0 (
    call :log_error "Environment validation failed. Please check your configuration."
    exit /b 1
)

call :log_step "Project setup environment validation..."
call :log_success "Configuration files found and valid!"

REM Get basic project information
call :get_app_name APP_NAME
call :get_pubspec_version VERSION

echo.
call :log_step "Project Information"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo App Name: %APP_NAME%
echo Version: %VERSION%
echo Platform Support: Android only (iOS not supported on Windows)
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REM Check Flutter environment
call :log_step "Checking Flutter environment..."
call :get_flutter_command FLUTTER_CMD
where flutter >nul 2>&1
if %errorlevel% equ 0 (
    for /f "delims=" %%i in ('flutter --version 2^>nul ^| findstr "Flutter"') do (
        call :log_success "Flutter found: %%i"
    )
    if "%FLUTTER_CMD%"=="fvm flutter" (
        call :log_info "Using FVM for Flutter version management"
    )
) else (
    call :log_error "Flutter not found in PATH!"
    exit /b 1
)

REM Check for required tools
call :log_step "Checking required development tools..."
set "missing_tools=0"

REM Check for jq
where jq >nul 2>&1
if %errorlevel% neq 0 (
    call :log_warning "jq not found (JSON parsing will be limited)"
    set /a missing_tools+=1
)

REM Check for Firebase CLI
where firebase >nul 2>&1
if %errorlevel% neq 0 (
    call :log_warning "firebase-tools not found"
    set /a missing_tools+=1
)

if %missing_tools% equ 0 (
    call :log_success "All required tools are available!"
) else (
    call :log_warning "Some tools are missing but setup can continue"

    if "%INTERACTIVE_MODE%"=="true" (
        echo.
        set /p "CONTINUE=Would you like to continue anyway? (y/N) "
        if /i "!CONTINUE!" neq "y" (
            call :log_info "Setup cancelled by user."
            exit /b 0
        )
    )
)

REM Validate configuration for each flavor
call :log_step "Validating flavor configurations..."
for %%f in (dev stg prod) do (
    call :log_info "Checking %%f flavor..."

    REM Validate Android package name
    call :get_android_package_name "%%f" PACKAGE_NAME
    if "!PACKAGE_NAME!" neq "" if "!PACKAGE_NAME!" neq "null" (
        call :log_success "  Android package: !PACKAGE_NAME!"
    ) else (
        call :log_warning "  Android package name not configured for %%f"
    )

    REM Check environment file
    call :get_env_file_path "%%f" ENV_FILE
    if exist "!ENV_FILE!" (
        call :log_success "  Environment file: !ENV_FILE!"
    ) else (
        call :log_warning "  Environment file not found: !ENV_FILE!"
    )

    REM Check Firebase project
    call :get_firebase_project_id "%%f" FIREBASE_PROJECT
    if "!FIREBASE_PROJECT!" neq "" if "!FIREBASE_PROJECT!" neq "null" (
        call :log_success "  Firebase project: !FIREBASE_PROJECT!"
    ) else (
        call :log_warning "  Firebase project not configured for %%f"
    )
)

echo.
call :log_step "Setup Summary"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo ✅ Project configuration validated
echo ✅ Flutter environment ready
echo ✅ Windows development tools checked
echo ✅ Flavor configurations validated
echo.
echo 📱 Android: Ready for development
echo 🚫 iOS: Not supported on Windows platform
echo.
echo Next steps:
echo 1. Run 'flutter pub get' to fetch dependencies
echo 2. Use build scripts: tools\windows\build\build_apk.bat [flavor]
echo 3. Configure Firebase if not already done
echo 4. Test builds with different flavors
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

call :log_success "🎉 Project setup completed successfully!"

REM Optional: Run flutter pub get
if "%INTERACTIVE_MODE%"=="true" (
    echo.
    set /p "RUN_PUB_GET=Would you like to run 'flutter pub get' now? (Y/n) "
    if /i "!RUN_PUB_GET!" neq "n" (
        call :log_step "Running flutter pub get..."
        %FLUTTER_CMD% pub get

        if !errorlevel! equ 0 (
            call :log_success "Dependencies fetched successfully!"
        ) else (
            call :log_warning "Failed to fetch dependencies. You may need to run it manually."
        )
    )
)

echo.
echo Press any key to close this window...
pause >nul
exit /b 0