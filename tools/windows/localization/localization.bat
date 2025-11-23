@echo off
setlocal enabledelayedexpansion

REM Localization orchestrator (Windows) – config-driven wrapper around localization_cli.py

set "SCRIPT_DIR=%~dp0"
set "LCOMMON=%SCRIPT_DIR%localization_common.bat"
set "WCOMMON=%SCRIPT_DIR%..\\common\\common.bat"
for %%i in ("%SCRIPT_DIR%..\\..\\..") do set "PROJECT_ROOT=%%~fi"

call :parse_action %*
if %errorlevel% neq 0 exit /b %errorlevel%
if not "%~1"=="" shift

cd /d "%PROJECT_ROOT%"

call "%LCOMMON%" :validate_environment
if %errorlevel% neq 0 exit /b 1
call "%LCOMMON%" :validate_localization_config
if %errorlevel% neq 0 exit /b 1

REM Seed service account env vars from config if unset
call "%LCOMMON%" :get_localization_sa_path sa_path
call "%LCOMMON%" :get_localization_sa_path_env sa_env
call "%LCOMMON%" :get_localization_sa_json_env sa_json_env
if not "%sa_path%"=="" (
    call set "sa_env_val=%%%sa_env%%%"
    if "%sa_env_val%"=="" (
        set "%sa_env%=%sa_path%"
    )
)

call "%LCOMMON%" :log_info "Localization action: %ACTION%"
call "%LCOMMON%" :show_localization_config

REM Fast path: slang generation (uses flutter command that respects fvm/puro if configured)
if /I "%ACTION%"=="slang" (
    call "%WCOMMON%" :get_flutter_command FLUTTER_CMD
    call "%LCOMMON%" :log_step "Running slang generator..."
    %FLUTTER_CMD% pub run slang %*
    endlocal & exit /b %ERRORLEVEL%
)

REM Ensure Python + venv
where python >nul 2>&1
if %errorlevel% neq 0 (
    call "%LCOMMON%" :log_error "Python 3 is required."
    exit /b 1
)

set "VENV_DIR=%PROJECT_ROOT%\.venv_localization"
if not exist "%VENV_DIR%" (
    call "%LCOMMON%" :log_warning "Creating virtual environment at %VENV_DIR%"
    python -m venv "%VENV_DIR%"
)

call "%LCOMMON%" :log_step "Activating virtual environment..."
call "%VENV_DIR%\Scripts\activate.bat"
if %errorlevel% neq 0 (
    call "%LCOMMON%" :log_error "Failed to activate virtual environment"
    exit /b 1
)

set "REQ_FILE=%SCRIPT_DIR%requirements.txt"
if exist "%REQ_FILE%" (
    for /f "skip=1 tokens=1" %%h in ('certutil -hashfile "%REQ_FILE%" MD5 ^| findstr /R "^[0-9A-F]"') do set "REQ_HASH=%%h"
    set "DEPS_STAMP=%VENV_DIR%\.deps_hash"
    set "CURRENT_HASH="
    if exist "%DEPS_STAMP%" set /p CURRENT_HASH=<"%DEPS_STAMP%"
    if /I not "%REQ_HASH%"=="%CURRENT_HASH%" (
        call "%LCOMMON%" :log_step "Ensuring Python dependencies..."
        pip install --upgrade pip >nul
        pip install -r "%REQ_FILE%" >nul
        echo %REQ_HASH% > "%DEPS_STAMP%"
    ) else (
        call "%LCOMMON%" :log_info "Dependencies already satisfied (cached)."
    )
)

call "%LCOMMON%" :create_python_config PYTHON_CONFIG
call "%LCOMMON%" :log_info "Using generated config: %PYTHON_CONFIG%"

python "%SCRIPT_DIR%localization_cli.py" --config "%PYTHON_CONFIG%" %ACTION% %*
set "EXIT_CODE=%ERRORLEVEL%"

del /f "%PYTHON_CONFIG%" >nul 2>&1
call "%VENV_DIR%\Scripts\deactivate.bat" >nul 2>&1

endlocal & exit /b %EXIT_CODE%

:parse_action
set "ACTION=pull"
if "%~1"=="" goto :eof
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help
if /I "%~1"=="pull"      (set "ACTION=pull" & goto :eof)
if /I "%~1"=="migrate"   (set "ACTION=migrate" & goto :eof)
if /I "%~1"=="push"      (set "ACTION=push" & goto :eof)
if /I "%~1"=="validate"  (set "ACTION=validate" & goto :eof)
if /I "%~1"=="slang"     (set "ACTION=slang" & goto :eof)
call "%LCOMMON%" :log_error "Unknown action: %~1"
call :show_help
exit /b 1

:show_help
echo Usage: localization.bat [pull^|migrate^|push^|validate^|slang] [options]
echo.
echo Commands:
echo   pull                      Fetch active sheet -^> YAML + records.json
echo   migrate [--source sheet^|arb] [--apply]
echo                             Import legacy sheet/ARB -^> YAML (optionally push)
echo   push [--apply]            Push records.json to active sheet (dry-run by default)
echo   validate                  Validate local records.json
echo   slang                     Run slang generator (flutter pub run slang)
echo.
echo Examples:
echo   localization.bat pull
echo   localization.bat migrate --source sheet --apply
echo   localization.bat push --apply
echo   localization.bat validate
echo   localization.bat slang
exit /b 0
