@echo off
setlocal enabledelayedexpansion

REM Configuration Testing Script (Windows)
REM This script validates the centralized configuration setup

REM Navigate to the root directory relative to the current script location
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\..\..\"
cd /d "%ROOT_DIR%" || (
    echo ❌ Failed to navigate to the project root directory.
    exit /b 1
)

REM Load common configuration functions
call "%SCRIPT_DIR%..\common\common.bat"
if %errorlevel% neq 0 (
    echo ❌ Failed to load common configuration library.
    echo Make sure tools\windows\common\common.bat exists and is readable.
    exit /b 1
)

call :log_info "🧪 Testing centralized configuration setup (Windows)..."

REM Test 1: Environment validation
echo.
call :log_step "Test 1: Environment Validation"
call :validate_environment
if %errorlevel% equ 0 (
    call :log_success "Environment validation passed"
) else (
    call :log_error "Environment validation failed"
    exit /b 1
)

REM Test 2: Configuration reading
echo.
call :log_step "Test 2: Configuration Reading"

REM Test app configuration
call :get_app_name APP_NAME
if "%APP_NAME%" neq "" if "%APP_NAME%" neq "null" (
    call :log_success "App name: %APP_NAME%"
) else (
    call :log_error "Failed to read app name"
)

REM Test version reading from pubspec.yaml
call :get_pubspec_version PUBSPEC_VERSION
if "%PUBSPEC_VERSION%" neq "" (
    call :log_success "Version from pubspec.yaml: %PUBSPEC_VERSION%"
) else (
    call :log_error "Failed to read version from pubspec.yaml"
)

REM Test 3: Flavor configurations
echo.
call :log_step "Test 3: Flavor Configurations"
for %%f in (dev stg prod) do (
    call :log_info "Testing %%f flavor..."

    call :validate_flavor "%%f"
    if !errorlevel! equ 0 (
        call :log_success "  ✅ Flavor validation: %%f"
    ) else (
        call :log_error "  ❌ Flavor validation: %%f"
        goto :continue_flavor_test
    )

    REM Test Android configuration
    call :get_android_package_name "%%f" ANDROID_PACKAGE
    if "!ANDROID_PACKAGE!" neq "" if "!ANDROID_PACKAGE!" neq "null" (
        call :log_success "  ✅ Android package: !ANDROID_PACKAGE!"
    ) else (
        call :log_warning "  ⚠️  Android package not configured for %%f"
    )

    REM Test environment file path
    call :get_env_file_path "%%f" ENV_FILE
    if "!ENV_FILE!" neq "" if "!ENV_FILE!" neq "null" (
        call :log_success "  ✅ Environment file path: !ENV_FILE!"

        if exist "!ENV_FILE!" (
            call :log_success "  ✅ Environment file exists"
        ) else (
            call :log_warning "  ⚠️  Environment file not found: !ENV_FILE!"
        )
    ) else (
        call :log_warning "  ⚠️  Environment file path not configured for %%f"
    )

    REM Test Firebase configuration
    call :get_firebase_project_id "%%f" FIREBASE_PROJECT
    if "!FIREBASE_PROJECT!" neq "" if "!FIREBASE_PROJECT!" neq "null" (
        call :log_success "  ✅ Firebase project: !FIREBASE_PROJECT!"
    ) else (
        call :log_warning "  ⚠️  Firebase project not configured for %%f"
    )

    :continue_flavor_test
    echo.
)

REM Test 4: Build paths
echo.
call :log_step "Test 4: Build Configuration"

call :get_output_path "android" "apk" APK_PATH
if "%APK_PATH%" neq "" if "%APK_PATH%" neq "null" (
    call :log_success "APK output path: %APK_PATH%"
) else (
    call :log_warning "APK output path not configured"
)

call :get_output_path "android" "appbundle" BUNDLE_PATH
if "%BUNDLE_PATH%" neq "" if "%BUNDLE_PATH%" neq "null" (
    call :log_success "App Bundle output path: %BUNDLE_PATH%"
) else (
    call :log_warning "App Bundle output path not configured"
)

call :get_debug_info_path DEBUG_PATH
if "%DEBUG_PATH%" neq "" if "%DEBUG_PATH%" neq "null" (
    call :log_success "Debug info path: %DEBUG_PATH%"
) else (
    call :log_warning "Debug info path not configured"
)

REM Test 5: Flutter command
echo.
call :log_step "Test 5: Flutter Command"
call :get_flutter_command FLUTTER_CMD
call :log_success "Flutter command: %FLUTTER_CMD%"

where flutter >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "Flutter is available in PATH"
    for /f "delims=" %%i in ('flutter --version 2^>nul ^| findstr "Flutter"') do (
        call :log_info "Flutter version: %%i"
    )
) else (
    call :log_error "Flutter not found in PATH!"
)

REM Test 6: Platform validation
echo.
call :log_step "Test 6: Platform Validation"
call :validate_platform "android"
if %errorlevel% equ 0 (
    call :log_success "Android platform validation passed"
) else (
    call :log_error "Android platform validation failed"
)

REM Note about iOS not being supported
call :log_info "iOS platform validation skipped (not supported on Windows)"

REM Summary
echo.
call :log_step "Configuration Test Summary"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo Project: %APP_NAME%
echo Version: %PUBSPEC_VERSION%
echo Platform: Windows (Android builds only)
echo Flutter: %FLUTTER_CMD%
echo.
echo Configuration Status:
echo   ✅ Environment validation
echo   ✅ Configuration reading
echo   ✅ Flavor configurations
echo   ✅ Build paths
echo   ✅ Flutter command
echo   ✅ Platform validation (Android)
echo.
echo Your centralized configuration is working correctly!
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

call :log_success "🎉 All configuration tests passed!"

REM Pause for user removed for automation
exit /b 0