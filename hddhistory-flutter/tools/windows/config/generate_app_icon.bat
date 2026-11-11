@echo off
setlocal enabledelayedexpansion

REM Enhanced App Icon Generation Script with Centralized Configuration (Windows)
REM This script generates app icons for all platforms using configuration from .info\ directory

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

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help

call :log_error "Unknown option: %~1"
echo Use -h or --help for usage information
goto :end

:show_help
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   -h, --help    Show this help message
echo.
echo This script generates app icons for all platforms.
echo Configuration is read from flutter_launcher_icons.yaml
echo.
echo Prerequisites:
echo   - flutter_launcher_icons package in pubspec.yaml
echo   - flutter_launcher_icons.yaml configuration file
echo   - Icon source file specified in configuration
goto :end

:args_done

REM Validate environment
call :validate_environment
if %errorlevel% neq 0 goto :end

REM Get configuration from centralized system
call :get_app_name APP_NAME
call :get_flutter_command FLUTTER_CMD

call :log_step "Generating app icons for %APP_NAME%"
echo Flutter Command: %FLUTTER_CMD%
echo.

REM Check if flutter_launcher_icons.yaml exists
if not exist "flutter_launcher_icons.yaml" (
    call :log_error "flutter_launcher_icons.yaml not found"
    call :log_error "Please create a flutter_launcher_icons.yaml configuration file"
    call :log_info "Example configuration can be found in the documentation"
    goto :end
)

call :log_success "Found flutter_launcher_icons.yaml configuration"

REM Check if the package is available
call :log_step "Checking flutter_launcher_icons package..."
dart pub deps | findstr flutter_launcher_icons >nul 2>&1
if %errorlevel% neq 0 (
    call :log_warning "flutter_launcher_icons package not found in dependencies"
    call :log_info "Attempting to activate globally..."
    dart pub global activate flutter_launcher_icons
    if !errorlevel! neq 0 (
        call :log_error "Failed to activate flutter_launcher_icons package"
        call :log_error "Please add it to pubspec.yaml or install globally"
        goto :end
    )
)

REM Run the flutter_launcher_icons command
call :log_step "Running flutter_launcher_icons..."
dart run flutter_launcher_icons

if %errorlevel% neq 0 (
    call :log_error "flutter_launcher_icons command failed"
    call :log_error "Please check your configuration and icon source file"
    goto :end
)

call :log_success "🎉 App icon generation completed successfully!"
echo.
call :log_info "Generated icons for all configured platforms"
call :log_info "Icons are now ready for %APP_NAME%"

:end
endlocal

REM Wait for a key press before closing
echo.
echo Press any key to close this window...
pause >nul
