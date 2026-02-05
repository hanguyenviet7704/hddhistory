@echo off
setlocal enabledelayedexpansion

REM Tracking helper (Windows) - run app and filter tracking logs

REM Navigate to project root
set "ROOT_DIR=%~dp0..\..\..\"
cd /d "%ROOT_DIR%"
if %errorlevel% neq 0 (
    echo Failed to navigate to the project root directory.
    goto :end
)

REM Load common configuration functions
call "%~dp0\..\common\common.bat"
if %errorlevel% neq 0 (
    echo Failed to load common configuration library.
    goto :end
)

set "ACTION=run"
set "FOLLOW=0"
set "RAW=0"
set "DEVICE="
set "FLAVOR="
set "TARGET="
set "ENV_FILE="

if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help
if "%~1"=="run" (
    set "ACTION=run"
    shift
) else if "%~1"=="logs" (
    set "ACTION=logs"
    shift
) else if "%~1"=="devices" (
    set "ACTION=devices"
    shift
) else if "%~1"=="clear" (
    set "ACTION=clear"
    shift
)

:parse_args
if "%~1"=="" goto :args_done
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
if "%~1"=="--device" (
    set "DEVICE=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--target" (
    set "TARGET=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--env" (
    set "ENV_FILE=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--follow" (
    set "FOLLOW=1"
    shift
    goto :parse_args
)
if "%~1"=="--raw" (
    set "RAW=1"
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help

call :log_error "Unknown option: %~1"
call :show_help
goto :end

:show_help
echo Usage: %~nx0 [run^|logs^|devices^|clear] [options]
echo.
echo Commands:
echo   run dev^|stg^|prod [--device ^<id^>] [--target ^<path^>] [--env ^<path^>]
echo       Run the app with flavor and env file.
echo   logs [--device ^<id^>] [--follow] [--raw]
echo       Show tracking logs from adb (Android).
echo   devices
echo       List connected adb devices.
echo   clear [--device ^<id^>]
echo       Clear adb logcat buffer.
echo.
echo Options:
echo   --device ^<id^>   adb device id (optional)
echo   --target ^<path^> Flutter target (default: lib/main_%%FLAVOR%%.dart)
echo   --env ^<path^>    Env file path (default from .info paths config)
echo   --follow        Stream logs (default: one-time dump)
echo   --raw           Do not filter by [Tracking]
echo   -h, --help      Show this help
echo.
echo Examples:
echo   %~nx0 run prod --device R58M35FT1NR
echo   %~nx0 logs --device R58M35FT1NR --follow
goto :end

:args_done

REM Handle non-run actions
if "%ACTION%"=="devices" (
    where adb >nul 2>&1
    if errorlevel 1 (
        call :log_error "adb not found"
        goto :end
    )
    adb devices
    goto :end
)

if "%ACTION%"=="clear" (
    where adb >nul 2>&1
    if errorlevel 1 (
        call :log_error "adb not found"
        goto :end
    )
    if "%DEVICE%"=="" (
        adb logcat -c
    ) else (
        adb -s %DEVICE% logcat -c
    )
    call :log_info "logcat buffer cleared"
    goto :end
)

if "%ACTION%"=="logs" (
    where adb >nul 2>&1
    if errorlevel 1 (
        call :log_error "adb not found"
        goto :end
    )
    set "ADB_CMD=adb"
    if not "%DEVICE%"=="" set "ADB_CMD=adb -s %DEVICE%"

    if "%FOLLOW%"=="1" (
        if "%RAW%"=="1" (
            %ADB_CMD% logcat
        ) else (
            %ADB_CMD% logcat ^| findstr /c:"[Tracking]"
        )
    ) else (
        if "%RAW%"=="1" (
            %ADB_CMD% logcat -d
        ) else (
            %ADB_CMD% logcat -d ^| findstr /c:"[Tracking]"
        )
    )
    goto :end
)

REM Run action
if "%FLAVOR%"=="" (
    call :log_error "Missing flavor"
    call :show_help
    goto :end
)

call :validate_environment
if %errorlevel% neq 0 goto :end

call :validate_flavor "%FLAVOR%"
if %errorlevel% neq 0 goto :end

if "%ENV_FILE%"=="" (
    call :get_env_file_path "%FLAVOR%" ENV_FILE
)

if "%TARGET%"=="" (
    set "TARGET=lib\main_%FLAVOR%.dart"
    if not exist "%TARGET%" set "TARGET=lib\main.dart"
)

if not exist "%ENV_FILE%" (
    call :log_error "Environment file not found: %ENV_FILE%"
    goto :end
)

call :get_flutter_command FLUTTER_CMD
call :show_config_summary "%FLAVOR%" "android"

set "RUN_CMD=%FLUTTER_CMD% run --flavor %FLAVOR% --dart-define-from-file=\"%ENV_FILE%\" -t \"%TARGET%\""
if not "%DEVICE%"=="" set "RUN_CMD=%RUN_CMD% -d %DEVICE%"

echo Command: %RUN_CMD%
call %RUN_CMD%

:end
endlocal
