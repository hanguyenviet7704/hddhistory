@echo off
setlocal enabledelayedexpansion

:: Define the root directory
set "ROOT_DIR=%~dp0..\..\.."

:: Load common configuration functions
call "%ROOT_DIR%\tools\windows\common\common.bat"
IF %ERRORLEVEL% NEQ 0 (
    echo Failed to load common configuration library.
    exit /b 1
)

:: Navigate to the root directory
cd /d "%ROOT_DIR%"
IF %ERRORLEVEL% NEQ 0 (
    call :log_error "Failed to navigate to the root directory."
    exit /b 1
)

:: Get the dart command based on version manager configuration
call :get_dart_command DART_CMD

:: Define the build_runner command
set "BUILD_RUNNER_CMD=%DART_CMD% run build_runner build --delete-conflicting-outputs"

call :log_info "Using command: %BUILD_RUNNER_CMD%"

:: Run the build_runner command
call :log_step "Running build_runner to generate api files..."
call :log_step "Running build_runner to generate models files..."
call :log_step "Running build_runner to generate resources files..."
call %BUILD_RUNNER_CMD%
IF %ERRORLEVEL% NEQ 0 (
    call :log_error "build_runner command failed."
    exit /b 1
)

call :log_success "Build_runner generation complete."

:: Exit the script
exit /b 0
