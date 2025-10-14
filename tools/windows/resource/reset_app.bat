@echo off
setlocal enabledelayedexpansion

REM Enhanced Flutter Reset Script with Centralized Configuration
REM This script resets Flutter project using configuration from .info\ directory

REM Navigate to the root directory relative to the current script location
set "ROOT_DIR=%~dp0..\..\.."
cd /d "%ROOT_DIR%"
if %errorlevel% neq 0 (
    echo ❌ Failed to navigate to the project root directory.
    goto :end
)

REM Load common configuration functions
call "%ROOT_DIR%\tools\windows\common\common.bat"
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
exit /b 1

:show_help
echo Usage: %~nx0 [--help]
echo.
echo This script cleans and resets the Flutter project:
echo   • Removes build directory
echo   • Runs flutter clean
echo   • Runs flutter pub get
echo   • Optionally runs build_runner clean and build
echo.
echo Options:
echo   -h, --help           Show this help message
echo.
echo This script uses centralized configuration from .info\ directory.
exit /b 0

:args_done

REM Get Flutter command from configuration
call :get_flutter_command
set "FLUTTER_CMD=%FLUTTER_COMMAND%"

call :get_app_name
set "APP_NAME=%APP_NAME_VALUE%"

call :log_info "🔄 Resetting Flutter project: %APP_NAME%"

REM Validate environment (just check Flutter, not all dependencies)
call :log_step "Validating Flutter environment..."
where flutter >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "Flutter is not installed or not added to PATH."
    call :log_info "Please ensure that Flutter is installed and added to your system PATH."
    exit /b 1
)

REM Show Flutter version
for /f "delims=" %%i in ('flutter --version 2^>nul ^| findstr "Flutter"') do (
    call :log_success "Flutter found: %%i"
)

REM Clean the Flutter project
call :log_step "Cleaning Flutter project..."

REM Remove build directories
call :log_info "Removing build directories..."
if exist "%ROOT_DIR%\build" rd /s /q "%ROOT_DIR%\build" 2>nul
if exist "%ROOT_DIR%\.dart_tool" rd /s /q "%ROOT_DIR%\.dart_tool" 2>nul
if exist "%ROOT_DIR%\android\.gradle" rd /s /q "%ROOT_DIR%\android\.gradle" 2>nul
if exist "%ROOT_DIR%\ios\.symlinks" rd /s /q "%ROOT_DIR%\ios\.symlinks" 2>nul
if exist "%ROOT_DIR%\ios\Pods" rd /s /q "%ROOT_DIR%\ios\Pods" 2>nul

REM Print and execute Flutter clean command
echo.
call :log_step "Executing clean command:"
echo Command: %FLUTTER_CMD% clean
echo.

call %FLUTTER_CMD% clean

if %errorlevel% neq 0 (
    call :log_error "Flutter clean failed."
    exit /b 1
)

call :log_success "Project cleaned successfully."

REM Get Flutter dependencies (pub get)
call :log_step "Fetching Flutter packages..."

REM Print and execute pub get command
echo.
call :log_step "Executing pub get command:"
echo Command: %FLUTTER_CMD% pub get
echo.

call %FLUTTER_CMD% pub get

if %errorlevel% neq 0 (
    call :log_error "Flutter pub get failed."
    exit /b 1
)

call :log_success "Dependencies fetched successfully."

REM Clean and regenerate build_runner generated files
call :log_step "Cleaning and regenerating build_runner files..."

REM Print and execute build_runner commands
echo.
call :log_step "Executing build_runner commands:"
echo Command: %FLUTTER_CMD% pub run build_runner clean
echo Command: %FLUTTER_CMD% pub run build_runner build --delete-conflicting-outputs
echo.

call %FLUTTER_CMD% pub run build_runner clean
call %FLUTTER_CMD% pub run build_runner build --delete-conflicting-outputs

if %errorlevel% neq 0 (
    call :log_warning "Build runner failed, but project reset was successful."
) else (
    call :log_success "Build runner files regenerated successfully."
)

REM Final success message
echo.
call :log_success "🎉 Flutter project reset completed successfully!"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo Project: %APP_NAME%
echo Actions completed:
echo   ✅ Build directories cleaned
echo   ✅ Flutter clean executed
echo   ✅ Dependencies refreshed
echo   ✅ Generated code refreshed
echo.
echo Your project is now ready for development!
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

:end
endlocal

REM Pause for user removed for automation
