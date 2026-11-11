@echo off
setlocal enabledelayedexpansion

REM Firebase App Distribution - Tester Management with Centralized Configuration (Windows)
REM This script provides comprehensive tester management for Firebase App Distribution

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
set "PROJECT_ID="
set "GROUP_NAME="
set "FILE_PATH="
set "FLAVOR="
set "DRY_RUN=false"
set "VERBOSE=false"
set "EMAILS="

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="list" (
    set "COMMAND=%~1"
    REM Check if next argument is a group name (not starting with --)
    if not "%~2"=="" if not "%~2:~0,2%"=="--" (
        set "GROUP_NAME=%~2"
        shift
    )
    shift
    goto :parse_args
)
if "%~1"=="add" (
    set "COMMAND=%~1"
    shift
    REM Collect all email arguments until we hit an option or end
    :collect_emails_add
    if "%~1"=="" goto :parse_args
    if "%~1:~0,2%"=="--" goto :parse_args
    if "%EMAILS%"=="" (
        set "EMAILS=%~1"
    ) else (
        set "EMAILS=!EMAILS!,%~1"
    )
    shift
    goto :collect_emails_add
)
if "%~1"=="remove" (
    set "COMMAND=%~1"
    shift
    REM Collect all email arguments until we hit an option or end
    :collect_emails_remove
    if "%~1"=="" goto :parse_args
    if "%~1:~0,2%"=="--" goto :parse_args
    if "%EMAILS%"=="" (
        set "EMAILS=%~1"
    ) else (
        set "EMAILS=!EMAILS!,%~1"
    )
    shift
    goto :collect_emails_remove
)
if "%~1"=="add-to-group" (
    set "COMMAND=%~1"
    shift
    goto :parse_args
)
if "%~1"=="remove-from-group" (
    set "COMMAND=%~1"
    shift
    goto :parse_args
)
if "%~1"=="import" (
    set "COMMAND=%~1"
    shift
    goto :parse_args
)
if "%~1"=="import-from-file" (
    set "COMMAND=%~1"
    shift
    goto :parse_args
)
if "%~1"=="add-file-to-group" (
    set "COMMAND=%~1"
    shift
    goto :parse_args
)
if "%~1"=="remove-file-from-group" (
    set "COMMAND=%~1"
    shift
    goto :parse_args
)
if "%~1"=="export" (
    set "COMMAND=%~1"
    shift
    goto :parse_args
)
if "%~1"=="--project" (
    set "PROJECT_ID=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--group" (
    set "GROUP_NAME=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--file" (
    set "FILE_PATH=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--flavor" (
    set "FLAVOR=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--dry-run" (
    set "DRY_RUN=true"
    shift
    goto :parse_args
)
if "%~1"=="--verbose" (
    set "VERBOSE=true"
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
echo   list [group]              List testers in project or group
echo   add ^<emails...^>           Add testers to project
echo   remove ^<emails...^>        Remove testers from project
echo   add-to-group              Add testers to a specific group
echo   remove-from-group         Remove testers from a specific group
echo   import                    Import testers from CSV file
echo   import-from-file          Import testers from tester_list.txt file
echo   add-file-to-group         Add testers from file to a specific group
echo   remove-file-from-group    Remove testers from file from a specific group
echo   export                    Export testers to CSV file
echo.
echo Options:
echo   --project ^<id^>            Firebase project ID (uses config if not specified)
echo   --group ^<name^>            Distribution group name
echo   --file ^<path^>             CSV file path for import/export
echo   --flavor ^<dev^|stg^|prod^>   Environment flavor for configuration
echo   --dry-run                 Show commands without executing
echo   --verbose                 Show detailed output
echo   -h, --help               Show this help message
echo.
echo Examples:
echo   %~nx0 list
echo   %~nx0 list --group qa-team
echo   %~nx0 add user1@example.com user2@example.com
echo   %~nx0 add-to-group --group qa-team user@example.com
echo   %~nx0 import --file testers.csv
echo   %~nx0 import-from-file --file .info\distribution\tester_list.txt
echo   %~nx0 add-file-to-group --group qa-team --file .info\distribution\tester_list.txt
echo   %~nx0 export --file testers-backup.csv
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

REM Get Firebase project ID from config if not specified
if "%PROJECT_ID%"=="" (
    if not "%FLAVOR%"=="" (
        call :validate_flavor "%FLAVOR%"
        if !errorlevel! neq 0 exit /b 1
        call :get_firebase_project_id "%FLAVOR%" PROJECT_ID
    ) else (
        REM Default to dev flavor if not specified
        call :get_firebase_project_id "dev" PROJECT_ID
    )
)

if "%PROJECT_ID%"=="" (
    call :log_error "Firebase project ID not found in configuration"
    call :log_error "Please specify --project or ensure Firebase configuration exists"
    exit /b 1
)

REM Set default file path for tester list
if "%FILE_PATH%"=="" if "%COMMAND:~-9%"=="-from-file" (
    set "FILE_PATH=.info\distribution\tester_list.txt"
)

REM Check Firebase CLI prerequisites
call :log_step "Checking Firebase CLI..."
where firebase >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "Firebase CLI is not installed"
    call :log_error "Please install it with: npm install -g firebase-tools"
    exit /b 1
)

REM Check Firebase authentication
firebase projects:list >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "Not logged in to Firebase CLI"
    call :log_error "Please login with: firebase login"
    exit /b 1
)

call :log_success "Firebase CLI is ready"
call :log_info "Project ID: %PROJECT_ID%"

REM Execute command
if "%COMMAND%"=="list" goto :list_testers
if "%COMMAND%"=="add" goto :add_testers
if "%COMMAND%"=="remove" goto :remove_testers
if "%COMMAND%"=="add-to-group" goto :add_to_group
if "%COMMAND%"=="remove-from-group" goto :remove_from_group
if "%COMMAND%"=="import" goto :import_testers
if "%COMMAND%"=="import-from-file" goto :import_from_file
if "%COMMAND%"=="add-file-to-group" goto :add_file_to_group
if "%COMMAND%"=="remove-file-from-group" goto :remove_file_from_group
if "%COMMAND%"=="export" goto :export_testers

call :log_error "Unknown command: %COMMAND%"
exit /b 1

:list_testers
if "%GROUP_NAME%"=="" (
    call :log_step "Listing all testers in project..."
    if "%DRY_RUN%"=="true" (
        call :log_info "DRY RUN: firebase appdistribution:testers:list --project=%PROJECT_ID%"
    ) else (
        firebase appdistribution:testers:list --project=%PROJECT_ID%
        if !errorlevel! neq 0 (
            call :log_error "Failed to list testers"
            exit /b 1
        )
    )
) else (
    call :log_step "Listing testers in group: %GROUP_NAME%"
    if "%DRY_RUN%"=="true" (
        call :log_info "DRY RUN: firebase appdistribution:groups:show %GROUP_NAME% --project=%PROJECT_ID%"
    ) else (
        firebase appdistribution:groups:show %GROUP_NAME% --project=%PROJECT_ID%
        if !errorlevel! neq 0 (
            call :log_error "Failed to show group testers"
            exit /b 1
        )
    )
)
goto :end

:add_testers
if "%EMAILS%"=="" (
    call :log_error "No email addresses specified for add command"
    exit /b 1
)

call :log_step "Adding testers to project..."
call :log_info "Emails: %EMAILS%"

set "ADD_CMD=firebase appdistribution:testers:add --emails=%EMAILS% --project=%PROJECT_ID%"

if "%VERBOSE%"=="true" (
    call :log_info "Command: !ADD_CMD!"
)

if "%DRY_RUN%"=="true" (
    call :log_info "DRY RUN: !ADD_CMD!"
) else (
    !ADD_CMD!
    if !errorlevel! equ 0 (
        call :log_success "Testers added successfully!"
    ) else (
        call :log_error "Failed to add some testers"
        exit /b 1
    )
)
goto :end

:remove_testers
if "%EMAILS%"=="" (
    call :log_error "No email addresses specified for remove command"
    exit /b 1
)

call :log_step "Removing testers from project..."
call :log_info "Emails: %EMAILS%"

set "REMOVE_CMD=firebase appdistribution:testers:remove --emails=%EMAILS% --project=%PROJECT_ID%"

if "%VERBOSE%"=="true" (
    call :log_info "Command: !REMOVE_CMD!"
)

if "%DRY_RUN%"=="true" (
    call :log_info "DRY RUN: !REMOVE_CMD!"
) else (
    call :log_warning "This will remove testers from the project. Continue? (Y/N)"
    set /p "CONFIRM="
    if /i "!CONFIRM!"=="Y" (
        !REMOVE_CMD!
        if !errorlevel! equ 0 (
            call :log_success "Testers removed successfully!"
        ) else (
            call :log_error "Failed to remove some testers"
            exit /b 1
        )
    ) else (
        call :log_info "Operation cancelled"
    )
)
goto :end

:add_to_group
if "%GROUP_NAME%"=="" (
    call :log_error "Group name is required for add-to-group command"
    call :log_error "Use --group option"
    exit /b 1
)

if "%EMAILS%"=="" (
    call :log_error "No email addresses specified"
    call :log_error "Provide emails as arguments or use --file option"
    exit /b 1
)

call :log_step "Adding testers to group: %GROUP_NAME%"
call :log_info "Emails: %EMAILS%"

set "ADD_GROUP_CMD=firebase appdistribution:groups:addtesters %GROUP_NAME% --emails=%EMAILS% --project=%PROJECT_ID%"

if "%VERBOSE%"=="true" (
    call :log_info "Command: !ADD_GROUP_CMD!"
)

if "%DRY_RUN%"=="true" (
    call :log_info "DRY RUN: !ADD_GROUP_CMD!"
) else (
    !ADD_GROUP_CMD!
    if !errorlevel! equ 0 (
        call :log_success "Testers added to group successfully!"
    ) else (
        call :log_error "Failed to add testers to group"
        exit /b 1
    )
)
goto :end

:remove_from_group
if "%GROUP_NAME%"=="" (
    call :log_error "Group name is required for remove-from-group command"
    call :log_error "Use --group option"
    exit /b 1
)

if "%EMAILS%"=="" (
    call :log_error "No email addresses specified"
    call :log_error "Provide emails as arguments or use --file option"
    exit /b 1
)

call :log_step "Removing testers from group: %GROUP_NAME%"
call :log_info "Emails: %EMAILS%"

set "REMOVE_GROUP_CMD=firebase appdistribution:groups:removetesters %GROUP_NAME% --emails=%EMAILS% --project=%PROJECT_ID%"

if "%VERBOSE%"=="true" (
    call :log_info "Command: !REMOVE_GROUP_CMD!"
)

if "%DRY_RUN%"=="true" (
    call :log_info "DRY RUN: !REMOVE_GROUP_CMD!"
) else (
    call :log_warning "This will remove testers from the group. Continue? (Y/N)"
    set /p "CONFIRM="
    if /i "!CONFIRM!"=="Y" (
        !REMOVE_GROUP_CMD!
        if !errorlevel! equ 0 (
            call :log_success "Testers removed from group successfully!"
        ) else (
            call :log_error "Failed to remove testers from group"
            exit /b 1
        )
    ) else (
        call :log_info "Operation cancelled"
    )
)
goto :end

:import_testers
if "%FILE_PATH%"=="" (
    call :log_error "File path is required for import command"
    call :log_error "Use --file option"
    exit /b 1
)

if not exist "%FILE_PATH%" (
    call :log_error "Import file not found: %FILE_PATH%"
    exit /b 1
)

call :log_step "Importing testers from CSV file: %FILE_PATH%"

set "IMPORT_CMD=firebase appdistribution:testers:import --file=%FILE_PATH% --project=%PROJECT_ID%"

if "%VERBOSE%"=="true" (
    call :log_info "Command: !IMPORT_CMD!"
)

if "%DRY_RUN%"=="true" (
    call :log_info "DRY RUN: !IMPORT_CMD!"
) else (
    !IMPORT_CMD!
    if !errorlevel! equ 0 (
        call :log_success "Testers imported successfully!"
    ) else (
        call :log_error "Failed to import testers"
        exit /b 1
    )
)
goto :end

:import_from_file
if "%FILE_PATH%"=="" (
    set "FILE_PATH=.info\distribution\tester_list.txt"
)

if not exist "%FILE_PATH%" (
    call :log_error "Tester list file not found: %FILE_PATH%"
    call :log_info "Create the file using: tools\windows\distribution\manage_distribution_data.bat init"
    exit /b 1
)

call :log_step "Importing testers from file: %FILE_PATH%"

REM Read emails from file and build email list
set "EMAIL_LIST="
set "EMAIL_COUNT=0"

for /f "usebackq tokens=*" %%a in ("%FILE_PATH%") do (
    set "line=%%a"
    REM Skip comments and empty lines
    if not "!line:~0,1!"=="#" if not "!line!"=="" (
        REM Basic email validation
        echo !line! | findstr "@" >nul && (
            if "!EMAIL_LIST!"=="" (
                set "EMAIL_LIST=!line!"
            ) else (
                set "EMAIL_LIST=!EMAIL_LIST!,!line!"
            )
            set /a EMAIL_COUNT+=1
        )
    )
)

if %EMAIL_COUNT% equ 0 (
    call :log_warning "No valid email addresses found in file"
    goto :end
)

call :log_info "Found %EMAIL_COUNT% email addresses"

set "IMPORT_CMD=firebase appdistribution:testers:add --emails=%EMAIL_LIST% --project=%PROJECT_ID%"

if "%VERBOSE%"=="true" (
    call :log_info "Command: !IMPORT_CMD!"
)

if "%DRY_RUN%"=="true" (
    call :log_info "DRY RUN: !IMPORT_CMD!"
) else (
    !IMPORT_CMD!
    if !errorlevel! equ 0 (
        call :log_success "Testers imported successfully from file!"
    ) else (
        call :log_error "Failed to import some testers"
        exit /b 1
    )
)
goto :end

:add_file_to_group
if "%GROUP_NAME%"=="" (
    call :log_error "Group name is required for add-file-to-group command"
    call :log_error "Use --group option"
    exit /b 1
)

if "%FILE_PATH%"=="" (
    set "FILE_PATH=.info\distribution\tester_list.txt"
)

if not exist "%FILE_PATH%" (
    call :log_error "Tester list file not found: %FILE_PATH%"
    exit /b 1
)

call :log_step "Adding testers from file to group: %GROUP_NAME%"
call :log_info "File: %FILE_PATH%"

REM Read emails from file and build email list
set "EMAIL_LIST="
set "EMAIL_COUNT=0"

for /f "usebackq tokens=*" %%a in ("%FILE_PATH%") do (
    set "line=%%a"
    if not "!line:~0,1!"=="#" if not "!line!"=="" (
        echo !line! | findstr "@" >nul && (
            if "!EMAIL_LIST!"=="" (
                set "EMAIL_LIST=!line!"
            ) else (
                set "EMAIL_LIST=!EMAIL_LIST!,!line!"
            )
            set /a EMAIL_COUNT+=1
        )
    )
)

if %EMAIL_COUNT% equ 0 (
    call :log_warning "No valid email addresses found in file"
    goto :end
)

call :log_info "Found %EMAIL_COUNT% email addresses"

set "ADD_GROUP_CMD=firebase appdistribution:groups:addtesters %GROUP_NAME% --emails=%EMAIL_LIST% --project=%PROJECT_ID%"

if "%VERBOSE%"=="true" (
    call :log_info "Command: !ADD_GROUP_CMD!"
)

if "%DRY_RUN%"=="true" (
    call :log_info "DRY RUN: !ADD_GROUP_CMD!"
) else (
    !ADD_GROUP_CMD!
    if !errorlevel! equ 0 (
        call :log_success "Testers from file added to group successfully!"
    ) else (
        call :log_error "Failed to add some testers to group"
        exit /b 1
    )
)
goto :end

:remove_file_from_group
if "%GROUP_NAME%"=="" (
    call :log_error "Group name is required for remove-file-from-group command"
    call :log_error "Use --group option"
    exit /b 1
)

if "%FILE_PATH%"=="" (
    set "FILE_PATH=.info\distribution\tester_list.txt"
)

if not exist "%FILE_PATH%" (
    call :log_error "Tester list file not found: %FILE_PATH%"
    exit /b 1
)

call :log_step "Removing testers from file from group: %GROUP_NAME%"
call :log_info "File: %FILE_PATH%"

REM Read emails from file and build email list
set "EMAIL_LIST="
set "EMAIL_COUNT=0"

for /f "usebackq tokens=*" %%a in ("%FILE_PATH%") do (
    set "line=%%a"
    if not "!line:~0,1!"=="#" if not "!line!"=="" (
        echo !line! | findstr "@" >nul && (
            if "!EMAIL_LIST!"=="" (
                set "EMAIL_LIST=!line!"
            ) else (
                set "EMAIL_LIST=!EMAIL_LIST!,!line!"
            )
            set /a EMAIL_COUNT+=1
        )
    )
)

if %EMAIL_COUNT% equ 0 (
    call :log_warning "No valid email addresses found in file"
    goto :end
)

call :log_info "Found %EMAIL_COUNT% email addresses"

set "REMOVE_GROUP_CMD=firebase appdistribution:groups:removetesters %GROUP_NAME% --emails=%EMAIL_LIST% --project=%PROJECT_ID%"

if "%VERBOSE%"=="true" (
    call :log_info "Command: !REMOVE_GROUP_CMD!"
)

if "%DRY_RUN%"=="true" (
    call :log_info "DRY RUN: !REMOVE_GROUP_CMD!"
) else (
    call :log_warning "This will remove testers from the group. Continue? (Y/N)"
    set /p "CONFIRM="
    if /i "!CONFIRM!"=="Y" (
        !REMOVE_GROUP_CMD!
        if !errorlevel! equ 0 (
            call :log_success "Testers from file removed from group successfully!"
        ) else (
            call :log_error "Failed to remove some testers from group"
            exit /b 1
        )
    ) else (
        call :log_info "Operation cancelled"
    )
)
goto :end

:export_testers
if "%FILE_PATH%"=="" (
    call :log_error "File path is required for export command"
    call :log_error "Use --file option"
    exit /b 1
)

call :log_step "Exporting testers to CSV file: %FILE_PATH%"

call :log_warning "Direct export not available via Firebase CLI"
call :log_info "Use 'list' command and manually save the output to a file"
call :log_info "Example: firebase appdistribution:testers:list --project=%PROJECT_ID% > %FILE_PATH%"
goto :end

:end
endlocal
exit /b 0