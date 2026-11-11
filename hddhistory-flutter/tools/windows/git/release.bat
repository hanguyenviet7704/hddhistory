@echo off
setlocal enabledelayedexpansion

REM Enhanced Release Management Script for Windows
REM This script helps manage release branches following GitFlow patterns

REM Navigate to the root directory
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\..\..\"
cd /d "%ROOT_DIR%"
if %errorlevel% neq 0 (
    echo ❌ Failed to navigate to the project root directory.
    exit /b 1
)

REM Load utilities
call "%SCRIPT_DIR%utils.bat"

REM Parse command and arguments
set "COMMAND=%~1"
set "VERSION=%~2"

if "%COMMAND%"=="" goto :show_usage
if "%COMMAND%"=="help" goto :show_usage

REM Validate git environment
call :check_git_installed
if %errorlevel% neq 0 exit /b 1

call :check_git_repo
if %errorlevel% neq 0 exit /b 1

goto :handle_command

:show_usage
echo Usage: %~nx0 ^<command^> [version]
echo.
echo Commands:
echo   start [version]     Start a new release branch
echo   finish              Finish current release branch
echo   publish             Push release branch to remote
echo   list                List all release branches
echo   help                Show this help message
echo.
echo Examples:
echo   %~nx0 start 1.2.0
echo   %~nx0 start         # Auto-detect version from pubspec.yaml
echo   %~nx0 finish
echo   %~nx0 publish
echo.
echo Note: Follows GitFlow conventions with release/ prefix
goto :end

:handle_command
if "%COMMAND%"=="start" goto :start_release
if "%COMMAND%"=="finish" goto :finish_release
if "%COMMAND%"=="publish" goto :publish_release
if "%COMMAND%"=="list" goto :list_releases

echo ❌ Unknown command: %COMMAND%
goto :show_usage

:start_release
REM Get version from argument or pubspec.yaml
if "%VERSION%"=="" (
    call :get_version_from_pubspec VERSION
    if "%VERSION%"=="" (
        echo ❌ Could not determine version. Please specify version or check pubspec.yaml
        echo Usage: %~nx0 start ^<version^>
        exit /b 1
    )
    echo 📋 Auto-detected version from pubspec.yaml: %VERSION%
)

set "BRANCH_NAME=release/%VERSION%"

echo 🚀 Starting new release: %BRANCH_NAME%

REM Check if release branch already exists
call :branch_exists_local "%BRANCH_NAME%"
if %errorlevel% equ 0 (
    echo ❌ Release branch already exists: %BRANCH_NAME%
    echo Use 'git checkout %BRANCH_NAME%' to switch to it
    exit /b 1
)

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

REM Ensure working tree is clean
call :check_clean_working_tree
if %errorlevel% neq 0 exit /b 1

REM Create release branch
echo 🌿 Creating release branch: %BRANCH_NAME%
git checkout -b "%BRANCH_NAME%"
if %errorlevel% neq 0 (
    echo ❌ Failed to create release branch
    exit /b 1
)

echo ✅ Release branch created: %BRANCH_NAME%
echo.
echo 📝 Next steps:
echo   1. Update version numbers if needed
echo   2. Update CHANGELOG.md
echo   3. Test the release
echo   4. Commit any final changes
echo   5. Run: %~nx0 finish
goto :end

:finish_release
REM Get current branch
call :get_current_branch CURRENT_BRANCH

echo %CURRENT_BRANCH% | findstr /r "^release/" >nul
if %errorlevel% neq 0 (
    echo ❌ Error: Not on a release branch
    echo Current branch: %CURRENT_BRANCH%
    exit /b 1
)

REM Extract version from branch name
for /f "tokens=2 delims=/" %%i in ("%CURRENT_BRANCH%") do set "RELEASE_VERSION=%%i"

echo 🏁 Finishing release: %CURRENT_BRANCH% (v%RELEASE_VERSION%)

REM Ensure working tree is clean
call :check_clean_working_tree
if %errorlevel% neq 0 exit /b 1

REM Push release branch to remote if not already there
call :branch_exists_remote "%CURRENT_BRANCH%"
if %errorlevel% neq 0 (
    echo 📤 Pushing release branch to remote...
    git push -u origin "%CURRENT_BRANCH%"
    if %errorlevel% neq 0 (
        echo ❌ Failed to push release branch to remote
        exit /b 1
    )
)

REM Merge to main/master
echo 🔄 Fetching latest main branch...
git fetch origin main 2>nul || git fetch origin master
if %errorlevel% neq 0 (
    echo ⚠️ Could not fetch main/master branch
)

echo 🔀 Merging release to main...
git checkout main 2>nul || git checkout master
if %errorlevel% neq 0 (
    echo ❌ Failed to checkout main/master branch
    exit /b 1
)

git merge --no-ff "%CURRENT_BRANCH%" -m "release-v%RELEASE_VERSION%: Merge release branch"
if %errorlevel% neq 0 (
    echo ❌ Failed to merge release to main
    echo Please resolve conflicts manually
    exit /b 1
)

REM Create release tag
echo 🏷️ Creating release tag: v%RELEASE_VERSION%
git tag -a "v%RELEASE_VERSION%" -m "Release version %RELEASE_VERSION%"
if %errorlevel% neq 0 (
    echo ⚠️ Failed to create tag
)

REM Merge back to develop
echo 🔀 Merging changes back to develop...
git checkout develop
if %errorlevel% neq 0 (
    echo ❌ Failed to checkout develop branch
    exit /b 1
)

git merge --no-ff "%CURRENT_BRANCH%" -m "release-v%RELEASE_VERSION%: Merge release changes to develop"
if %errorlevel% neq 0 (
    echo ⚠️ Failed to merge release to develop. Please resolve manually.
)

REM Push everything
echo 📤 Pushing all changes...
git checkout main 2>nul || git checkout master
git push origin main 2>nul || git push origin master
git push origin "v%RELEASE_VERSION%"

git checkout develop
git push origin develop

REM Clean up local release branch
echo 🧹 Cleaning up release branch...
git branch -d "%CURRENT_BRANCH%"

echo ✅ Release v%RELEASE_VERSION% completed successfully!
echo.
echo 📝 Summary:
echo   - Release merged to main
echo   - Changes merged back to develop
echo   - Tag v%RELEASE_VERSION% created
echo   - Release branch deleted locally
echo.
echo 🚀 Next steps:
echo   1. Create GitHub release from tag v%RELEASE_VERSION%
echo   2. Update release notes
echo   3. Deploy to production
goto :end

:publish_release
call :get_current_branch CURRENT_BRANCH

echo %CURRENT_BRANCH% | findstr /r "^release/" >nul
if %errorlevel% neq 0 (
    echo ❌ Error: Not on a release branch
    echo Current branch: %CURRENT_BRANCH%
    exit /b 1
)

echo 📤 Publishing release: %CURRENT_BRANCH%

git push -u origin "%CURRENT_BRANCH%"
if %errorlevel% equ 0 (
    echo ✅ Release branch published to remote
) else (
    echo ❌ Failed to publish release branch
    exit /b 1
)
goto :end

:list_releases
echo 📋 Local release branches:
git branch | findstr "release/"
echo.
echo 📡 Remote release branches:
git branch -r | findstr "origin/release/"
echo.
echo 🏷️ Recent release tags:
git tag | findstr "^v[0-9]" | powershell "Get-Content | Sort-Object {[version]($_ -replace '^v','')} | Select-Object -Last 10"
goto :end

:end
endlocal