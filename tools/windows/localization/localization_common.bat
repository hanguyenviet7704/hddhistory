@echo off
setlocal enabledelayedexpansion

REM Localization-specific configuration helper functions (Windows)
REM This extends the common configuration with localization-specific utilities

REM Source the main common configuration
call "%~dp0..\common\common.bat"
if %errorlevel% neq 0 (
    echo ❌ Failed to load common configuration
    exit /b 1
)

REM Localization configuration file
set "LOCALIZATION_CONFIG=%INFO_APP_DIR%\localization.json"

REM Function to get localization configuration value
:get_localization_config
set "key=%~1"
set "result="
if exist "%LOCALIZATION_CONFIG%" (
    for /f "tokens=*" %%i in ('jq -r "%key% // empty" "%LOCALIZATION_CONFIG%" 2^>nul') do set "result=%%i"
)
if "%result%"=="null" set "result="
set "%~2=%result%"
exit /b 0

REM Google Sheets configuration functions
:get_sheet_id
call :get_localization_config ".googleSheets.sheetId" sheet_id
set "%~1=%sheet_id%"
exit /b 0

:get_sheet_gids
call :get_localization_config ".googleSheets.sheetGids[]" sheet_gids_raw
set "sheet_gids=%sheet_gids_raw%"
set "%~1=%sheet_gids%"
exit /b 0

:get_sheet_columns
set "column=%~1"
call :get_localization_config ".googleSheets.columns.%column%" column_value
set "%~2=%column_value%"
exit /b 0

REM Language configuration functions
:get_language_mapping
set "language=%~1"
call :get_localization_config ".languages.mapping.%language%" mapping_value
set "%~2=%mapping_value%"
exit /b 0

:get_default_language
call :get_localization_config ".languages.default" default_lang
set "%~1=%default_lang%"
exit /b 0

REM Path configuration functions
:get_arb_dir
call :get_localization_config ".paths.arbDir" arb_path
call :get_relative_path "%arb_path%" resolved_path
set "%~1=%resolved_path%"
exit /b 0

:get_module_dir
call :get_localization_config ".paths.moduleDir" module_path
call :get_relative_path "%module_path%" resolved_path
set "%~1=%resolved_path%"
exit /b 0

:get_app_dir
call :get_localization_config ".paths.appDir" app_path
call :get_relative_path "%app_path%" resolved_path
set "%~1=%resolved_path%"
exit /b 0

:get_l10n_config_path
call :get_localization_config ".paths.l10nConfig" l10n_config
call :get_relative_path "%l10n_config%" resolved_path
set "%~1=%resolved_path%"
exit /b 0

:get_l10n_output_dir
call :get_localization_config ".paths.outputDir" output_dir
call :get_relative_path "%output_dir%" resolved_path
set "%~1=%resolved_path%"
exit /b 0

REM Generation configuration functions
:get_generation_author
call :get_localization_config ".generation.author" gen_author
set "%~1=%gen_author%"
exit /b 0

:get_generation_encoding
call :get_localization_config ".generation.encoding" gen_encoding
set "%~1=%gen_encoding%"
exit /b 0

REM Validation function
:validate_localization_config
call :log_step "Validating localization configuration..."

if not exist "%LOCALIZATION_CONFIG%" (
    call :log_error "Localization configuration not found: %LOCALIZATION_CONFIG%"
    exit /b 1
)

REM Check required fields
call :get_sheet_id sheet_id
call :get_arb_dir arb_dir

if "%sheet_id%"=="" (
    call :log_error "Sheet ID not configured in localization.json"
    exit /b 1
)

if "%arb_dir%"=="" (
    call :log_error "ARB directory not configured in localization.json"
    exit /b 1
)

call :log_success "Localization configuration is valid"
exit /b 0

REM Show localization configuration summary
:show_localization_config
echo.
call :log_step "Localization Configuration"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

call :get_sheet_id sheet_id
echo Sheet ID: %sheet_id%

call :get_sheet_gids sheet_gids
echo Sheet GIDs: %sheet_gids%

call :get_default_language default_lang
echo Default Language: %default_lang%

call :get_arb_dir arb_dir
echo ARB Directory: %arb_dir%

call :get_module_dir module_dir
echo Module Directory: %module_dir%

call :get_app_dir app_dir
echo App Directory: %app_dir%

call :get_l10n_config_path l10n_config
echo L10n Config: %l10n_config%

call :get_l10n_output_dir output_dir
echo Output Directory: %output_dir%

call :get_generation_author gen_author
echo Generation Author: %gen_author%

echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
exit /b 0

REM Create Python configuration file for scripts
:create_python_config
set "config_file=%PROJECT_ROOT%\.localization_config.json"

call :get_sheet_id sheet_id
call :get_sheet_gids sheet_gids
call :get_sheet_columns "screen" col_screen
call :get_sheet_columns "key" col_key
call :get_sheet_columns "metadata" col_metadata
call :get_sheet_columns "en" col_en
call :get_sheet_columns "vi" col_vi
call :get_sheet_columns "zh" col_zh
call :get_default_language default_lang
call :get_arb_dir arb_dir
call :get_module_dir module_dir
call :get_app_dir app_dir
call :get_generation_author gen_author
call :get_generation_encoding gen_encoding

REM Get language mapping object
call :get_localization_config ".languages.mapping" lang_mapping

REM Create JSON configuration file
(
    echo {
    echo     "sheet_id": "%sheet_id%",
    echo     "sheet_gids": [%sheet_gids%],
    echo     "columns": {
    echo         "screen": "%col_screen%",
    echo         "key": "%col_key%",
    echo         "metadata": "%col_metadata%",
    echo         "en": "%col_en%",
    echo         "vi": "%col_vi%",
    echo         "zh": "%col_zh%"
    echo     },
    echo     "languages": {
    echo         "mapping": %lang_mapping%,
    echo         "default": "%default_lang%"
    echo     },
    echo     "paths": {
    echo         "base_dir": "%PROJECT_ROOT%",
    echo         "arb_dir": "%arb_dir%",
    echo         "module_dir": "%module_dir%",
    echo         "app_dir": "%app_dir%"
    echo     },
    echo     "generation": {
    echo         "author": "%gen_author%",
    echo         "encoding": "%gen_encoding%"
    echo     }
    echo }
) > "%config_file%"

set "%~1=%config_file%"
exit /b 0