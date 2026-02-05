@echo off
setlocal enabledelayedexpansion

REM Distribution Data File Manager with Centralized Configuration (Windows)
REM This script manages tester lists, groups, release notes, and test devices in text files

REM Navigate to the root directory relative to the current script location
set "ROOT_DIR=%~dp0..\..\.."
cd /d "%ROOT_DIR%"
if %errorlevel% neq 0 (
    echo ❌ Failed to navigate to the project root directory.
    exit /b 1
)

REM Load common configuration functions
call "%~dp0..\common\common.bat"
if %errorlevel% neq 0 (
    echo ❌ Failed to load common configuration library.
    echo Make sure tools\windows\common\common.bat exists and is readable.
    exit /b 1
)

REM Initialize variables
set "COMMAND="
set "FILE_TYPE="
set "VALUE="
set "FLAVOR="
set "EDITOR=notepad"

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="init" (
    set "COMMAND=%~1"
    shift
    goto :parse_args
)
if "%~1"=="sync-app-ids" (
    set "COMMAND=%~1"
    shift
    goto :parse_args
)
if "%~1"=="edit" (
    set "COMMAND=%~1"
    set "FILE_TYPE=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="show" (
    set "COMMAND=%~1"
    set "FILE_TYPE=%~2"
    shift
    if not "%~2"=="" shift
    goto :parse_args
)
if "%~1"=="add-tester" (
    set "COMMAND=%~1"
    set "VALUE=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="add-group" (
    set "COMMAND=%~1"
    set "VALUE=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="set-release-note" (
    set "COMMAND=%~1"
    shift
    goto :parse_args
)
if "%~1"=="add-device" (
    set "COMMAND=%~1"
    set "VALUE=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="set-password" (
    set "COMMAND=%~1"
    shift
    goto :parse_args
)
if "%~1"=="sync-to-firebase" (
    set "COMMAND=%~1"
    shift
    goto :parse_args
)
if "%~1"=="validate" (
    set "COMMAND=%~1"
    shift
    goto :parse_args
)
if "%~1"=="--flavor" (
    set "FLAVOR=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--editor" (
    set "EDITOR=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help

call :log_error "Unknown option: %~1"
echo Use -h or --help for usage information
exit /b 1

:show_help
echo Usage: %~nx0 ^<command^> [options]
echo.
echo Commands:
echo   init                      Initialize distribution data files with examples
echo   sync-app-ids              Sync Firebase app IDs from firebase.json
echo   edit ^<file^>               Edit a distribution data file
echo   show [file]               Show content of distribution data files
echo   add-tester ^<email^>        Add tester to tester_list.txt
echo   add-group ^<group^>         Add group to tester_group.txt
echo   set-release-note          Set custom release notes
echo   add-device ^<device^>       Add test device
echo   set-password              Set test password
echo   sync-to-firebase          Sync data files to Firebase
echo   validate                  Validate all data files
echo.
echo File options:
echo   tester-list       Tester email addresses
echo   tester-group      Distribution group names
echo   release-note      Custom release notes
echo   test-device       Test devices for automation
echo   test-password     Test account password
echo.
echo Options:
echo   --flavor ^<env^>    Environment flavor (dev^|stg^|prod)
echo   --editor ^<cmd^>    Text editor command (default: notepad)
echo   -h, --help        Show this help message
echo.
echo Examples:
echo   %~nx0 init
echo   %~nx0 sync-app-ids
echo   %~nx0 show
echo   %~nx0 add-tester user@example.com
echo   %~nx0 add-group qa-team
echo   %~nx0 edit tester-list
echo   %~nx0 sync-to-firebase --flavor dev
echo.
echo Note: Uses Windows text editors (notepad, notepad++, or custom EDITOR)
exit /b 0

:args_done

REM Validate environment and parameters
call :validate_environment
if %errorlevel% neq 0 exit /b 1

if "%COMMAND%"=="" (
    call :log_error "No command specified."
    echo Use -h or --help for usage information
    exit /b 1
)

REM Set up distribution file paths
call :get_paths_config PATHS_CONFIG
for /f "tokens=2 delims=:" %%a in ('type "%PATHS_CONFIG%" ^| jq -r ".distribution.data_dir"') do set "INFO_DIST_DIR=%%a"
if "%INFO_DIST_DIR%"=="" set "INFO_DIST_DIR=.info\distribution"

set "TESTER_LIST_FILE=%INFO_DIST_DIR%\tester_list.txt"
set "TESTER_GROUP_FILE=%INFO_DIST_DIR%\tester_group.txt"
set "RELEASE_NOTE_FILE=%INFO_DIST_DIR%\release_note.txt"
set "TEST_DEVICE_FILE=%INFO_DIST_DIR%\test_device.txt"
set "TEST_PASSWORD_FILE=%INFO_DIST_DIR%\test_password.txt"

REM Execute command
if "%COMMAND%"=="init" goto :init_distribution_files
if "%COMMAND%"=="sync-app-ids" goto :sync_app_ids
if "%COMMAND%"=="edit" goto :edit_file
if "%COMMAND%"=="show" goto :show_files
if "%COMMAND%"=="add-tester" goto :add_tester
if "%COMMAND%"=="add-group" goto :add_group
if "%COMMAND%"=="set-release-note" goto :set_release_note
if "%COMMAND%"=="add-device" goto :add_device
if "%COMMAND%"=="set-password" goto :set_password
if "%COMMAND%"=="sync-to-firebase" goto :sync_to_firebase
if "%COMMAND%"=="validate" goto :validate_files

call :log_error "Unknown command: %COMMAND%"
exit /b 1

:init_distribution_files
call :log_step "Initializing distribution data files..."

REM Ensure distribution directory exists
if not exist "%INFO_DIST_DIR%" (
    call :log_info "Creating distribution data directory: %INFO_DIST_DIR%"
    mkdir "%INFO_DIST_DIR%" 2>nul
)

REM Create tester list file
if not exist "%TESTER_LIST_FILE%" (
    (
        echo # Tester Email List
        echo # Add one email address per line
        echo # Lines starting with # are comments and will be ignored
        echo #
        echo # Example:
        echo # user1@example.com
        echo # user2@example.com
        echo # qa-team@company.com
        echo.
    ) > "%TESTER_LIST_FILE%"
    call :log_success "Created: %TESTER_LIST_FILE%"
) else (
    call :log_info "Already exists: %TESTER_LIST_FILE%"
)

REM Create tester group file
if not exist "%TESTER_GROUP_FILE%" (
    (
        echo # Tester Group List
        echo # Add one group name per line
        echo # Lines starting with # are comments and will be ignored
        echo #
        echo # Example:
        echo # qa-team
        echo # beta-users
        echo # internal-testers
        echo.
    ) > "%TESTER_GROUP_FILE%"
    call :log_success "Created: %TESTER_GROUP_FILE%"
) else (
    call :log_info "Already exists: %TESTER_GROUP_FILE%"
)

REM Create release note file
if not exist "%RELEASE_NOTE_FILE%" (
    (
        echo # Custom Release Notes
        echo # Add your release notes content below
        echo # Lines starting with # are comments and will be ignored
        echo #
        echo # This file is used for custom release notes when distributing
        echo # builds through Firebase App Distribution.
        echo.
        echo New features and improvements in this release.
    ) > "%RELEASE_NOTE_FILE%"
    call :log_success "Created: %RELEASE_NOTE_FILE%"
) else (
    call :log_info "Already exists: %RELEASE_NOTE_FILE%"
)

REM Create test device file
if not exist "%TEST_DEVICE_FILE%" (
    (
        echo # Test Device List
        echo # Add device information for automated testing
        echo # Format: device_id:device_name:platform
        echo #
        echo # Example:
        echo # emulator-5554:Android_Emulator:android
        echo # ABCD1234:iPhone_12:ios
        echo.
    ) > "%TEST_DEVICE_FILE%"
    call :log_success "Created: %TEST_DEVICE_FILE%"
) else (
    call :log_info "Already exists: %TEST_DEVICE_FILE%"
)

REM Create test password file
if not exist "%TEST_PASSWORD_FILE%" (
    (
        echo # Test Account Password
        echo # Add test account credentials for automated testing
        echo # Keep this file secure and out of version control
        echo #
        echo # Example format:
        echo # username:password
        echo # test@example.com:testpassword123
        echo.
    ) > "%TEST_PASSWORD_FILE%"
    call :log_success "Created: %TEST_PASSWORD_FILE%"
) else (
    call :log_info "Already exists: %TEST_PASSWORD_FILE%"
)

call :log_success "🎉 Distribution data files initialized successfully!"
goto :end

:sync_app_ids
call :log_step "Syncing Firebase app IDs from configuration..."

call :get_firebase_config FIREBASE_CONFIG
if not exist "%FIREBASE_CONFIG%" (
    call :log_error "Firebase configuration not found: %FIREBASE_CONFIG%"
    exit /b 1
)

call :log_info "Reading Firebase app IDs from: %FIREBASE_CONFIG%"
REM This would require more complex JSON parsing for Windows
call :log_warning "App ID sync not fully implemented for Windows"
call :log_info "Please manually verify Firebase app IDs in: %FIREBASE_CONFIG%"
goto :end

:edit_file
if "%FILE_TYPE%"=="" (
    call :log_error "File type not specified for edit command"
    echo Available files: tester-list, tester-group, release-note, test-device, test-password
    exit /b 1
)

set "TARGET_FILE="
if "%FILE_TYPE%"=="tester-list" set "TARGET_FILE=%TESTER_LIST_FILE%"
if "%FILE_TYPE%"=="tester-group" set "TARGET_FILE=%TESTER_GROUP_FILE%"
if "%FILE_TYPE%"=="release-note" set "TARGET_FILE=%RELEASE_NOTE_FILE%"
if "%FILE_TYPE%"=="test-device" set "TARGET_FILE=%TEST_DEVICE_FILE%"
if "%FILE_TYPE%"=="test-password" set "TARGET_FILE=%TEST_PASSWORD_FILE%"

if "%TARGET_FILE%"=="" (
    call :log_error "Unknown file type: %FILE_TYPE%"
    exit /b 1
)

if not exist "%TARGET_FILE%" (
    call :log_warning "File does not exist: %TARGET_FILE%"
    call :log_info "Run 'init' command first to create distribution files"
    exit /b 1
)

call :log_info "Opening file with %EDITOR%: %TARGET_FILE%"
start /wait %EDITOR% "%TARGET_FILE%"
goto :end

:show_files
if "%FILE_TYPE%"=="" (
    call :log_step "Distribution Data Files Summary"
    echo.

    for %%f in ("%TESTER_LIST_FILE%" "%TESTER_GROUP_FILE%" "%RELEASE_NOTE_FILE%" "%TEST_DEVICE_FILE%" "%TEST_PASSWORD_FILE%") do (
        if exist "%%f" (
            call :log_success "✅ %%~nxf"
        ) else (
            call :log_warning "❌ %%~nxf (missing)"
        )
    )

    echo.
    call :log_info "Use 'show ^<file-type^>' to view specific file contents"
    call :log_info "Use 'edit ^<file-type^>' to modify files"
) else (
    set "TARGET_FILE="
    if "%FILE_TYPE%"=="tester-list" set "TARGET_FILE=%TESTER_LIST_FILE%"
    if "%FILE_TYPE%"=="tester-group" set "TARGET_FILE=%TESTER_GROUP_FILE%"
    if "%FILE_TYPE%"=="release-note" set "TARGET_FILE=%RELEASE_NOTE_FILE%"
    if "%FILE_TYPE%"=="test-device" set "TARGET_FILE=%TEST_DEVICE_FILE%"
    if "%FILE_TYPE%"=="test-password" set "TARGET_FILE=%TEST_PASSWORD_FILE%"

    if "!TARGET_FILE!"=="" (
        call :log_error "Unknown file type: %FILE_TYPE%"
        exit /b 1
    )

    if exist "!TARGET_FILE!" (
        call :log_info "Contents of !TARGET_FILE!:"
        echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
        type "!TARGET_FILE!"
        echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    ) else (
        call :log_warning "File does not exist: !TARGET_FILE!"
    )
)
goto :end

:add_tester
if "%VALUE%"=="" (
    call :log_error "Email address not specified"
    exit /b 1
)

if not exist "%TESTER_LIST_FILE%" (
    call :log_warning "Tester list file does not exist. Creating it..."
    goto :init_distribution_files
)

REM Check if email already exists
findstr /C:"%VALUE%" "%TESTER_LIST_FILE%" >nul 2>&1
if %errorlevel% equ 0 (
    call :log_warning "Email already exists in tester list: %VALUE%"
) else (
    echo %VALUE% >> "%TESTER_LIST_FILE%"
    call :log_success "Added tester: %VALUE%"
)
goto :end

:add_group
if "%VALUE%"=="" (
    call :log_error "Group name not specified"
    exit /b 1
)

if not exist "%TESTER_GROUP_FILE%" (
    call :log_warning "Tester group file does not exist. Creating it..."
    goto :init_distribution_files
)

REM Check if group already exists
findstr /C:"%VALUE%" "%TESTER_GROUP_FILE%" >nul 2>&1
if %errorlevel% equ 0 (
    call :log_warning "Group already exists in tester groups: %VALUE%"
) else (
    echo %VALUE% >> "%TESTER_GROUP_FILE%"
    call :log_success "Added group: %VALUE%"
)
goto :end

:set_release_note
call :log_info "Opening release notes file for editing..."
if not exist "%RELEASE_NOTE_FILE%" (
    call :log_warning "Release note file does not exist. Creating it..."
    goto :init_distribution_files
)
start /wait %EDITOR% "%RELEASE_NOTE_FILE%"
goto :end

:add_device
if "%VALUE%"=="" (
    call :log_error "Device information not specified"
    call :log_info "Format: device_id:device_name:platform"
    exit /b 1
)

if not exist "%TEST_DEVICE_FILE%" (
    call :log_warning "Test device file does not exist. Creating it..."
    goto :init_distribution_files
)

echo %VALUE% >> "%TEST_DEVICE_FILE%"
call :log_success "Added test device: %VALUE%"
goto :end

:set_password
call :log_info "Opening test password file for editing..."
call :log_warning "Keep this file secure and out of version control!"
if not exist "%TEST_PASSWORD_FILE%" (
    call :log_warning "Test password file does not exist. Creating it..."
    goto :init_distribution_files
)
start /wait %EDITOR% "%TEST_PASSWORD_FILE%"
goto :end

:sync_to_firebase
call :log_step "Syncing distribution data to Firebase..."
call :log_warning "Firebase sync not fully implemented for Windows"
call :log_info "Use Firebase Console to manage testers and groups manually"
call :log_info "https://console.firebase.google.com/project/your-project/appdistribution"
goto :end

:validate_files
call :log_step "Validating distribution data files..."

set "VALIDATION_ERRORS=0"

REM Validate tester list
if exist "%TESTER_LIST_FILE%" (
    call :log_info "Validating tester list..."
    REM Simple email validation (Windows batch is limited)
    for /f "usebackq tokens=*" %%a in ("%TESTER_LIST_FILE%") do (
        set "line=%%a"
        if not "!line:~0,1!"=="#" if not "!line!"=="" (
            echo !line! | findstr "@" >nul || (
                call :log_warning "Invalid email format: !line!"
                set /a VALIDATION_ERRORS+=1
            )
        )
    )
    call :log_success "Tester list validation complete"
) else (
    call :log_warning "Tester list file not found: %TESTER_LIST_FILE%"
    set /a VALIDATION_ERRORS+=1
)

if %VALIDATION_ERRORS% equ 0 (
    call :log_success "✅ All distribution data files are valid"
) else (
    call :log_warning "⚠️  Found %VALIDATION_ERRORS% validation issues"
)
goto :end

:end
endlocal
exit /b 0