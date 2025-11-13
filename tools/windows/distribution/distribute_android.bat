@echo off
setlocal enabledelayedexpansion

REM Enhanced Android Distribution Script with Centralized Configuration (Windows)
REM This script distributes Android apps using Firebase App Distribution

REM Get the directory of this script
set "SCRIPT_DIR=%~dp0"

REM Source the common configuration
call "%SCRIPT_DIR%..\common\common.bat"
if %errorlevel% neq 0 (
    echo ❌ Failed to load common configuration
    goto :end
)

REM Function to check prerequisites
call :check_prerequisites
if %errorlevel% neq 0 goto :end

REM Initialize variables
set "FILE_TYPE="
set "FLAVOR="
set "CUSTOM_TESTERS="
set "CUSTOM_GROUPS="
set "CUSTOM_NOTES="

REM Parse command line arguments
:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="apk" (
    set "FILE_TYPE=%~1"
    shift
    goto :parse_args
)
if "%~1"=="aab" (
    set "FILE_TYPE=%~1"
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
if "%~1"=="--testers" (
    set "CUSTOM_TESTERS=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--groups" (
    set "CUSTOM_GROUPS=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--notes" (
    set "CUSTOM_NOTES=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="-h" goto :show_usage
if "%~1"=="--help" goto :show_usage

call :log_error "Unknown option: %~1"
goto :show_usage

:show_usage
echo Usage: %~nx0 [apk^|aab] [dev^|stg^|prod] [options]
echo.
echo Arguments:
echo   apk^|aab                  File type to distribute (required)
echo   dev^|stg^|prod             Build flavor (required)
echo.
echo Options:
echo   --testers ^<emails^>       Override testers list (comma-separated)
echo   --groups ^<names^>         Override groups list (comma-separated)
echo   --notes ^<text^>           Override release notes
echo   -h, --help              Show this help message
echo.
echo Examples:
echo   %~nx0 apk dev
echo   %~nx0 aab prod --testers "user1@example.com,user2@example.com"
echo   %~nx0 apk stg --groups "qa-team,beta-testers"
echo.
echo This script uses centralized configuration from .info\ directory.
goto :end

:args_done

REM Validate required arguments
if "%FILE_TYPE%"=="" (
    call :log_error "File type (apk|aab) is required"
    goto :show_usage
)

if "%FLAVOR%"=="" (
    call :log_error "Flavor (dev|stg|prod) is required"
    goto :show_usage
)

REM Validate inputs
call :validate_flavor "%FLAVOR%"
if %errorlevel% neq 0 goto :end

if "%FILE_TYPE%" neq "apk" if "%FILE_TYPE%" neq "aab" (
    call :log_error "Invalid file type: %FILE_TYPE%"
    echo Supported types: apk, aab
    goto :end
)

REM Show configuration summary
call :show_config_summary "%FLAVOR%" "android"

REM Load Firebase configuration
call :load_firebase_config "%FLAVOR%" "android"
if %errorlevel% neq 0 goto :end

REM Find the APK/AAB file
call :find_app_file "%FLAVOR%" "%FILE_TYPE%"
if %errorlevel% neq 0 goto :end

REM Get version information
call :get_pubspec_version VERSION

REM Generate release notes
if "%CUSTOM_NOTES%" neq "" (
    set "RELEASE_NOTES=%CUSTOM_NOTES%"
    call :log_info "Using custom release notes"
) else (
    call :generate_release_notes "%FLAVOR%" "%VERSION%"
)

REM Distribute the app
call :distribute_app "%FILE_TYPE%"
if %errorlevel% neq 0 goto :end

REM Show success summary
echo.
call :log_success "🎉 Distribution completed successfully!"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo File: %APP_FILE%
echo Type: %FILE_TYPE%
echo Flavor: %FLAVOR%
echo Version: %VERSION%
echo Platform: Android (Windows)
echo Firebase Project: %PROJECT_ID%
echo.
echo Your app has been distributed via Firebase App Distribution!
echo Testers will receive email notifications with download links.
echo.
echo Firebase Console:
echo https://console.firebase.google.com/project/%PROJECT_ID%/appdistribution
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

goto :end

REM ============================================
REM Helper Functions
REM ============================================

:check_prerequisites
call :log_step "Checking prerequisites..."

REM Check if Firebase CLI is installed
where firebase >nul 2>&1
if !errorlevel! neq 0 (
    call :log_error "Firebase CLI is not installed. Please install it first:"
    echo npm install -g firebase-tools
    exit /b 1
)

REM Validate environment
call :validate_environment
if !errorlevel! neq 0 exit /b 1

call :log_success "All prerequisites are met!"
exit /b 0

:load_firebase_config
set "flavor=%~1"
set "platform=%~2"

call :get_firebase_project_id "%flavor%" PROJECT_ID
call :get_firebase_app_id "%platform%" "%flavor%" APP_ID

if "%PROJECT_ID%"=="" if "%PROJECT_ID%"=="null" if "%APP_ID%"=="" if "%APP_ID%"=="null" (
    call :log_error "Firebase configuration not found for flavor: %flavor%, platform: %platform%"
    call :log_info "Please check your .info\app\firebase.json configuration"
    exit /b 1
)

call :log_success "Firebase configuration loaded"
call :log_info "Project ID: %PROJECT_ID%"
call :log_info "App ID: %APP_ID%"
exit /b 0

:find_app_file
set "flavor=%~1"
set "file_type=%~2"

if "%file_type%"=="apk" (
    call :get_output_path "android" "apk" output_path
    REM Look for the APK file
    set "APP_FILE=%output_path%\app-%flavor%-release.apk"
) else (
    call :get_output_path "android" "appbundle" output_path
    REM Look for the AAB file
    set "APP_FILE=%output_path%\app-%flavor%-release.aab"
)

if not exist "%APP_FILE%" (
    call :log_error "%file_type% file not found for flavor: %flavor%"
    call :log_info "Please build the %file_type% first using tools\windows\build\build_%file_type%.bat %flavor%"
    exit /b 1
)

call :log_success "Found %file_type% file: %APP_FILE%"
exit /b 0

:generate_release_notes
set "flavor=%~1"
set "version=%~2"

REM Simple release notes for Windows
set "RELEASE_NOTES=Release for %flavor% environment - Version %version%

Built on: %date% %time%
Platform: Android (Windows build)

call :log_success "Release notes generated"
exit /b 0

:distribute_app
set "file_type=%~1"

call :log_step "Distributing %file_type% to Firebase App Distribution..."

REM Prepare the distribution command
set "FIREBASE_CMD=firebase appdistribution:distribute "%APP_FILE%" --app "%APP_ID%""

REM Add release notes
set "FIREBASE_CMD=%FIREBASE_CMD% --release-notes "%RELEASE_NOTES%""

call :log_info "Executing Firebase distribution command..."
echo Command: %FIREBASE_CMD%

REM Execute the command
%FIREBASE_CMD%

if %errorlevel% equ 0 (
    call :log_success "App distributed successfully!"
) else (
    call :log_error "Failed to distribute app"
    exit /b 1
)
exit /b 0

:end
endlocal