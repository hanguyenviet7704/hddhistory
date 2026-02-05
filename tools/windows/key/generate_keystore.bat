@echo off
setlocal enabledelayedexpansion

REM Enhanced Keystore Generation Script with Centralized Configuration (Windows)
REM This script generates Android keystore files using configuration from .info\ directory

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
set "KEYSTORE_TYPE=JKS"
set "KEY_ALG=RSA"
set "KEY_SIZE=2048"
set "VALIDITY=10000"

:parse_args
if "%~1"=="" goto :args_done
if "%~1"=="--non-interactive" (
    set "INTERACTIVE=false"
    shift
    goto :parse_args
)
if "%~1"=="--keystore-type" (
    set "KEYSTORE_TYPE=%~2"
    shift
    shift
    goto :parse_args
)
if "%~1"=="--key-algorithm" (
    set "KEY_ALG=%~2"
    shift
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
    set "VALIDITY=%~2"
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
echo   --non-interactive     Run without user prompts (use existing config)
echo   --keystore-type ^<type^> Keystore type (JKS, PKCS12, default: JKS)
echo   --key-algorithm ^<alg^>  Key algorithm (RSA, EC, default: RSA)
echo   --key-size ^<size^>     Key size in bits (default: 2048)
echo   --validity ^<days^>     Certificate validity in days (default: 10000)
echo   -h, --help           Show this help message
echo.
echo This script uses centralized configuration from .info\ directory.
echo.
echo Examples:
echo   %~nx0                                Interactive mode
echo   %~nx0 --non-interactive              Use existing key.properties
echo   %~nx0 --key-size 4096 --validity 365  Custom key size and validity
exit /b 0

:args_done

REM Validate environment
call :validate_environment
if %errorlevel% neq 0 exit /b 1

REM Get app information for keystore generation
call :get_app_name APP_NAME
call :get_pubspec_version VERSION

REM Set file paths
set "PROPERTIES_FILE=android\key.properties"
set "KEYSTORE_PATH=android\app\upload-keystore.jks"

call :log_info "🔐 Android Keystore Generation with Centralized Configuration"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo App: %APP_NAME%
echo Version: %VERSION%
echo Keystore Path: %KEYSTORE_PATH%
echo Properties File: %PROPERTIES_FILE%
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

REM Read values from key.properties
call :log_step "Reading key.properties configuration..."
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

    call :log_success "Configuration loaded successfully"
    echo   storePassword: %storePassword%
    echo   keyPassword: %keyPassword%
    echo   keyAlias: %keyAlias%
    echo   storeFile: %storeFile%
) else (
    call :log_error "key.properties file not found at %PROPERTIES_FILE%"
    call :log_info "Please create the key.properties file first with:"
    echo     storePassword=your_store_password
    echo     keyPassword=your_key_password
    echo     keyAlias=your_key_alias
    echo     storeFile=android/app/upload-keystore.jks
    exit /b 1
)

REM Check if keystore already exists
echo.
call :log_step "Checking existing keystore..."
if exist "%KEYSTORE_PATH%" (
    call :log_warning "Keystore already exists at %KEYSTORE_PATH%"
    if "%INTERACTIVE%"=="true" (
        set /p "OVERWRITE=Do you want to overwrite it? (y/N): "
        if /i "!OVERWRITE!" neq "y" (
            call :log_info "Operation cancelled by user"
            exit /b 0
        )
    ) else (
        call :log_info "Non-interactive mode: overwriting existing keystore"
    )
) else (
    call :log_info "No existing keystore found"
)

REM Check if keytool is available
call :log_step "Checking Java keytool availability..."
where keytool >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "keytool is not installed or not in PATH"
    call :log_error "Please install Java JDK and ensure keytool is accessible from command line"
    call :log_info "Download from: https://adoptium.net/"
    exit /b 1
)

REM Get Java version info
for /f "tokens=*" %%i in ('keytool -help 2^>nul ^| findstr "keytool"') do (
    call :log_success "Java keytool found: %%i"
)

REM Ensure android/app directory exists
if not exist "android\app" (
    call :log_info "Creating android/app directory..."
    mkdir "android\app"
)

REM Display generation configuration
echo.
call :log_step "Keystore Generation Configuration"
echo Keystore Type: %KEYSTORE_TYPE%
echo Key Algorithm: %KEY_ALG%
echo Key Size: %KEY_SIZE% bits
echo Validity: %VALIDITY% days
echo Alias: %keyAlias%
echo.

REM Generate the keystore
call :log_step "Generating Android keystore..."
call :log_info "This may take a few moments..."

keytool -genkeypair ^
    -keystore "%KEYSTORE_PATH%" ^
    -alias "%keyAlias%" ^
    -keyalg %KEY_ALG% ^
    -keysize %KEY_SIZE% ^
    -validity %VALIDITY% ^
    -storepass "%storePassword%" ^
    -keypass "%keyPassword%" ^
    -storetype %KEYSTORE_TYPE% ^
    -dname "CN=%APP_NAME%, OU=Mobile Development, O=Development Team, L=City, ST=State, C=US" ^
    -noprompt

if %errorlevel% neq 0 (
    call :log_error "Failed to generate keystore"
    call :log_error "Please check your key.properties configuration and Java installation"
    exit /b 1
)

call :log_success "🎉 Keystore generated successfully!"
echo.
call :log_step "Keystore Information"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo Location: %KEYSTORE_PATH%
echo Alias: %keyAlias%
echo Type: %KEYSTORE_TYPE%
echo Algorithm: %KEY_ALG%
echo Key Size: %KEY_SIZE% bits
echo Validity: %VALIDITY% days
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.

call :log_info "📝 Next Steps:"
echo 1️⃣  Verify your build.gradle configuration includes signing config
echo 2️⃣  Test the keystore with a release build
echo 3️⃣  Keep the keystore file secure and backed up
echo 4️⃣  Never commit the keystore file to version control
echo.
call :log_info "📚 Documentation:"
echo   • Android Signing: https://developer.android.com/studio/publish/app-signing
echo   • Flutter Release: https://docs.flutter.dev/deployment/android#signing-the-app
echo.

REM Verify keystore was created correctly
call :log_step "Verifying keystore..."
keytool -list -v -keystore "%KEYSTORE_PATH%" -storepass "%storePassword%" -alias "%keyAlias%" >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "Keystore verification passed"
) else (
    call :log_warning "Keystore verification failed, but file was created"
)

REM Pause for user removed for automation

endlocal
exit /b 0
