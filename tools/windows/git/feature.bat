@echo off
setlocal enabledelayedexpansion

REM Enhanced Feature Branch Management Script for Windows
REM This script helps manage feature branches following GitFlow patterns

REM Navigate to the root directory
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\..\..\"
cd /d "%ROOT_DIR%"
if %errorlevel% neq 0 (
    echo ❌ Failed to navigate to the project root directory.
    exit /b 1
)

REM Load common utilities
call "%SCRIPT_DIR%utils.bat" 2>nul

REM Parse command and arguments
set "COMMAND=%~1"
set "TICKET_ID=%~2"
set "DESCRIPTION=%~3"

if "%COMMAND%"=="" goto :show_usage
if "%COMMAND%"=="help" goto :show_usage

goto :handle_command

:show_usage
echo Usage: %~nx0 ^<command^> [options]
echo.
echo Commands:
echo   start ^<ticket-id^> ^<description^>  Start a new feature branch
echo   finish                            Finish current feature branch
echo   publish                           Push feature branch to remote
echo   list                              List all feature branches
echo   help                              Show this help message
echo.
echo Examples:
echo   %~nx0 start TG-123 login-social
echo   %~nx0 finish
echo   %~nx0 publish
echo.
echo Note: Follows GitFlow conventions with feature/ prefix
goto :end

:handle_command
if "%COMMAND%"=="start" goto :start_feature
if "%COMMAND%"=="finish" goto :finish_feature
if "%COMMAND%"=="publish" goto :publish_feature
if "%COMMAND%"=="list" goto :list_features

echo ❌ Unknown command: %COMMAND%
goto :show_usage

:start_feature
if "%TICKET_ID%"=="" (
    echo ❌ Error: Missing ticket ID or description
    echo Usage: %~nx0 start ^<ticket-id^> ^<description^>
    exit /b 1
)
if "%DESCRIPTION%"=="" (
    echo ❌ Error: Missing description
    echo Usage: %~nx0 start ^<ticket-id^> ^<description^>
    exit /b 1
)

set "BRANCH_NAME=feature/%TICKET_ID%-%DESCRIPTION%"

echo 🚀 Starting new feature: %BRANCH_NAME%

REM Ensure we're on develop and up to date
echo 🔄 Switching to develop branch...
git checkout develop
if %errorlevel% neq 0 (
    echo ❌ Failed to checkout develop branch
    exit /b 1
)

echo 📥 Pulling latest changes from develop...
git pull origin develop
if %errorlevel% neq 0 (
    echo ⚠️ Failed to pull from develop. Continuing with local develop.
)

REM Create and checkout new feature branch
echo 🌿 Creating feature branch: %BRANCH_NAME%
git checkout -b "%BRANCH_NAME%"
if %errorlevel% neq 0 (
    echo ❌ Failed to create feature branch
    exit /b 1
)

echo ✅ Feature branch created: %BRANCH_NAME%
echo 💡 You can now start working on your feature
echo.
echo Next steps:
echo   1. Make your changes
echo   2. Commit your work: git add . && git commit -m "your message"
echo   3. When ready: %~nx0 finish
goto :end

:finish_feature
REM Get current branch
for /f "tokens=*" %%i in ('git branch --show-current') do set "CURRENT_BRANCH=%%i"

echo %CURRENT_BRANCH% | findstr /r "^feature/" >nul
if %errorlevel% neq 0 (
    echo ❌ Error: Not on a feature branch
    echo Current branch: %CURRENT_BRANCH%
    exit /b 1
)

echo 🏁 Finishing feature: %CURRENT_BRANCH%

REM Check if there are uncommitted changes
call :check_clean_working_tree
if %errorlevel% neq 0 exit /b 1

REM Extract ticket ID from branch name
call :extract_ticket_id "%CURRENT_BRANCH%" TICKET_ID

REM Make sure develop is up to date
echo 📡 Fetching latest develop...
git fetch origin develop
if %errorlevel% neq 0 (
    echo ⚠️ Failed to fetch develop. Continuing with local develop.
)

REM Push current branch to remote if it's not already there
call :branch_exists_remote "%CURRENT_BRANCH%" REMOTE_EXISTS
if "%REMOTE_EXISTS%"=="false" (
    echo 📤 Pushing feature branch to remote...
    git push -u origin "%CURRENT_BRANCH%"
    if %errorlevel% neq 0 (
        echo ❌ Failed to push branch to remote
        exit /b 1
    )
) else (
    echo 📝 Feature branch already exists on remote

    REM Make sure local branch is up to date with remote
    echo 🔄 Updating local branch from remote...
    git pull origin "%CURRENT_BRANCH%"
    if %errorlevel% neq 0 (
        echo ⚠️ Failed to pull from remote. Continuing with local changes.
    )
)

REM Create PR title based on branch name
for /f "tokens=2 delims=-" %%i in ("%CURRENT_BRANCH%") do set "BRANCH_DESCRIPTION=%%i"
if "%BRANCH_DESCRIPTION%"=="" set "BRANCH_DESCRIPTION=%CURRENT_BRANCH:feature/=%"

REM Convert description for PR title
set "PR_TITLE=feature-%TICKET_ID%: %BRANCH_DESCRIPTION%"
set "PR_TITLE=!PR_TITLE:-= !"

REM Create pull request (if GitHub CLI is available)
echo 🔗 Creating pull request...
where gh >nul 2>&1
if %errorlevel% equ 0 (
    gh pr create --title "%PR_TITLE%" --body "Feature implementation for %TICKET_ID%" --base develop --head "%CURRENT_BRANCH%"
    if %errorlevel% equ 0 (
        echo ✅ Pull request created successfully!
    ) else (
        echo ⚠️ Failed to create pull request via GitHub CLI
        call :show_manual_pr_instructions
    )
) else (
    echo ⚠️ GitHub CLI not found
    call :show_manual_pr_instructions
)

echo ✅ Feature completed and ready for review!
echo 💡 After the pull request is approved and merged, you can delete your local branch with:
echo    git branch -d %CURRENT_BRANCH%
goto :end

:publish_feature
for /f "tokens=*" %%i in ('git branch --show-current') do set "CURRENT_BRANCH=%%i"

echo %CURRENT_BRANCH% | findstr /r "^feature/" >nul
if %errorlevel% neq 0 (
    echo ❌ Error: Not on a feature branch
    echo Current branch: %CURRENT_BRANCH%
    exit /b 1
)

echo 📤 Publishing feature: %CURRENT_BRANCH%

git push -u origin "%CURRENT_BRANCH%"
if %errorlevel% equ 0 (
    echo ✅ Feature branch published to remote
) else (
    echo ❌ Failed to publish feature branch
    exit /b 1
)
goto :end

:list_features
echo 📋 Local feature branches:
git branch | findstr "feature/"
echo.
echo 📡 Remote feature branches:
git branch -r | findstr "origin/feature/"
goto :end

REM ============================================
REM Helper Functions
REM ============================================

:check_clean_working_tree
git diff-index --quiet HEAD --
if %errorlevel% neq 0 (
    echo ❌ Error: You have uncommitted changes
    echo Please commit or stash your changes before finishing the feature
    git status --porcelain
    exit /b 1
)
exit /b 0

:extract_ticket_id
set "branch_name=%~1"
set "result_var=%~2"

REM Extract ticket ID pattern like TG-123, PROJ-456, etc.
for /f "tokens=2 delims=/" %%i in ("%branch_name%") do (
    for /f "tokens=1 delims=-" %%j in ("%%i") do (
        for /f "tokens=2 delims=-" %%k in ("%%i") do (
            set "%result_var%=%%j-%%k"
            exit /b 0
        )
    )
)
set "%result_var%="
exit /b 0

:branch_exists_remote
set "branch_name=%~1"
set "result_var=%~2"

git ls-remote --heads origin "%branch_name%" | findstr "%branch_name%" >nul
if %errorlevel% equ 0 (
    set "%result_var%=true"
) else (
    set "%result_var%=false"
)
exit /b 0

:show_manual_pr_instructions
echo.
echo 📝 Manual Pull Request Instructions:
echo 1. Open your repository in a web browser
echo 2. Navigate to Pull Requests section
echo 3. Click "New Pull Request"
echo 4. Select base: develop, compare: %CURRENT_BRANCH%
echo 5. Title: %PR_TITLE%
echo 6. Add description and submit for review
echo.
echo Alternatively, install GitHub CLI for automated PR creation:
echo https://cli.github.com/
exit /b 0

:end
endlocal