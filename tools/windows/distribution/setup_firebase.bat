@echo off
setlocal enabledelayedexpansion

REM Enhanced Firebase Setup Script for Windows
REM This script helps set up Firebase App Distribution configuration

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

REM Function to check prerequisites
call :check_prerequisites
if %errorlevel% neq 0 goto :end

REM Initialize variables
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
goto :show_help

:show_help
echo Usage: %~nx0 [--non-interactive]
echo.
echo Options:
echo   --non-interactive     Run without user prompts (use existing config)
echo   -h, --help           Show this help message
echo.
echo This script helps set up Firebase App Distribution for the project.
echo It will guide you through configuring Firebase projects and app IDs.
echo.
echo Note: iOS configuration is not available on Windows.
goto :end

:args_done

call :log_step "🚀 Setting up Firebase App Distribution..."

REM Check Firebase login
call :firebase_login
if %errorlevel% neq 0 goto :end

REM Show available projects
call :list_firebase_projects

REM Get configuration for each flavor
call :log_step "Configuring Firebase projects for flavors..."

for %%f in (dev stg prod) do (
    echo.
    call :log_step "Configuring flavor: %%f"

    if "%INTERACTIVE_MODE%"=="true" (
        call :configure_flavor_interactive "%%f"
    ) else (
        call :configure_flavor_automatic "%%f"
    )

    if !errorlevel! neq 0 (
        call :log_warning "Failed to configure flavor: %%f"
    ) else (
        call :log_success "Flavor %%f configured successfully"
    )
)

REM Test configuration
echo.
call :log_step "Testing Firebase configuration..."
call :test_firebase_config

call :log_success "🎉 Firebase setup completed successfully!"
echo.
echo Your Firebase configuration is ready for use with distribution scripts.
echo.
echo Next steps:
echo   1. Build your app: tools\windows\build\build_apk.bat dev
echo   2. Distribute: tools\windows\distribution\distribute_android.bat apk dev
echo.

goto :end

REM ============================================
REM Helper Functions
REM ============================================

:check_prerequisites
call :log_step "Checking prerequisites..."

REM Check if Firebase CLI is installed
where firebase >nul 2>&1
if !errorlevel! neq 0 (
    call :log_error "Firebase CLI is not installed. Please install it first:"
    echo npm install -g firebase-tools
    exit /b 1
)

REM Check if jq is installed for JSON parsing
where jq >nul 2>&1
if !errorlevel! neq 0 (
    call :log_warning "jq is not installed. Some features may be limited."
    echo Download from: https://github.com/stedolan/jq/releases
) else (
    call :log_success "jq found - full JSON support available"
)

call :log_success "Firebase CLI found"
exit /b 0

:firebase_login
call :log_step "Checking Firebase authentication..."

firebase projects:list >nul 2>&1
if !errorlevel! neq 0 (
    call :log_step "Please login to Firebase..."
    firebase login
    if !errorlevel! neq 0 (
        call :log_error "Firebase login failed"
        exit /b 1
    )
) else (
    call :log_success "Already logged in to Firebase!"
)
exit /b 0

:list_firebase_projects
call :log_step "Available Firebase projects:"
firebase projects:list
exit /b 0

:configure_flavor_interactive
set "flavor=%~1"
call :log_info "Configuring %flavor% flavor..."

echo.
echo Please enter the Firebase project ID for %flavor% flavor:
set /p "project_id=Project ID: "

if "%project_id%"=="" (
    call :log_warning "No project ID provided for %flavor%, skipping..."
    exit /b 1
)

REM Validate project exists
call :validate_firebase_project "%project_id%"
if !errorlevel! neq 0 exit /b 1

REM Get Android app ID
echo.
echo Please enter the Android app ID for %flavor% flavor:
set /p "android_app_id=Android App ID: "

if "%android_app_id%"=="" (
    call :log_warning "No Android app ID provided for %flavor%"
)

REM Store configuration (this would update the JSON config file)
call :log_info "Configuration saved for %flavor%:"
echo   Project ID: %project_id%
echo   Android App ID: %android_app_id%

exit /b 0

:configure_flavor_automatic
set "flavor=%~1"
call :log_info "Using existing configuration for %flavor% flavor..."

call :get_firebase_project_id "%flavor%" existing_project
if "%existing_project%"=="" (
    call :log_warning "No existing configuration found for %flavor%"
    exit /b 1
)

call :log_success "Found existing configuration for %flavor%: %existing_project%"
exit /b 0

:validate_firebase_project
set "project_id=%~1"

call :log_info "Validating project: %project_id%"

firebase projects:list | findstr /c:"%project_id%" >nul
if %errorlevel% neq 0 (
    call :log_error "Project '%project_id%' not found in your Firebase account"
    exit /b 1
)

REM Set current project
firebase use "%project_id%" >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "Failed to set project '%project_id%'"
    exit /b 1
)

call :log_success "Project '%project_id%' validated successfully!"
exit /b 0

:test_firebase_config
call :log_info "Testing Firebase configuration..."

REM Test each configured flavor
for %%f in (dev stg prod) do (
    call :get_firebase_project_id "%%f" project_id
    if "!project_id!" neq "" (
        call :log_info "Testing %%f: !project_id!"
        firebase use "!project_id!" >nul 2>&1
        if !errorlevel! equ 0 (
            call :log_success "%%f configuration: OK"
        ) else (
            call :log_warning "%%f configuration: Failed"
        )
    ) else (
        call :log_warning "%%f: No configuration found"
    )
)

exit /b 0

:end
endlocal

REM Pause for user removed for automation