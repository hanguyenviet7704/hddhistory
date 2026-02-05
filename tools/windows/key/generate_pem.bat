@echo off
setlocal enabledelayedexpansion

REM Enhanced PEM Certificate Generation Script with Centralized Configuration (Windows)
REM This script generates PEM certificates using configuration from .info\ directory

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
set "KEY_SIZE=2048"
set "VALIDITY_DAYS=365"
set "ALGORITHM=RSA"

:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="--non-interactive" (
    set "INTERACTIVE=false"
    shift
    goto :parse_args
)
if "%~1"=="--key-size" (
    set "KEY_SIZE=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--validity" (
    set "VALIDITY_DAYS=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--algorithm" (
    set "ALGORITHM=%~2"
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
echo   --non-interactive     Run without user prompts (use config/defaults)
echo   --key-size ^<size^>     Private key size in bits (default: 2048)
echo   --validity ^<days^>     Certificate validity in days (default: 365)
echo   --algorithm ^<alg^>     Key algorithm (RSA, EC, default: RSA)
echo   -h, --help           Show this help message
echo.
echo This script uses centralized configuration from .info\ directory.
echo.
echo Examples:
echo   %~nx0                                Interactive mode
echo   %~nx0 --non-interactive              Use config/defaults
echo   %~nx0 --key-size 4096 --validity 730 Custom key size and validity
exit /b 0

:args_done

REM Validate environment
call :validate_environment
if %errorlevel% neq 0 exit /b 1

REM Get app information for certificate generation
call :get_app_name APP_NAME
call :get_pubspec_version VERSION

REM Set file paths
set "PROPERTIES_FILE=android\pem.properties"
set "PRIVATE_KEY_PATH=android\app\private-key.pem"
set "CERTIFICATE_PATH=android\app\certificate.pem"
set "COMBINED_PEM_PATH=android\app\combined.pem"

call :log_info "📜 PEM Certificate Generation with Centralized Configuration"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo App: %APP_NAME%
echo Version: %VERSION%
echo Private Key: %PRIVATE_KEY_PATH%
echo Certificate: %CERTIFICATE_PATH%
echo Combined PEM: %COMBINED_PEM_PATH%
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

REM Default certificate values
set "COUNTRY=US"
set "STATE=California"
set "LOCALITY=San Francisco"
set "ORGANIZATION=%APP_NAME%"
set "ORGANIZATIONAL_UNIT=Mobile Development"
set "COMMON_NAME=%APP_NAME%"
set "EMAIL=admin@example.com"

REM Read values from pem.properties if it exists
call :log_step "Loading certificate configuration..."
if exist "%PROPERTIES_FILE%" (
    call :log_success "Properties file found: %PROPERTIES_FILE%"
    echo.
    call :log_info "File contents:"
    type "%PROPERTIES_FILE%"
    echo.

    REM Parse properties file
    for /f "usebackq tokens=1,* delims==" %%G in ("%PROPERTIES_FILE%") do (
        set "%%G=%%H"
    )
    call :log_success "Configuration loaded from properties file"
) else (
    call :log_warning "pem.properties file not found at %PROPERTIES_FILE%"
    call :log_info "Using default values based on app configuration"
    echo.
    call :log_info "You can create a pem.properties file with:"
    echo   COUNTRY=US
    echo   STATE=California
    echo   LOCALITY=San Francisco
    echo   ORGANIZATION=%APP_NAME%
    echo   ORGANIZATIONAL_UNIT=Mobile Development
    echo   COMMON_NAME=%APP_NAME%
    echo   EMAIL=admin@example.com
    echo   VALIDITY_DAYS=365
    echo.
)

REM Display certificate configuration
echo.
call :log_step "Certificate Configuration"
echo Country: %COUNTRY%
echo State: %STATE%
echo Locality: %LOCALITY%
echo Organization: %ORGANIZATION%
echo Organizational Unit: %ORGANIZATIONAL_UNIT%
echo Common Name: %COMMON_NAME%
echo Email: %EMAIL%
echo Validity: %VALIDITY_DAYS% days
echo Key Size: %KEY_SIZE% bits
echo Algorithm: %ALGORITHM%
echo.

REM Check if PEM files already exist
call :log_step "Checking existing PEM files..."
set "FILES_EXIST=false"
if exist "%PRIVATE_KEY_PATH%" (
    call :log_warning "Private key exists: %PRIVATE_KEY_PATH%"
    set "FILES_EXIST=true"
)
if exist "%CERTIFICATE_PATH%" (
    call :log_warning "Certificate exists: %CERTIFICATE_PATH%"
    set "FILES_EXIST=true"
)
if exist "%COMBINED_PEM_PATH%" (
    call :log_warning "Combined PEM exists: %COMBINED_PEM_PATH%"
    set "FILES_EXIST=true"
)

if "%FILES_EXIST%"=="true" (
    if "%INTERACTIVE%"=="true" (
        set /p "OVERWRITE_ALL=Do you want to overwrite all existing PEM files? (y/N): "
        if /i "!OVERWRITE_ALL!" neq "y" (
            call :log_info "Operation cancelled by user"
            exit /b 0
        )
    ) else (
        call :log_info "Non-interactive mode: overwriting existing files"
    )
) else (
    call :log_info "No existing PEM files found"
)

REM Check if OpenSSL is installed
call :log_step "Checking OpenSSL availability..."
where openssl >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "OpenSSL is not installed or not in PATH"
    call :log_error "Please install OpenSSL and ensure it's accessible from command line"
    call :log_info "Download from: https://slproweb.com/products/Win32OpenSSL.html"
    exit /b 1
)

REM Get OpenSSL version
for /f "tokens=*" %%i in ('openssl version 2^>nul') do (
    call :log_success "OpenSSL found: %%i"
)

REM Ensure android/app directory exists
if not exist "android\app" (
    call :log_info "Creating android/app directory..."
    mkdir "android\app"
)

REM Generate private key
echo.
call :log_step "Generating private key..."
call :log_info "Key size: %KEY_SIZE% bits"
call :log_info "Algorithm: %ALGORITHM%"

if "%ALGORITHM%"=="RSA" (
    openssl genrsa -out "%PRIVATE_KEY_PATH%" %KEY_SIZE%
) else if "%ALGORITHM%"=="EC" (
    openssl ecparam -genkey -name secp256r1 -out "%PRIVATE_KEY_PATH%"
) else (
    call :log_error "Unsupported algorithm: %ALGORITHM%"
    exit /b 1
)

if %errorlevel% neq 0 (
    call :log_error "Failed to generate private key"
    exit /b 1
)

call :log_success "Private key generated successfully"

REM Generate certificate
call :log_step "Generating X.509 certificate..."
call :log_info "Validity: %VALIDITY_DAYS% days"

openssl req -new -x509 -key "%PRIVATE_KEY_PATH%" -out "%CERTIFICATE_PATH%" -days %VALIDITY_DAYS% -subj "/C=%COUNTRY%/ST=%STATE%/L=%LOCALITY%/O=%ORGANIZATION%/OU=%ORGANIZATIONAL_UNIT%/CN=%COMMON_NAME%/emailAddress=%EMAIL%"

if %errorlevel% neq 0 (
    call :log_error "Failed to generate certificate"
    exit /b 1
)

call :log_success "Certificate generated successfully"

REM Combine private key and certificate into a single PEM file
call :log_step "Creating combined PEM file..."

(
    type "%PRIVATE_KEY_PATH%"
    echo.
    type "%CERTIFICATE_PATH%"
) > "%COMBINED_PEM_PATH%"

if %errorlevel% neq 0 (
    call :log_error "Failed to create combined PEM file"
    exit /b 1
)

call :log_success "Combined PEM file created successfully"

REM Verify generated files
echo.
call :log_step "Verifying generated certificates..."

REM Check private key
openssl rsa -in "%PRIVATE_KEY_PATH%" -check -noout >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "Private key verification passed"
) else (
    call :log_warning "Private key verification failed"
)

REM Check certificate
openssl x509 -in "%CERTIFICATE_PATH%" -text -noout >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "Certificate verification passed"
) else (
    call :log_warning "Certificate verification failed"
)

echo.
call :log_success "🎉 PEM files generated successfully!"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
call :log_info "📂 Generated files:"
echo   • Private Key:  %PRIVATE_KEY_PATH%
echo   • Certificate:  %CERTIFICATE_PATH%
echo   • Combined PEM: %COMBINED_PEM_PATH%
echo.
call :log_info "🔒 Security Notes:"
echo   • Keep these files secure and private
echo   • Add them to .gitignore to prevent accidental commits
echo   • Back up the files in a secure location
echo   • Never share the private key
echo.
call :log_info "📝 Certificate Details:"
echo   • Subject: CN=%COMMON_NAME%, O=%ORGANIZATION%, C=%COUNTRY%
echo   • Valid for: %VALIDITY_DAYS% days
echo   • Algorithm: %ALGORITHM%
echo   • Key Size: %KEY_SIZE% bits
echo.
call :log_info "📚 Documentation:"
echo   • OpenSSL: https://www.openssl.org/docs/
echo   • X.509 Certificates: https://tools.ietf.org/html/rfc5280
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

REM Pause for user removed for automation

endlocal
exit /b 0 