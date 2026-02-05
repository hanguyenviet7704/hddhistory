@echo off
setlocal enabledelayedexpansion

REM Enhanced Universal Distribution Script for Windows
REM Firebase App Distribution - Universal Tool (Android Only)

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

REM Function to show usage
:show_usage
echo 🚀 Firebase App Distribution - Universal Tool (Windows)
echo.
echo Usage: %~nx0 [platform] [build_type] [flavor] [options]
echo.
echo Arguments:
echo   platform:     android (iOS not supported on Windows)
echo   build_type:   apk, appbundle, or both
echo   flavor:       dev, stg, or prod
echo.
echo Options:
echo   build_first   Build before distributing
echo   file_path     Specific path to build file (for single file distribution)
echo.
echo Examples:
echo   %~nx0 android apk dev build_first          # Build and distribute APK for dev
echo   %~nx0 android appbundle prod               # Distribute existing App Bundle for prod
echo   %~nx0 android both stg build_first         # Build and distribute all formats for staging
echo   %~nx0 android appbundle dev path\to.aab    # Distribute specific App Bundle
echo.
echo This script uses centralized configuration from .info\ directory.
goto :end

REM Initialize variables
set "PLATFORM="
set "BUILD_TYPE="
set "FLAVOR="
set "BUILD_FIRST=false"
set "SPECIFIC_FILE="

REM Parse arguments
:parse_args
if "%~1"=="" goto :args_done

if "%~1"=="android" (
    set "PLATFORM=%~1"
    shift
    goto :parse_args
)
if "%~1"=="apk" (
    set "BUILD_TYPE=%~1"
    shift
    goto :parse_args
)
if "%~1"=="appbundle" (
    set "BUILD_TYPE=%~1"
    shift
    goto :parse_args
)
if "%~1"=="both" (
    if "%BUILD_TYPE%"=="" (
        set "BUILD_TYPE=%~1"
    )
    shift
    goto :parse_args
)
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
if "%~1"=="build_first" (
    set "BUILD_FIRST=true"
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_usage
if "%~1"=="--help" goto :show_usage

REM If we get here, assume it's a file path
if exist "%~1" (
    set "SPECIFIC_FILE=%~1"
    shift
    goto :parse_args
)

call :log_error "Unknown argument: %~1"
goto :show_usage

:args_done

REM Validate required parameters
if "%PLATFORM%"=="" (
    call :log_error "Platform is required"
    goto :show_usage
)

if "%PLATFORM%" neq "android" (
    call :log_error "Only 'android' platform is supported on Windows"
    goto :show_usage
)

if "%BUILD_TYPE%"=="" (
    call :log_error "Build type is required"
    goto :show_usage
)

if "%FLAVOR%"=="" (
    call :log_error "Flavor is required"
    goto :show_usage
)

REM Validate environment
call :validate_environment
if %errorlevel% neq 0 goto :end

call :validate_flavor "%FLAVOR%"
if %errorlevel% neq 0 goto :end

REM Show configuration summary
call :show_config_summary "%FLAVOR%" "%PLATFORM%"

REM Main distribution logic
call :log_step "Starting distribution process..."
echo Platform: %PLATFORM%
echo Build Type: %BUILD_TYPE%
echo Flavor: %FLAVOR%
echo Build First: %BUILD_FIRST%
if "%SPECIFIC_FILE%" neq "" echo Specific File: %SPECIFIC_FILE%
echo.

REM Build first if requested
if "%BUILD_FIRST%"=="true" (
    call :log_step "Building before distribution..."

    if "%BUILD_TYPE%"=="apk" (
        call "%SCRIPT_DIR%..\build\build_apk.bat" "%FLAVOR%"
        if %errorlevel% neq 0 (
            call :log_error "APK build failed"
            goto :end
        )
    ) else if "%BUILD_TYPE%"=="appbundle" (
        call "%SCRIPT_DIR%..\build\build_appbundle.bat" "%FLAVOR%"
        if %errorlevel% neq 0 (
            call :log_error "App Bundle build failed"
            goto :end
        )
    ) else if "%BUILD_TYPE%"=="both" (
        call "%SCRIPT_DIR%..\build\build_apk.bat" "%FLAVOR%"
        if %errorlevel% neq 0 (
            call :log_error "APK build failed"
            goto :end
        )

        call "%SCRIPT_DIR%..\build\build_appbundle.bat" "%FLAVOR%"
        if %errorlevel% neq 0 (
            call :log_error "App Bundle build failed"
            goto :end
        )
    )

    call :log_success "Build completed successfully"
    echo.
)

REM Distribute based on build type
if "%SPECIFIC_FILE%" neq "" (
    call :log_step "Distributing specific file: %SPECIFIC_FILE%"
    REM Determine file type from extension
    if /i "%SPECIFIC_FILE:~-4%"==".apk" (
        call "%SCRIPT_DIR%\distribute_android.bat" apk "%FLAVOR%" --file "%SPECIFIC_FILE%"
    ) else if /i "%SPECIFIC_FILE:~-4%"==".aab" (
        call "%SCRIPT_DIR%\distribute_android.bat" aab "%FLAVOR%" --file "%SPECIFIC_FILE%"
    ) else (
        call :log_error "Unsupported file type. Only .apk and .aab files are supported."
        goto :end
    )
) else (
    if "%BUILD_TYPE%"=="apk" (
        call :log_step "Distributing APK..."
        call "%SCRIPT_DIR%\distribute_android.bat" apk "%FLAVOR%"
        if %errorlevel% neq 0 (
            call :log_error "APK distribution failed"
            goto :end
        )
    ) else if "%BUILD_TYPE%"=="appbundle" (
        call :log_step "Distributing App Bundle..."
        call "%SCRIPT_DIR%\distribute_android.bat" aab "%FLAVOR%"
        if %errorlevel% neq 0 (
            call :log_error "App Bundle distribution failed"
            goto :end
        )
    ) else if "%BUILD_TYPE%"=="both" (
        call :log_step "Distributing APK..."
        call "%SCRIPT_DIR%\distribute_android.bat" apk "%FLAVOR%"
        if %errorlevel% neq 0 (
            call :log_warning "APK distribution failed, continuing with App Bundle..."
        ) else (
            call :log_success "APK distributed successfully"
        )

        echo.
        call :log_step "Distributing App Bundle..."
        call "%SCRIPT_DIR%\distribute_android.bat" aab "%FLAVOR%"
        if %errorlevel% neq 0 (
            call :log_error "App Bundle distribution failed"
            goto :end
        )
    )
)

call :log_success "🎉 Distribution completed successfully!"
echo.
echo All distribution tasks have been completed.
echo Check Firebase App Distribution console for details.

:end
endlocal

REM Pause for user removed for automation