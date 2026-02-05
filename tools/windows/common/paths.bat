@echo off
REM Enhanced Common paths configuration for Windows Artlexis scripts
REM This file defines standard paths used across all scripts and integrates with centralized configuration
REM Usage: call "%~dp0\..\common\paths.bat"

setlocal enabledelayedexpansion

REM Determine script locations
set "CALLING_SCRIPT_DIR=%~dp0"
set "COMMON_DIR=%CALLING_SCRIPT_DIR%"

REM Define standard directory structure
REM COMMON_DIR is tools\windows\common, so go up two levels to get to tools
for %%i in ("%COMMON_DIR%\..\..") do set "TOOLS_DIR=%%~fi"

REM Use PROJECT_ROOT from common.bat if available, otherwise calculate ROOT_DIR
if defined PROJECT_ROOT (
    set "ROOT_DIR=%PROJECT_ROOT%"
) else (
    for %%i in ("%TOOLS_DIR%\..") do set "ROOT_DIR=%%~fi"
)

REM Platform-specific tools directories
set "MACOS_TOOLS_DIR=%TOOLS_DIR%\macos"
set "LINUX_TOOLS_DIR=%TOOLS_DIR%\linux"
set "WINDOWS_TOOLS_DIR=%TOOLS_DIR%\windows"

REM Functional directories (Windows specific)
set "BUILD_DIR=%WINDOWS_TOOLS_DIR%\build"
set "CONFIG_DIR=%WINDOWS_TOOLS_DIR%\config"
set "DISTRIBUTION_DIR=%WINDOWS_TOOLS_DIR%\distribution"
set "KEY_DIR=%WINDOWS_TOOLS_DIR%\key"

REM Load centralized configuration (only if not already loaded)
if not defined PROJECT_ROOT (
    if exist "%ROOT_DIR%\tools\windows\common\common.bat" (
        call "%ROOT_DIR%\tools\windows\common\common.bat"
    )
)

REM Set configuration file paths
if defined PROJECT_ROOT (
    REM Use paths from common.bat if available
    set "FIREBASE_INFO_FILE=%PROJECT_ROOT%\.info\app\firebase.json"
    set "APP_CONFIG_FILE=%PROJECT_ROOT%\.info\app\app.json"
    set "BUILD_CONFIG_FILE=%PROJECT_ROOT%\.info\app\build.json"
    set "PATHS_CONFIG_FILE=%PROJECT_ROOT%\.info\app\paths.json"
) else (
    REM Fallback to hardcoded paths if centralized config is not available
    set "FIREBASE_INFO_FILE=%ROOT_DIR%\.info\firebase_info.json"
    set "APP_CONFIG_FILE=%ROOT_DIR%\.info\app\app.json"
    set "BUILD_CONFIG_FILE="
    set "PATHS_CONFIG_FILE="
)

REM Project paths
set "PUBSPEC_FILE=%ROOT_DIR%\pubspec.yaml"
set "L10N_FILE=%ROOT_DIR%\l10n.yaml"
set "FLAVORIZR_FILE=%ROOT_DIR%\flavorizr.yaml"

REM Build output directories (with fallbacks) - Android only for Windows
where jq >nul 2>&1
if %errorlevel% equ 0 if exist "%BUILD_CONFIG_FILE%" (
    for /f "delims=" %%i in ('jq -r ".flutter.outputPaths.android.apk // \"build\\app\\outputs\\flutter-apk\"" "%BUILD_CONFIG_FILE%" 2^>nul') do set "ANDROID_APK_OUTPUT=%%i"
    for /f "delims=" %%i in ('jq -r ".flutter.outputPaths.android.appbundle // \"build\\app\\outputs\\bundle\"" "%BUILD_CONFIG_FILE%" 2^>nul') do set "ANDROID_BUNDLE_OUTPUT=%%i"
    for /f "delims=" %%i in ('jq -r ".flutter.outputPaths.debugInfo // \".obfuscation\"" "%BUILD_CONFIG_FILE%" 2^>nul') do set "DEBUG_SYMBOLS_DIR=%%i"
) else (
    REM Fallback to hardcoded paths
    set "ANDROID_APK_OUTPUT=%ROOT_DIR%\build\app\outputs\flutter-apk"
    set "ANDROID_BUNDLE_OUTPUT=%ROOT_DIR%\build\app\outputs\bundle"
    set "DEBUG_SYMBOLS_DIR=%ROOT_DIR%\.obfuscation"
)

REM Legacy compatibility
set "ANDROID_OUTPUT_DIR=%ROOT_DIR%\build\app\outputs"

REM Environment files directory
set "ENV_DIR=%ROOT_DIR%\.env"

REM Export variables are automatically available in batch files within the same session

goto :eof

REM ============================================
REM Convenience function to display current paths configuration
REM ============================================

:show_paths_config
echo === Project Paths Configuration (Windows) ===
echo Root Directory: %ROOT_DIR%
echo Tools Directory: %TOOLS_DIR%
echo Info Directory: %ROOT_DIR%\.info
echo.
echo === Configuration Files ===
echo App Config: %APP_CONFIG_FILE%
echo Firebase Config: %FIREBASE_INFO_FILE%
echo Build Config: %BUILD_CONFIG_FILE%
echo Paths Config: %PATHS_CONFIG_FILE%
echo.
echo === Build Output Paths ===
echo Android APK: %ANDROID_APK_OUTPUT%
echo Android Bundle: %ANDROID_BUNDLE_OUTPUT%
echo Debug Symbols: %DEBUG_SYMBOLS_DIR%
echo Note: iOS builds not supported on Windows
echo ==========================================
goto :eof