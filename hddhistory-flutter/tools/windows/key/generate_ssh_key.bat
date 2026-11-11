@echo off
setlocal enabledelayedexpansion

REM Enhanced SSH Key Generation Script with Centralized Configuration (Windows)
REM This script generates SSH keys for Git authentication using configuration from .info\ directory

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

REM Parse command line arguments
set "INTERACTIVE=true"
set "KEY_TYPE=ed25519"
set "CUSTOM_KEY_NAME="
set "CUSTOM_EMAIL="

:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="--non-interactive" (
    set "INTERACTIVE=false"
    shift
    goto :parse_args
)
if "%~1"=="--key-type" (
    set "KEY_TYPE=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--key-name" (
    set "CUSTOM_KEY_NAME=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--email" (
    set "CUSTOM_EMAIL=%~2"
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
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   --non-interactive     Run without user prompts (use defaults)
echo   --key-type ^<type^>     SSH key type (ed25519, rsa, default: ed25519)
echo   --key-name ^<name^>     Custom key name (default: git_ssh_key)
echo   --email ^<email^>       Email for key comment (uses Git config if available)
echo   -h, --help           Show this help message
echo.
echo This script uses centralized configuration from .info\ directory.
echo.
echo Examples:
echo   %~nx0                                    Interactive mode
echo   %~nx0 --non-interactive                  Use all defaults
echo   %~nx0 --key-type rsa --key-name my_key   Custom key type and name
exit /b 0

:args_done

REM Validate environment
call :validate_environment
if %errorlevel% neq 0 exit /b 1

REM Get app information for SSH key generation
call :get_app_name APP_NAME
call :get_pubspec_version VERSION

cls
call :log_info "🔑 SSH Key Generation with Centralized Configuration"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo App: %APP_NAME%
echo Version: %VERSION%
echo Purpose: Git authentication (GitHub/GitLab)
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

REM Default values
set "DEFAULT_KEY_NAME=git_ssh_key"
set "DEFAULT_PASSPHRASE=git_ssh_pass"
set "DEFAULT_EMAIL="

REM Get Git user email if available
call :log_step "Detecting Git configuration..."
for /f "tokens=*" %%i in ('git config --global user.email 2^>nul') do set "DEFAULT_EMAIL=%%i"

if not "%DEFAULT_EMAIL%"=="" (
    call :log_success "Found Git email: %DEFAULT_EMAIL%"
) else (
    call :log_warning "No Git email configured"
    call :log_info "Consider setting: git config --global user.email your@email.com"
)

REM Determine final values
if not "%CUSTOM_KEY_NAME%"=="" (
    set "KEY_NAME=%CUSTOM_KEY_NAME%"
) else (
    set "KEY_NAME=%DEFAULT_KEY_NAME%"
)

if not "%CUSTOM_EMAIL%"=="" (
    set "EMAIL=%CUSTOM_EMAIL%"
) else (
    set "EMAIL=%DEFAULT_EMAIL%"
)

set "PASSPHRASE=%DEFAULT_PASSPHRASE%"

REM Interactive mode - get user preferences
if "%INTERACTIVE%"=="true" (
    echo.
    call :log_step "SSH Key Configuration"

    set /p "INPUT_KEY_NAME=Enter key name [%KEY_NAME%]: "
    if not "!INPUT_KEY_NAME!"=="" set "KEY_NAME=!INPUT_KEY_NAME!"

    set /p "INPUT_EMAIL=Enter email for key comment [%EMAIL%]: "
    if not "!INPUT_EMAIL!"=="" set "EMAIL=!INPUT_EMAIL!"

    echo.
    echo Key type options:
    echo   1. ed25519 (recommended, modern)
    echo   2. rsa (compatible, larger)
    set /p "KEY_TYPE_CHOICE=Choose key type [1]: "
    if "!KEY_TYPE_CHOICE!"=="2" set "KEY_TYPE=rsa"
    if "!KEY_TYPE_CHOICE!"=="" set "KEY_TYPE=ed25519"

    echo.
    set /p "USE_DEFAULT_PASS=Use default passphrase '%DEFAULT_PASSPHRASE%'? (Y/n): "
    if /i "!USE_DEFAULT_PASS!"=="n" (
        set /p "PASSPHRASE=Enter your passphrase: "
        set /p "PASSPHRASE_CONFIRM=Confirm your passphrase: "

        if not "!PASSPHRASE!"=="!PASSPHRASE_CONFIRM!" (
            call :log_error "Passphrases do not match"
            exit /b 1
        )
    )
)

set "KEY_PATH=%USERPROFILE%\.ssh\%KEY_NAME%"

REM Display final configuration
echo.
call :log_step "SSH Key Configuration Summary"
echo Key name: %KEY_NAME%
echo Key type: %KEY_TYPE%
echo Email: %EMAIL%
echo Path: %KEY_PATH%
echo.

REM Check if key already exists
if exist "%KEY_PATH%" (
    call :log_warning "SSH key already exists at %KEY_PATH%"
    if "%INTERACTIVE%"=="true" (
        set /p "OVERWRITE=Do you want to overwrite it? (y/N): "
        if /i not "!OVERWRITE!"=="y" (
            call :log_info "Operation cancelled by user"
            exit /b 0
        )
    ) else (
        call :log_info "Non-interactive mode: overwriting existing key"
    )
)

REM Ensure .ssh directory exists
if not exist "%USERPROFILE%\.ssh" (
    call :log_info "Creating .ssh directory..."
    mkdir "%USERPROFILE%\.ssh"
)

REM Generate SSH key based on type
call :log_step "Generating SSH key..."
if "%KEY_TYPE%"=="ed25519" (
    ssh-keygen -t ed25519 -f "%KEY_PATH%" -N "%PASSPHRASE%" -C "%EMAIL%"
) else if "%KEY_TYPE%"=="rsa" (
    ssh-keygen -t rsa -b 4096 -f "%KEY_PATH%" -N "%PASSPHRASE%" -C "%EMAIL%"
) else (
    call :log_error "Unsupported key type: %KEY_TYPE%"
    exit /b 1
)

REM Check if key was generated successfully
if not exist "%KEY_PATH%" (
    call :log_error "Failed to generate SSH key"
    exit /b 1
)

call :log_success "SSH key generated successfully!"

REM Check if ssh-agent is available and add key
call :log_step "Adding key to SSH agent..."
where ssh-add >nul 2>&1
if %errorlevel% equ 0 (
    REM Start ssh-agent if not running
    ssh-add -l >nul 2>&1
    if !errorlevel! neq 0 (
        call :log_info "Starting SSH agent..."
        for /f "tokens=*" %%i in ('ssh-agent') do (
            echo %%i | findstr "SSH_" >nul && set "%%i"
        )
    )

    ssh-add "%KEY_PATH%"
    if !errorlevel! equ 0 (
        call :log_success "Key added to SSH agent"
    ) else (
        call :log_warning "Failed to add key to SSH agent"
    )
) else (
    call :log_warning "ssh-add not available, skipping SSH agent setup"
)

REM Copy public key to clipboard
set "PUBLIC_KEY_PATH=%KEY_PATH%.pub"
if exist "%PUBLIC_KEY_PATH%" (
    call :log_step "Copying public key to clipboard..."
    type "%PUBLIC_KEY_PATH%" | clip
    call :log_success "Public key copied to clipboard!"
) else (
    call :log_error "Public key file not found: %PUBLIC_KEY_PATH%"
)

echo.
call :log_step "🎉 SSH Key Setup Complete!"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
call :log_info "📂 Your SSH key files:"
echo   • Private key: %KEY_PATH%
echo   • Public key: %PUBLIC_KEY_PATH%
echo.
call :log_info "🚀 Next Steps:"
echo.
echo 1️⃣  Add your SSH key to GitHub:
echo    a. Go to GitHub → Settings → SSH and GPG keys → New SSH key
echo    b. Paste the copied key and give it a title (e.g., "%APP_NAME% - Windows")
echo    c. Click 'Add SSH key'
echo    📌 https://github.com/settings/ssh/new
echo.
echo 2️⃣  Add your SSH key to GitLab:
echo    a. Go to GitLab → Preferences → SSH Keys
echo    b. Paste the copied key and give it a title
echo    c. Click 'Add key'
echo    📌 https://gitlab.com/-/profile/keys
echo.
echo 3️⃣  Test your connection:
echo    • GitHub:  ssh -T git@github.com
echo    • GitLab:  ssh -T git@gitlab.com
echo.
echo 4️⃣  Update your repository remote URL:
echo    git remote set-url origin git@github.com:username/repository.git
echo    git remote set-url origin git@gitlab.com:username/repository.git
echo.
echo 📚 Documentation:
echo   • GitHub: https://docs.github.com/en/authentication/connecting-to-github-with-ssh
echo   • GitLab: https://docs.gitlab.com/ee/user/ssh.html
echo.
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REM Pause for user removed for automation

endlocal
exit /b 0 