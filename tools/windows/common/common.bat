@echo off
REM Enhanced Common Configuration Library for Windows
REM This library provides centralized access to all project configurations
REM Usage: call "%~dp0\..\common\common.bat"

REM Don't use setlocal here - it prevents functions from being called by other scripts
REM Individual functions will use setlocal/endlocal as needed

REM Define ANSI color codes for Windows (requires Windows 10 version 1607 or later)
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "PURPLE=[95m"
set "CYAN=[96m"
set "NC=[0m"

REM Project paths
for %%i in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fi"
set "INFO_DIR=%PROJECT_ROOT%\.info"
set "INFO_APP_DIR=%INFO_DIR%\app"
set "INFO_DIST_DIR=%INFO_DIR%\distribution"
set "INFO_KEY_DIR=%INFO_DIR%\key"
set "INFO_CACHE_DIR=%INFO_DIR%\cache"
set "VERSION_MANAGER_CACHE=%INFO_CACHE_DIR%\version_manager.cache"

REM Configuration files
set "APP_CONFIG=%INFO_APP_DIR%\app.json"
set "FIREBASE_CONFIG=%INFO_APP_DIR%\firebase.json"
set "BUILD_CONFIG=%INFO_APP_DIR%\build.json"
set "PATHS_CONFIG=%INFO_APP_DIR%\paths.json"

REM Distribution data files
set "TESTER_LIST_FILE=%INFO_DIST_DIR%\tester_list.txt"
set "TESTER_GROUP_FILE=%INFO_DIST_DIR%\tester_group.txt"
set "RELEASE_NOTE_FILE=%INFO_DIST_DIR%\release_note.txt"
set "TEST_DEVICE_FILE=%INFO_DIST_DIR%\test_device.txt"
set "TEST_PASSWORD_FILE=%INFO_DIST_DIR%\test_password.txt"

REM Export common functions flag
set "COMMON_LOADED=1"

goto :eof

REM ============================================
REM Logging Functions
REM ============================================

:log_info
echo %BLUE%ℹ️  %~1%NC%
goto :eof

:log_success
echo %GREEN%✅ %~1%NC%
goto :eof

:log_warning
echo %YELLOW%⚠️  %~1%NC%
goto :eof

:log_error
echo %RED%❌ %~1%NC%
goto :eof

:log_step
echo %PURPLE%🔸 %~1%NC%
goto :eof

REM ============================================
REM Validation Functions
REM ============================================

:validate_flavor
set "flavor=%~1"
if "%flavor%"=="dev" goto :validate_flavor_valid
if "%flavor%"=="stg" goto :validate_flavor_valid
if "%flavor%"=="prod" goto :validate_flavor_valid

call :log_error "Invalid flavor: %flavor%"
call :log_info "Supported flavors: dev, stg, prod"
exit /b 1

:validate_flavor_valid
exit /b 0

:validate_platform
set "platform=%~1"
if "%platform%"=="android" goto :validate_platform_valid

call :log_error "Invalid platform: %platform%"
call :log_info "Supported platforms: android (iOS not supported on Windows)"
exit /b 1

:validate_platform_valid
exit /b 0

:check_required_files
setlocal enabledelayedexpansion
set "missing_count=0"

if not exist "%APP_CONFIG%" (
    call :log_error "Missing: %APP_CONFIG%"
    set /a missing_count+=1
)
if not exist "%FIREBASE_CONFIG%" (
    call :log_error "Missing: %FIREBASE_CONFIG%"
    set /a missing_count+=1
)
if not exist "%BUILD_CONFIG%" (
    call :log_error "Missing: %BUILD_CONFIG%"
    set /a missing_count+=1
)
if not exist "%PATHS_CONFIG%" (
    call :log_error "Missing: %PATHS_CONFIG%"
    set /a missing_count+=1
)

if !missing_count! gtr 0 (
    call :log_error "Missing required configuration files"
    endlocal
    exit /b 1
)
endlocal
exit /b 0

REM ============================================
REM JSON Reading Functions (requires jq.exe)
REM ============================================

:get_app_config
setlocal enabledelayedexpansion
set "key=%~1"
set "result="
if exist "%APP_CONFIG%" (
    where jq >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "delims=" %%i in ('jq -r "!key! // empty" "%APP_CONFIG%" 2^>nul') do set "result=%%i"
    )
)
endlocal & set "%~2=%result%"
goto :eof

:get_firebase_config
setlocal enabledelayedexpansion
set "key=%~1"
set "result="
if exist "%FIREBASE_CONFIG%" (
    where jq >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "delims=" %%i in ('jq -r "!key! // empty" "%FIREBASE_CONFIG%" 2^>nul') do set "result=%%i"
    )
)
endlocal & set "%~2=%result%"
goto :eof

:get_build_config
setlocal enabledelayedexpansion
set "key=%~1"
set "result="
if exist "%BUILD_CONFIG%" (
    where jq >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "delims=" %%i in ('jq -r "!key! // empty" "%BUILD_CONFIG%" 2^>nul') do set "result=%%i"
    )
)
endlocal & set "%~2=%result%"
goto :eof

:get_paths_config
setlocal enabledelayedexpansion
set "key=%~1"
set "result="
if exist "%PATHS_CONFIG%" (
    where jq >nul 2>&1
    if !errorlevel! equ 0 (
        for /f "delims=" %%i in ('jq -r "!key! // empty" "%PATHS_CONFIG%" 2^>nul') do set "result=%%i"
    )
)
endlocal & set "%~2=%result%"
goto :eof

REM ============================================
REM App Information Functions
REM ============================================

:get_app_name
call :get_app_config ".appName" app_name_result
set "%~1=%app_name_result%"
goto :eof

:get_app_display_name
setlocal enabledelayedexpansion
set "flavor=%~1"
set "result="
if "!flavor!" neq "" (
    call :get_app_config ".flavors.!flavor!.displayName" flavor_display_name
    if "!flavor_display_name!" neq "" if "!flavor_display_name!" neq "null" (
        set "result=!flavor_display_name!"
    ) else (
        call :get_app_config ".appDisplayName" result
    )
) else (
    call :get_app_config ".appDisplayName" result
)
endlocal & set "%~2=%result%"
goto :eof

:get_app_version
call :get_app_config ".version" app_version_result
set "%~1=%app_version_result%"
goto :eof

:get_build_number
call :get_app_config ".buildNumber" build_number_result
set "%~1=%build_number_result%"
goto :eof

REM Get version from pubspec.yaml
:get_pubspec_version
setlocal enabledelayedexpansion
set "pubspec_path=%PROJECT_ROOT%\pubspec.yaml"
set "result="
if exist "%pubspec_path%" (
    for /f "tokens=2" %%i in ('findstr "^version:" "%pubspec_path%"') do (
        set "result=%%i"
        REM Remove any comments
        for /f "tokens=1 delims=#" %%j in ("!result!") do set "result=%%j"
        set "result=!result: =!"
    )
)
endlocal & set "%~1=%result%"
goto :eof

REM ============================================
REM Platform-specific Functions
REM ============================================

:get_android_package_name
setlocal enabledelayedexpansion
set "flavor=%~1"
set "result="
if "!flavor!" neq "" (
    call :get_app_config ".flavors.!flavor!.android.packageName" flavor_package
    if "!flavor_package!" neq "" if "!flavor_package!" neq "null" (
        set "result=!flavor_package!"
    ) else (
        call :get_app_config ".android.packageName" result
    )
) else (
    call :get_app_config ".android.packageName" result
)
endlocal & set "%~2=%result%"
goto :eof

REM ============================================
REM Firebase Functions
REM ============================================

:get_firebase_project_id
setlocal enabledelayedexpansion
set "flavor=%~1"
set "result="
if "!flavor!" neq "" (
    call :get_firebase_config ".projects.!flavor!" project_id
    if "!project_id!" neq "" if "!project_id!" neq "null" (
        set "result=!project_id!"
    ) else (
        call :get_firebase_config ".projectId" result
    )
) else (
    call :get_firebase_config ".projectId" result
)
endlocal & set "%~2=%result%"
goto :eof

:get_firebase_app_id
set "platform=%~1"
set "flavor=%~2"
call :get_firebase_config ".apps.%platform%.%flavor%.appId" result
set "%~3=%result%"
goto :eof

REM ============================================
REM Cache Management Functions
REM ============================================

:ensure_cache_dir
if not exist "%INFO_CACHE_DIR%" (
    mkdir "%INFO_CACHE_DIR%" 2>nul
)
goto :eof

:get_cached_version_manager
setlocal
set "cached="
if exist "%VERSION_MANAGER_CACHE%" (
    set /p cached=<"%VERSION_MANAGER_CACHE%"
)
endlocal & set "%~1=%cached%"
goto :eof

:set_cached_version_manager
call :ensure_cache_dir
echo %~1>"%VERSION_MANAGER_CACHE%"
goto :eof

:clear_version_manager_cache
if exist "%VERSION_MANAGER_CACHE%" del "%VERSION_MANAGER_CACHE%" 2>nul
goto :eof

:is_version_manager_available
setlocal
set "vm=%~1"
set "available=0"

if "%vm%"=="puro" (
    where puro >nul 2>&1
    if !errorlevel!==0 set "available=1"
) else if "%vm%"=="fvm" (
    where fvm >nul 2>&1
    if !errorlevel!==0 set "available=1"
) else if "%vm%"=="none" (
    set "available=1"
)

endlocal & exit /b %available%

:detect_version_manager
setlocal enabledelayedexpansion
set "use_cache=%~1"
if "%use_cache%"=="" set "use_cache=true"

REM Check cache if enabled
call :get_build_config ".flutter.versionManagerCache" cache_enabled
if "%cache_enabled%"=="" set "cache_enabled=true"

if "%use_cache%"=="true" if not "%cache_enabled%"=="false" (
    call :get_cached_version_manager cached
    if not "!cached!"=="" (
        call :is_version_manager_available "!cached!"
        if !errorlevel!==1 (
            endlocal & set "%~2=!cached!" & goto :eof
        )
    )
)

REM Get version manager configuration (check if array or string)
call :get_build_config ".flutter.versionManager" vm_config

if "%vm_config%"=="" (
    call :set_cached_version_manager "none"
    endlocal & set "%~2=none" & goto :eof
)

REM Simple detection: try to parse as array using PowerShell
powershell -Command "try { $cfg = '%vm_config%' | ConvertFrom-Json; if ($cfg -is [array]) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
if !errorlevel!==0 (
    REM Array mode: auto-detect
    for /f "delims=" %%v in ('powershell -Command "$cfg = '%vm_config%' | ConvertFrom-Json; $cfg -join '|'"') do (
        for %%m in (%%v) do (
            call :is_version_manager_available "%%m"
            if !errorlevel!==1 (
                call :set_cached_version_manager "%%m"
                endlocal & set "%~2=%%m" & goto :eof
            )
        )
    )

    REM Nothing found
    call :log_warning "No version manager found from configuration, using system flutter"
    call :set_cached_version_manager "none"
    endlocal & set "%~2=none" & goto :eof
) else (
    REM Force mode: use specific version manager
    call :is_version_manager_available "%vm_config%"
    if !errorlevel!==1 (
        call :set_cached_version_manager "%vm_config%"
        endlocal & set "%~2=%vm_config%" & goto :eof
    ) else (
        call :log_warning "%vm_config% configured but not found, falling back to system flutter"
        call :set_cached_version_manager "none"
        endlocal & set "%~2=none" & goto :eof
    )
)

REM ============================================
REM Build Configuration Functions
REM ============================================

:get_flutter_command
setlocal
if defined SKIP_VERSION_MANAGER_CACHE (
    call :detect_version_manager "false" vm
) else (
    call :detect_version_manager "true" vm
)

if "%vm%"=="puro" (
    set "cmd=puro flutter"
) else if "%vm%"=="fvm" (
    set "cmd=fvm flutter"
) else (
    set "cmd=flutter"
)

endlocal & set "%~1=%cmd%"
goto :eof

:get_dart_command
setlocal
if defined SKIP_VERSION_MANAGER_CACHE (
    call :detect_version_manager "false" vm
) else (
    call :detect_version_manager "true" vm
)

if "%vm%"=="puro" (
    set "cmd=puro dart"
) else if "%vm%"=="fvm" (
    set "cmd=fvm dart"
) else (
    set "cmd=dart"
)

endlocal & set "%~1=%cmd%"
goto :eof

:get_output_path
set "platform=%~1"
set "build_type=%~2"
call :get_build_config ".flutter.outputPaths.%platform%.%build_type%" result
if "%result%"=="" (
    REM Fallback paths
    if "%platform%"=="android" (
        if "%build_type%"=="apk" set "result=build\app\outputs\flutter-apk"
        if "%build_type%"=="appbundle" set "result=build\app\outputs\bundle"
    )
)
set "%~3=%result%"
goto :eof

:get_debug_info_path
call :get_build_config ".flutter.outputPaths.debugInfo" result
if "%result%"=="" set "result=.obfuscation"
set "%~1=%result%"
goto :eof

REM ============================================
REM Environment File Functions
REM ============================================

:get_env_file_path
set "flavor=%~1"
call :get_paths_config ".environment.files.%flavor%" result
if "%result%"=="" (
    REM Fallback to standard path
    set "result=.env\.env.%flavor%"
)
set "%~2=%result%"
goto :eof

REM ============================================
REM Validation and Setup Functions
REM ============================================

:validate_environment
setlocal enabledelayedexpansion
call :log_step "Validating environment..."

REM Check for required tools
set "missing_tools=0"

where jq >nul 2>&1
if !errorlevel! neq 0 (
    call :log_warning "jq not found (JSON parsing will be limited)"
    set /a missing_tools+=1
)

where flutter >nul 2>&1
if !errorlevel! neq 0 (
    call :log_error "flutter not found"
    set /a missing_tools+=1
    endlocal
    exit /b 1
) else (
    call :log_success "flutter found"
)

REM Check for required configuration files
call :check_required_files
if !errorlevel! neq 0 (
    endlocal
    exit /b 1
)

if !missing_tools! equ 0 (
    call :log_success "Environment validation passed"
) else (
    call :log_warning "Environment validation passed with warnings"
)
endlocal
exit /b 0

REM ============================================
REM Configuration Summary
REM ============================================

:show_config_summary
set "flavor=%~1"
set "platform=%~2"

echo.
call :log_step "Configuration Summary"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

call :get_app_display_name "%flavor%" app_display_name
echo App Name: %app_display_name%

call :get_pubspec_version pubspec_version
echo Version: %pubspec_version%

echo Flavor: %flavor%

if "%platform%" neq "" (
    echo Platform: %platform%

    if "%platform%"=="android" (
        call :get_android_package_name "%flavor%" package_name
        echo Package Name: %package_name%
    )
)

call :get_firebase_project_id "%flavor%" firebase_project
echo Firebase Project: %firebase_project%

call :get_env_file_path "%flavor%" env_file
echo Environment File: %env_file%

echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
goto :eof

REM ============================================
REM Distribution Functions
REM ============================================

:get_firebase_testers
set "flavor=%~1"
call :get_firebase_config ".distribution.testers.%flavor%" testers_raw
REM Convert array to comma-separated string (simplified for batch)
set "%~2=%testers_raw%"
goto :eof

:get_firebase_groups
set "flavor=%~1"
call :get_firebase_config ".distribution.groups.%flavor%" groups_raw
REM Convert array to comma-separated string (simplified for batch)
set "%~2=%groups_raw%"
goto :eof

:get_release_notes_template
call :get_firebase_config ".distribution.releaseNotes.template" result
set "%~1=%result%"
goto :eof

:get_tester_list_from_file
set "result="
if exist "%TESTER_LIST_FILE%" (
    for /f "usebackq eol=# delims=" %%i in ("%TESTER_LIST_FILE%") do (
        set "line=%%i"
        if "!line!" neq "" (
            if "!result!"=="" (
                set "result=!line!"
            ) else (
                set "result=!result!,!line!"
            )
        )
    )
)
set "%~1=%result%"
goto :eof

:get_tester_groups_from_file
set "result="
if exist "%TESTER_GROUP_FILE%" (
    for /f "usebackq eol=# delims=" %%i in ("%TESTER_GROUP_FILE%") do (
        set "line=%%i"
        if "!line!" neq "" (
            if "!result!"=="" (
                set "result=!line!"
            ) else (
                set "result=!result!,!line!"
            )
        )
    )
)
set "%~1=%result%"
goto :eof

:get_release_notes_from_file
set "result="
if exist "%RELEASE_NOTE_FILE%" (
    for /f "usebackq delims=" %%i in ("%RELEASE_NOTE_FILE%") do (
        if "!result!"=="" (
            set "result=%%i"
        ) else (
            set "result=!result! %%i"
        )
    )
)
set "%~1=%result%"
goto :eof

:get_test_devices_from_file
set "result="
if exist "%TEST_DEVICE_FILE%" (
    for /f "usebackq eol=# delims=" %%i in ("%TEST_DEVICE_FILE%") do (
        set "line=%%i"
        if "!line!" neq "" (
            if "!result!"=="" (
                set "result=!line!"
            ) else (
                set "result=!result! !line!"
            )
        )
    )
)
set "%~1=%result%"
goto :eof

:get_test_password_from_file
set "result="
if exist "%TEST_PASSWORD_FILE%" (
    for /f "usebackq eol=# delims=" %%i in ("%TEST_PASSWORD_FILE%") do (
        set "line=%%i"
        if "!line!" neq "" (
            set "result=!line!"
            goto :get_test_password_done
        )
    )
)
:get_test_password_done
set "%~1=%result%"
goto :eof

:get_all_testers
set "flavor=%~1"

call :get_firebase_testers "%flavor%" json_testers
call :get_tester_list_from_file file_testers

set "all_testers="
if "%json_testers%" neq "" set "all_testers=%json_testers%"
if "%file_testers%" neq "" (
    if "%all_testers%" neq "" (
        set "all_testers=%all_testers%,%file_testers%"
    ) else (
        set "all_testers=%file_testers%"
    )
)
set "%~2=%all_testers%"
goto :eof

:get_all_groups
set "flavor=%~1"

call :get_firebase_groups "%flavor%" json_groups
call :get_tester_groups_from_file file_groups

set "all_groups="
if "%json_groups%" neq "" set "all_groups=%json_groups%"
if "%file_groups%" neq "" (
    if "%all_groups%" neq "" (
        set "all_groups=%all_groups%,%file_groups%"
    ) else (
        set "all_groups=%file_groups%"
    )
)
set "%~2=%all_groups%"
goto :eof

:get_all_release_notes
set "flavor=%~1"
set "version=%~2"

call :get_release_notes_from_file file_notes

if "%file_notes%" neq "" (
    REM Use file notes and replace variables
    set "result=%file_notes%"
    for /f "tokens=1-6 delims=/ " %%a in ("%date%") do (
        set "date_formatted=%%c-%%a-%%b"
    )
    for /f "tokens=1-2 delims=:" %%a in ("%time%") do (
        set "time_formatted=%%a:%%b"
    )
    set "result=!result:{{version}}=%version%!"
    set "result=!result:{{flavor}}=%flavor%!"
    set "result=!result:{{date}}=%date_formatted% %time_formatted%!"
    set "%~3=!result!"
) else (
    REM Fallback to template from JSON
    call :format_release_notes "%flavor%" "%version%" result
    set "%~3=%result%"
)
goto :eof

:format_release_notes
set "flavor=%~1"
set "version=%~2"
call :get_release_notes_template template
set "result=%template%"
for /f "tokens=1-6 delims=/ " %%a in ("%date%") do (
    set "date_formatted=%%c-%%a-%%b"
)
for /f "tokens=1-2 delims=:" %%a in ("%time%") do (
    set "time_formatted=%%a:%%b"
)
set "result=!result:{{version}}=%version%!"
set "result=!result:{{flavor}}=%flavor%!"
set "result=!result:{{date}}=%date_formatted% %time_formatted%!"
set "%~3=%result%"
goto :eof

:get_project_root
set "%~1=%PROJECT_ROOT%"
goto :eof

:get_relative_path
set "path=%~1"
if "%path:~1,1%"==":" (
  set "%~2=%path%"
) else (
  set "%~2=%PROJECT_ROOT%\%path%"
)
goto :eof

REM ============================================
REM Entry Point Information
REM ============================================

:main
if "%~0"=="%~nx0" (
    call :log_info "Common configuration library loaded for Windows"
    call :log_info "Usage: call this file from other scripts"
    call :log_info "Available functions:"
    echo   - validate_environment
    echo   - get_app_name, get_app_version, etc.
    echo   - get_android_package_name
    echo   - get_firebase_project_id, get_firebase_app_id
    echo   - get_all_testers, get_all_groups, get_all_release_notes
    echo   - show_config_summary
    echo.
    echo Note: Install jq.exe for full JSON parsing support
    echo Download from: https://github.com/stedolan/jq/releases
)
goto :eof

REM Run main if script is executed directly
if "%~0"=="%~nx0" call :main
