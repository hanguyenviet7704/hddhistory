@echo off
setlocal enabledelayedexpansion

REM Enhanced ARB File Cleanup Script with Centralized Configuration (Windows)
REM Script to clean up old ARB files after migration to module-based structure

REM Parse command line arguments
set "INTERACTIVE=true"

:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="--non-interactive" (
    set "INTERACTIVE=false"
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help

echo Unknown option: %~1
echo Use -h or --help for usage information
exit /b 1

:show_help
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   --non-interactive     Run without user prompts
echo   -h, --help           Show this help message
echo.
echo This script uses centralized configuration from .info\ directory.
echo.
echo Examples:
echo   %~nx0                     Interactive mode
echo   %~nx0 --non-interactive   Automated cleanup
exit /b 0

:args_done

REM Navigate to the root directory relative to the current script location
set "ROOT_DIR=%~dp0..\..\..\"
cd /d "%ROOT_DIR%"
if %errorlevel% neq 0 (
    echo ❌ Failed to navigate to the project root directory.
    exit /b 1
)

REM Load localization-specific configuration
call "%~dp0localization_common.bat"
if %errorlevel% neq 0 (
    echo ❌ Failed to load localization configuration
    exit /b 1
)

REM Validate environment and configuration
call :validate_environment
if %errorlevel% neq 0 exit /b 1

call :validate_localization_config
if %errorlevel% neq 0 exit /b 1

call :log_warning "ARB File Cleanup"
echo ==================
echo.

REM Get ARB directory from configuration
call :get_arb_dir ARB_DIR

REM Define files to remove (using configuration-based paths)
set "OLD_FILE_1=%ARB_DIR%\app_en.arb"
set "OLD_FILE_2=%ARB_DIR%\app_vn.arb"

echo This will remove the following old ARB files:
set "FILES_EXIST=false"

if exist "%OLD_FILE_1%" (
    echo   - %OLD_FILE_1%
    set "FILES_EXIST=true"
)

if exist "%OLD_FILE_2%" (
    echo   - %OLD_FILE_2%
    set "FILES_EXIST=true"
)

if "%FILES_EXIST%"=="false" (
    call :log_info "No old ARB files found to cleanup"
    echo.
    REM Pause for user removed for automation
    exit /b 0
)

echo.
if "%INTERACTIVE%"=="true" (
    set /p "CONFIRM=Are you sure you want to delete these files? (y/N): "
    if /i not "!CONFIRM!"=="y" (
        call :log_warning "Cleanup cancelled by user"
        REM Pause for user removed for automation
        exit /b 0
    )
) else (
    call :log_info "Non-interactive mode: proceeding with cleanup"
)

REM Remove files
if exist "%OLD_FILE_1%" (
    del "%OLD_FILE_1%" >nul 2>&1
    if %errorlevel% equ 0 (
        call :log_success "Removed: %OLD_FILE_1%"
    ) else (
        call :log_error "Failed to remove: %OLD_FILE_1%"
    )
) else (
    call :log_warning "File not found: %OLD_FILE_1%"
)

if exist "%OLD_FILE_2%" (
    del "%OLD_FILE_2%" >nul 2>&1
    if %errorlevel% equ 0 (
        call :log_success "Removed: %OLD_FILE_2%"
    ) else (
        call :log_error "Failed to remove: %OLD_FILE_2%"
    )
) else (
    call :log_warning "File not found: %OLD_FILE_2%"
)

echo.
call :log_success "🎉 Cleanup completed!"

echo.
call :log_info "📂 Cleanup Summary:"
echo   • Removed legacy ARB files from: %ARB_DIR%
echo   • Your current localization files remain in the module and app directories
echo.
call :log_info "📚 Next Steps:"
echo   • Run 'generate_localization.bat' to regenerate current localization files
echo   • Verify your app works correctly with the module-based structure

REM Pause for user removed for automation

endlocal
exit /b 0 