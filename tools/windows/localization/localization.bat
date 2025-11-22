@echo off
setlocal enabledelayedexpansion

REM Entry point for localization tooling (Sheets ⇄ slang) on Windows

set "SCRIPT_DIR=%~dp0"
set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=pull"
if not "%~1"=="" shift
set "LCOMMON=%SCRIPT_DIR%localization_common.bat"
for %%i in ("%SCRIPT_DIR%..\\..\\..") do set "PROJECT_ROOT=%%~fi"

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
