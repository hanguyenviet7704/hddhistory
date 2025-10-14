@echo off
setlocal enabledelayedexpansion

REM Git Setup Script for Windows
REM Sets up GitFlow workflow for the project

REM Navigate to the root directory relative to the current script location
set "SCRIPT_DIR=%~dp0"
set "ROOT_DIR=%SCRIPT_DIR%..\..\..\"
cd /d "%ROOT_DIR%" || (
    echo ❌ Failed to navigate to the project root directory.
    exit /b 1
)

echo 🚀 Setting up GitFlow workflow for the project (Windows)...
echo 📍 Project root: %CD%

REM Check if we're in a git repository
if not exist ".git" (
    echo ❌ Not a git repository. Please run 'git init' first.
    exit /b 1
)

REM Create hooks directory if it doesn't exist
if not exist ".git\hooks" mkdir ".git\hooks"

REM Create a simple commit-msg hook
echo 📝 Installing commit message validation hook...
(
echo @echo off
echo REM Simple commit message validation
echo.
echo set "commit_file=%%1"
echo for /f "delims=" %%%%i in ^(%%commit_file%%^) do ^(
echo     set "commit_msg=%%%%i"
echo     goto :validate
echo ^)
echo.
echo :validate
echo echo %%commit_msg%% ^| findstr /r "^feat.*:" ^>nul ^|^| ^(
echo echo %%commit_msg%% ^| findstr /r "^fix.*:" ^>nul ^|^| ^(
echo echo %%commit_msg%% ^| findstr /r "^docs.*:" ^>nul ^|^| ^(
echo echo %%commit_msg%% ^| findstr /r "^style.*:" ^>nul ^|^| ^(
echo echo %%commit_msg%% ^| findstr /r "^refactor.*:" ^>nul ^|^| ^(
echo echo %%commit_msg%% ^| findstr /r "^test.*:" ^>nul ^|^| ^(
echo echo %%commit_msg%% ^| findstr /r "^chore.*:" ^>nul ^|^| ^(
echo     echo Invalid commit message format!
echo     echo Format should be: type^(scope^): description
echo     echo Types: feat, fix, docs, style, refactor, test, chore
echo     echo Example: feat^(auth^): add login functionality
echo     exit /b 1
echo ^)^)^)^)^)^)^)
) > ".git\hooks\commit-msg.bat"

REM Initialize git flow branches if they don't exist
echo 🌿 Checking branch structure...
git show-ref --verify --quiet refs/heads/main
if %errorlevel% neq 0 (
    echo Creating main branch...
    git checkout -b main 2>nul || echo Main branch already exists or checkout failed
)

git show-ref --verify --quiet refs/heads/develop
if %errorlevel% neq 0 (
    echo Creating develop branch...
    git checkout -b develop 2>nul || echo Develop branch already exists or checkout failed
)

REM Create local config for git flow
echo ⚙️  Configuring GitFlow settings...
git config gitflow.branch.master main
git config gitflow.branch.develop develop
git config gitflow.prefix.feature feature/
git config gitflow.prefix.release release/
git config gitflow.prefix.hotfix hotfix/
git config gitflow.prefix.support support/
git config gitflow.prefix.versiontag v

echo ✅ GitFlow setup completed successfully!
echo.
echo 📚 Available commands:
echo   - tools\windows\git\utils.bat    : Git utility functions
echo.
echo 💡 Note: This is a simplified setup for Windows
echo     For full GitFlow functionality, install Git Flow for Windows:
echo     https://github.com/nvie/gitflow/wiki/Windows
echo.
echo 🚀 You can now start development with:
echo     git checkout develop
echo     git checkout -b feature/your-feature-name

REM Pause for user removed for automation
exit /b 0