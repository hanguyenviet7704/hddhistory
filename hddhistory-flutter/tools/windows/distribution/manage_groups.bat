@echo off
setlocal enabledelayedexpansion

REM Firebase App Distribution - Group Management with Centralized Configuration (Windows)
REM This script provides comprehensive group management for Firebase App Distribution

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
set "FLAVOR="
set "DESCRIPTION="
set "ADD_TESTERS="
set "FILE_PATH="
set "DRY_RUN=false"
set "VERBOSE=false"
set "GROUP_NAME="
set "GROUP_ALIAS="

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="list" (
    set "COMMAND=%~1"
    shift
    goto :parse_args
)
if "%~1"=="create" (
    set "COMMAND=%~1"
    set "GROUP_NAME=%~2"
    set "GROUP_ALIAS=%~3"
    shift
    shift
    if not "%~3"=="" shift
    goto :parse_args
)
if "%~1"=="delete" (
    set "COMMAND=%~1"
    set "GROUP_ALIAS=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="show" (
    set "COMMAND=%~1"
    set "GROUP_ALIAS=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="sync" (
    set "COMMAND=%~1"
    shift
    goto :parse_args
)
if "%~1"=="sync-from-file" (
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
if "%~1"=="--flavor" (
    set "FLAVOR=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--description" (
    set "DESCRIPTION=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--add-testers" (
    set "ADD_TESTERS=%~2"
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
echo   list                      List all distribution groups
echo   create ^<name^> [alias]     Create a new distribution group
echo   delete ^<alias^>            Delete a distribution group
echo   show ^<alias^>              Show group details and members
echo   sync                      Sync groups from configuration
echo   sync-from-file            Sync groups from tester_group.txt file
echo.
echo Options:
echo   --project ^<id^>            Firebase project ID (uses config if not specified)
echo   --flavor ^<dev^|stg^|prod^>   Environment flavor for configuration
echo   --description ^<text^>      Group description (for create)
echo   --add-testers ^<emails^>    Add testers when creating group
echo   --file ^<path^>             Path to tester_group.txt file
echo   --dry-run                 Show commands without executing
echo   --verbose                 Show detailed output
echo   -h, --help               Show this help message
echo.
echo Examples:
echo   %~nx0 list
echo   %~nx0 create "QA Team" qa-team
echo   %~nx0 delete qa-team
echo   %~nx0 show qa-team
echo   %~nx0 sync --flavor dev
echo   %~nx0 sync-from-file --file .info\distribution\tester_group.txt
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

REM Set default file path for tester groups
if "%FILE_PATH%"=="" (
    set "FILE_PATH=.info\distribution\tester_group.txt"
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
if "%COMMAND%"=="list" goto :list_groups
if "%COMMAND%"=="create" goto :create_group
if "%COMMAND%"=="delete" goto :delete_group
if "%COMMAND%"=="show" goto :show_group
if "%COMMAND%"=="sync" goto :sync_groups
if "%COMMAND%"=="sync-from-file" goto :sync_from_file

call :log_error "Unknown command: %COMMAND%"
exit /b 1

:list_groups
call :log_step "Listing Firebase App Distribution groups..."

if "%DRY_RUN%"=="true" (
    call :log_info "DRY RUN: firebase appdistribution:groups:list --project=%PROJECT_ID%"
) else (
    firebase appdistribution:groups:list --project=%PROJECT_ID%
    if !errorlevel! neq 0 (
        call :log_error "Failed to list groups"
        exit /b 1
    )
)
goto :end

:create_group
if "%GROUP_NAME%"=="" (
    call :log_error "Group name is required for create command"
    exit /b 1
)

if "%GROUP_ALIAS%"=="" (
    REM Generate alias from name (simple conversion)
    set "GROUP_ALIAS=%GROUP_NAME%"
    set "GROUP_ALIAS=!GROUP_ALIAS: =-!"
    for %%i in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
        set "GROUP_ALIAS=!GROUP_ALIAS:%%i=%%i!"
    )
    set "GROUP_ALIAS=!GROUP_ALIAS: =!"
    call :log_info "Generated alias: !GROUP_ALIAS!"
)

call :log_step "Creating Firebase App Distribution group..."
call :log_info "Name: %GROUP_NAME%"
call :log_info "Alias: %GROUP_ALIAS%"

set "CREATE_CMD=firebase appdistribution:groups:create %GROUP_ALIAS% --display-name "%GROUP_NAME%" --project=%PROJECT_ID%"

if not "%DESCRIPTION%"=="" (
    set "CREATE_CMD=!CREATE_CMD! --description "%DESCRIPTION%""
)

if "%VERBOSE%"=="true" (
    call :log_info "Command: !CREATE_CMD!"
)

if "%DRY_RUN%"=="true" (
    call :log_info "DRY RUN: !CREATE_CMD!"
) else (
    !CREATE_CMD!
    if !errorlevel! neq 0 (
        call :log_error "Failed to create group"
        exit /b 1
    )
    call :log_success "Group created successfully!"

    REM Add testers if specified
    if not "%ADD_TESTERS%"=="" (
        call :log_info "Adding testers to group..."
        firebase appdistribution:groups:addtesters %GROUP_ALIAS% --emails=%ADD_TESTERS% --project=%PROJECT_ID%
        if !errorlevel! equ 0 (
            call :log_success "Testers added to group"
        ) else (
            call :log_warning "Failed to add some testers"
        )
    )
)
goto :end

:delete_group
if "%GROUP_ALIAS%"=="" (
    call :log_error "Group alias is required for delete command"
    exit /b 1
)

call :log_step "Deleting Firebase App Distribution group: %GROUP_ALIAS%"

set "DELETE_CMD=firebase appdistribution:groups:delete %GROUP_ALIAS% --project=%PROJECT_ID%"

if "%VERBOSE%"=="true" (
    call :log_info "Command: !DELETE_CMD!"
)

if "%DRY_RUN%"=="true" (
    call :log_info "DRY RUN: !DELETE_CMD!"
) else (
    call :log_warning "This will permanently delete the group. Continue? (Y/N)"
    set /p "CONFIRM="
    if /i "!CONFIRM!"=="Y" (
        !DELETE_CMD!
        if !errorlevel! equ 0 (
            call :log_success "Group deleted successfully!"
        ) else (
            call :log_error "Failed to delete group"
            exit /b 1
        )
    ) else (
        call :log_info "Operation cancelled"
    )
)
goto :end

:show_group
if "%GROUP_ALIAS%"=="" (
    call :log_error "Group alias is required for show command"
    exit /b 1
)

call :log_step "Showing Firebase App Distribution group details: %GROUP_ALIAS%"

if "%DRY_RUN%"=="true" (
    call :log_info "DRY RUN: firebase appdistribution:groups:show %GROUP_ALIAS% --project=%PROJECT_ID%"
) else (
    firebase appdistribution:groups:show %GROUP_ALIAS% --project=%PROJECT_ID%
    if !errorlevel! neq 0 (
        call :log_error "Failed to show group details"
        exit /b 1
    )
)
goto :end

:sync_groups
call :log_step "Syncing groups from centralized configuration..."

if "%FLAVOR%"=="" (
    call :log_error "Flavor is required for sync command"
    call :log_error "Use --flavor dev|stg|prod"
    exit /b 1
)

call :validate_flavor "%FLAVOR%"
if %errorlevel% neq 0 exit /b 1

call :log_info "Syncing groups for %FLAVOR% environment"
call :log_warning "Group sync from centralized config not fully implemented for Windows"
call :log_info "Use 'sync-from-file' command with tester_group.txt file instead"
goto :end

:sync_from_file
call :log_step "Syncing groups from file: %FILE_PATH%"

if not exist "%FILE_PATH%" (
    call :log_error "Tester group file not found: %FILE_PATH%"
    call :log_info "Create the file using: tools\windows\distribution\manage_distribution_data.bat init"
    exit /b 1
)

call :log_info "Reading groups from: %FILE_PATH%"
set "GROUP_COUNT=0"

for /f "usebackq tokens=*" %%a in ("%FILE_PATH%") do (
    set "line=%%a"
    REM Skip comments and empty lines
    if not "!line:~0,1!"=="#" if not "!line!"=="" (
        set /a GROUP_COUNT+=1
        call :log_info "Processing group: !line!"

        if "%DRY_RUN%"=="true" (
            call :log_info "DRY RUN: Would create group '!line!'"
        ) else (
            REM Attempt to create group
            firebase appdistribution:groups:create "!line!" --display-name "!line!" --project=%PROJECT_ID% >nul 2>&1
            if !errorlevel! equ 0 (
                call :log_success "Created group: !line!"
            ) else (
                call :log_warning "Group may already exist: !line!"
            )
        )
    )
)

if %GROUP_COUNT% equ 0 (
    call :log_warning "No groups found in file (excluding comments)"
) else (
    call :log_success "Processed %GROUP_COUNT% groups from file"
)
goto :end

:end
endlocal
exit /b 0