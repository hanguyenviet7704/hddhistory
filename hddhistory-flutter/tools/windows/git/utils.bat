@echo off
setlocal enabledelayedexpansion

REM Git Utility Functions for Windows
REM Common functions used by other git scripts

REM Function to check if git is installed
:check_git_installed
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Git is not installed or not in PATH
    echo Please install Git and try again
    exit /b 1
)
exit /b 0

REM Function to check if we're in a git repository
:check_git_repo
git rev-parse --git-dir >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Not in a git repository
    echo Please run this script from within a git repository
    exit /b 1
)
exit /b 0

REM Function to check if working tree is clean
:check_clean_working_tree
git diff-index --quiet HEAD --
if %errorlevel% neq 0 (
    echo ❌ Working tree is not clean
    echo Please commit or stash your changes first
    git status --porcelain
    exit /b 1
)
exit /b 0

REM Function to get current branch name
:get_current_branch
for /f "tokens=*" %%i in ('git branch --show-current 2^>nul') do (
    set "%~1=%%i"
    exit /b 0
)
set "%~1="
exit /b 1

REM Function to check if branch exists locally
:branch_exists_local
set "branch_name=%~1"
git show-ref --verify --quiet refs/heads/%branch_name%
exit /b %errorlevel%

REM Function to check if branch exists on remote
:branch_exists_remote
set "branch_name=%~1"
git ls-remote --heads origin "%branch_name%" | findstr "%branch_name%" >nul
exit /b %errorlevel%

REM Function to switch to branch (create if doesn't exist)
:switch_to_branch
set "branch_name=%~1"
set "base_branch=%~2"

call :branch_exists_local "%branch_name%"
if %errorlevel% equ 0 (
    echo 🔄 Switching to existing branch: %branch_name%
    git checkout "%branch_name%"
) else (
    if "%base_branch%" neq "" (
        echo 🌿 Creating new branch: %branch_name% from %base_branch%
        git checkout -b "%branch_name%" "%base_branch%"
    ) else (
        echo 🌿 Creating new branch: %branch_name%
        git checkout -b "%branch_name%"
    )
)
exit /b %errorlevel%

REM Function to push branch to remote
:push_to_remote
set "branch_name=%~1"
if "%branch_name%"=="" (
    call :get_current_branch branch_name
)

echo 📤 Pushing %branch_name% to remote...
git push -u origin "%branch_name%"
exit /b %errorlevel%

REM Function to pull latest changes from remote
:pull_from_remote
set "branch_name=%~1"
if "%branch_name%"=="" (
    call :get_current_branch branch_name
)

echo 📥 Pulling latest changes for %branch_name%...
git pull origin "%branch_name%"
exit /b %errorlevel%

REM Function to extract ticket ID from branch name
:extract_ticket_id
set "branch_name=%~1"
set "result_var=%~2"

REM Extract pattern like TG-123, PROJ-456, etc. from feature/TG-123-description
for /f "tokens=2 delims=/" %%i in ("%branch_name%") do (
    for /f "tokens=1,2 delims=-" %%j in ("%%i") do (
        set "%result_var%=%%j-%%k"
        exit /b 0
    )
)
set "%result_var%="
exit /b 1

REM Function to create pull request using GitHub CLI
:create_pull_request
set "source_branch=%~1"
set "target_branch=%~2"
set "pr_title=%~3"
set "pr_body=%~4"

where gh >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️ GitHub CLI not found. Cannot create pull request automatically.
    echo Please create the pull request manually at your repository.
    exit /b 1
)

if "%pr_body%"=="" set "pr_body=Automated pull request from %source_branch%"

echo 🔗 Creating pull request: %pr_title%
gh pr create --title "%pr_title%" --body "%pr_body%" --base "%target_branch%" --head "%source_branch%"
exit /b %errorlevel%

REM Function to get version from pubspec.yaml
:get_version_from_pubspec
set "result_var=%~1"
set "pubspec_file=pubspec.yaml"

if not exist "%pubspec_file%" (
    set "%result_var%="
    exit /b 1
)

for /f "tokens=2" %%i in ('findstr "^version:" "%pubspec_file%"') do (
    set "version=%%i"
    REM Remove any comments
    for /f "tokens=1 delims=#" %%j in ("!version!") do (
        set "version=%%j"
        set "version=!version: =!"
        set "%result_var%=!version!"
        exit /b 0
    )
)
set "%result_var%="
exit /b 1

REM Function to validate branch name format
:validate_branch_name
set "branch_name=%~1"
set "pattern=%~2"

echo %branch_name% | findstr /r "%pattern%" >nul
exit /b %errorlevel%

REM Function to get last commit message
:get_last_commit_message
set "result_var=%~1"
for /f "tokens=*" %%i in ('git log -1 --pretty=format:"%%s" 2^>nul') do (
    set "%result_var%=%%i"
    exit /b 0
)
set "%result_var%="
exit /b 1

REM Function to check if current branch is ahead of remote
:is_ahead_of_remote
set "branch_name=%~1"
if "%branch_name%"=="" (
    call :get_current_branch branch_name
)

for /f %%i in ('git rev-list --count origin/%branch_name%..HEAD 2^>nul') do (
    if %%i gtr 0 (
        exit /b 0
    ) else (
        exit /b 1
    )
)
exit /b 1

REM Function to check if current branch is behind remote
:is_behind_remote
set "branch_name=%~1"
if "%branch_name%"=="" (
    call :get_current_branch branch_name
)

for /f %%i in ('git rev-list --count HEAD..origin/%branch_name% 2^>nul') do (
    if %%i gtr 0 (
        exit /b 0
    ) else (
        exit /b 1
    )
)
exit /b 1

REM Function to display git status summary
:show_git_status
echo 📊 Git Status Summary:
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━

call :get_current_branch current_branch
echo Branch: %current_branch%

call :is_ahead_of_remote "%current_branch%"
if %errorlevel% equ 0 (
    echo Status: ⬆️ Ahead of remote
) else (
    call :is_behind_remote "%current_branch%"
    if %errorlevel% equ 0 (
        echo Status: ⬇️ Behind remote
    ) else (
        echo Status: ✅ Up to date
    )
)

git status --porcelain | find /c /v "" >nul
if %errorlevel% equ 0 (
    echo Changes: ✅ Clean working tree
) else (
    echo Changes: ⚠️ Uncommitted changes
)

echo ━━━━━━━━━━━━━━━━━━━━━━━━━━
exit /b 0

REM Entry point - show available functions if called directly
:main
if "%~0"=="%~nx0" (
    echo Git Utility Functions for Windows
    echo ================================
    echo.
    echo Available functions:
    echo   :check_git_installed
    echo   :check_git_repo
    echo   :check_clean_working_tree
    echo   :get_current_branch
    echo   :branch_exists_local
    echo   :branch_exists_remote
    echo   :switch_to_branch
    echo   :push_to_remote
    echo   :pull_from_remote
    echo   :extract_ticket_id
    echo   :create_pull_request
    echo   :get_version_from_pubspec
    echo   :validate_branch_name
    echo   :show_git_status
    echo.
    echo Usage: call "%~nx0" from other batch files
    REM Pause for user removed for automation
)
exit /b 0

REM Run main if script is executed directly
if "%~0"=="%~nx0" call :main