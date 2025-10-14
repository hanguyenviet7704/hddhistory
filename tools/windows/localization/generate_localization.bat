@echo off
setlocal enabledelayedexpansion

REM Enhanced Flutter Localization Generator with Centralized Configuration (Windows)
REM This script:
REM 1. Generates module-specific ARB files from Google Sheets
REM 2. Merges module ARB files into app ARB files
REM 3. Runs Flutter's localization generation

REM Parse command line arguments
set "INTERACTIVE=true"
set "SKIP_FLUTTER=false"

:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="--non-interactive" (
    set "INTERACTIVE=false"
    shift
    goto :parse_args
)
if "%~1"=="--skip-flutter" (
    set "SKIP_FLUTTER=true"
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
echo   --skip-flutter        Skip Flutter generation step
echo   -h, --help           Show this help message
echo.
echo This script uses centralized configuration from .info\ directory.
echo.
echo Examples:
echo   %~nx0                     Interactive mode with all steps
echo   %~nx0 --non-interactive   Automated mode
echo   %~nx0 --skip-flutter      Generate ARB files only
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

call :log_info "Flutter Localization Generator"
echo ================================
call :show_localization_config

REM Check if Python is installed
call :log_step "Checking Python availability..."
python --version >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "Python is not installed"
    call :log_error "Please install Python from: https://python.org"
    exit /b 1
)

REM Get Python version for logging
for /f "tokens=*" %%i in ('python --version 2^>^&1') do (
    call :log_success "Found Python: %%i"
)

REM Setup virtual environment
set "VENV_DIR=%PROJECT_ROOT%\.venv_localization"
if not exist "%VENV_DIR%" (
    call :log_warning "Creating virtual environment..."
    python -m venv "%VENV_DIR%"
)

REM Activate virtual environment
call :log_step "Activating virtual environment..."
call "%VENV_DIR%\Scripts\activate.bat"
if %errorlevel% neq 0 (
    call :log_error "Failed to activate virtual environment"
    exit /b 1
)

REM Check if required Python packages are installed
call :log_step "Checking Python dependencies..."
python -c "import requests" >nul 2>&1
if %errorlevel% neq 0 (
    call :log_warning "Installing requests package..."
    pip install requests
    if %errorlevel% neq 0 (
        call :log_error "Failed to install Python dependencies"
        exit /b 1
    )
)

call :log_success "Python dependencies are ready"

REM Create Python configuration file
call :create_python_config PYTHON_CONFIG
call :log_info "Created Python configuration: %PYTHON_CONFIG%"

REM Step 1: Generate module ARB files from Google Sheets
echo.
call :log_step "Step 1: Generating module ARB files from Google Sheets..."
python "%~dp0generate_arb_from_sheets.py" "%PYTHON_CONFIG%"
if %errorlevel% neq 0 (
    call :log_error "Failed to generate ARB files from Google Sheets"
    del /f "%PYTHON_CONFIG%" >nul 2>&1
    call "%VENV_DIR%\Scripts\deactivate.bat"
    exit /b 1
)

call :log_success "Module ARB files generated successfully"

REM Step 2: Merge module ARB files into app ARB files
echo.
call :log_step "Step 2: Merging module ARB files..."
python "%~dp0merge_arb_files.py" "%PYTHON_CONFIG%"
if %errorlevel% neq 0 (
    call :log_error "Failed to merge ARB files"
    del /f "%PYTHON_CONFIG%" >nul 2>&1
    call "%VENV_DIR%\Scripts\deactivate.bat"
    exit /b 1
)

call :log_success "ARB files merged successfully"

REM Step 3: Run Flutter localization generation
echo.
if "%SKIP_FLUTTER%"=="true" (
    call :log_warning "Skipping Flutter generation step (--skip-flutter flag used)"
) else (
    call :log_step "Step 3: Running Flutter localization generation..."

    REM Get Flutter command from configuration
    call :get_flutter_command FLUTTER_CMD
    call :log_info "Using Flutter command: %FLUTTER_CMD%"

    REM Validate Flutter availability
    where flutter >nul 2>&1
    if %errorlevel% neq 0 (
        call :log_warning "Flutter command not found in PATH"
        if "%INTERACTIVE%"=="true" (
            echo Please specify the path to Flutter manually:
            echo 1^ Enter the full path to the flutter command
            echo 2^ Type 'skip' to skip Flutter generation
            echo 3^ Press Enter to try with 'flutter' anyway
            set /p "FLUTTER_INPUT=> "

            if "!FLUTTER_INPUT!"=="skip" (
                call :log_warning "Skipping Flutter generation step..."
                set "FLUTTER_CMD="
            ) else if not "!FLUTTER_INPUT!"=="" (
                where "!FLUTTER_INPUT!" >nul 2>&1
                if !errorlevel! equ 0 (
                    set "FLUTTER_CMD=!FLUTTER_INPUT!"
                ) else (
                    call :log_error "Specified path is not valid or not found"
                    echo Skipping Flutter generation step...
                    set "FLUTTER_CMD="
                )
            )
        ) else (
            call :log_warning "Non-interactive mode: skipping Flutter generation"
            set "FLUTTER_CMD="
        )
    )

    if not "%FLUTTER_CMD%"=="" (
        call :log_step "Generating Flutter localization files with: %FLUTTER_CMD%"
        %FLUTTER_CMD% gen-l10n
        if %errorlevel% equ 0 (
            call :log_success "Flutter localization files generated successfully"
        ) else (
            call :log_error "Flutter localization generation failed"
            del /f "%PYTHON_CONFIG%" >nul 2>&1
            call "%VENV_DIR%\Scripts\deactivate.bat"
            exit /b 1
        )
    ) else (
        call :log_warning "Flutter localization files were not generated."
        echo You will need to run 'flutter gen-l10n' manually to complete the process.
    )
)

REM Cleanup
del /f "%PYTHON_CONFIG%" >nul 2>&1
call "%VENV_DIR%\Scripts\deactivate.bat"

echo.
call :log_success "🎉 Localization generation completed successfully!"
echo.
call :log_info "📂 Generated files:"

call :get_module_dir module_dir
echo   • Module ARB files: %module_dir%

call :get_app_dir app_dir
echo   • App ARB files: %app_dir%

if not "%FLUTTER_CMD%"=="" (
    call :get_l10n_output_dir output_dir
    echo   • Dart localization files: %output_dir%
) else (
    echo   • Dart localization files: Not generated ^(run 'flutter gen-l10n' manually^)
)

echo.
call :log_info "📚 Documentation:"
echo   • Flutter Internationalization: https://docs.flutter.dev/development/accessibility-and-localization/internationalization
echo   • ARB File Format: https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification

REM Pause for user removed for automation

endlocal
exit /b 0 