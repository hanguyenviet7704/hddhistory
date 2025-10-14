@echo off
setlocal

:: Define the root directory
set "ROOT_DIR=%~dp0..\..\.."

:: Define the build_runner command
set "BUILD_RUNNER_CMD=fvm dart run build_runner build --delete-conflicting-outputs"

:: Navigate to the root directory
cd /d "%ROOT_DIR%"
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to navigate to the root directory.
    exit /b 1
)

:: Run the build_runner command
echo Running build_runner to generate api files...
echo Running build_runner to generate models files...
echo Running build_runner to generate resources files...
call %BUILD_RUNNER_CMD%
IF %ERRORLEVEL% NEQ 0 (
    echo build_runner command failed.
    exit /b 1
)

echo Build_runner generation complete.

:: Exit the script
exit /b 0
