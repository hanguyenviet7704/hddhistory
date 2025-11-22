@echo off

REM Localization-specific configuration helper functions for the slang pipeline (Windows)

REM Colors
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "BLUE=[94m"
set "PURPLE=[95m"
set "CYAN=[96m"
set "NC=[0m"

REM Project paths
for %%i in ("%~dp0..\..\..") do set "PROJECT_ROOT=%%~fi"
set "INFO_DIR=%PROJECT_ROOT%\.info"
set "INFO_APP_DIR=%INFO_DIR%\app"

REM Localization configuration file
set "LOCALIZATION_CONFIG=%INFO_APP_DIR%\localization.json"

REM Dispatch to label when called as: localization_common.bat :label args...
if not "%~1"=="" (
    set "_target=%~1"
    shift
    goto %_target%
)
goto :eof

:log_info
echo %BLUE%ℹ️  %~1%NC%
exit /b 0

:log_success
echo %GREEN%✅ %~1%NC%
exit /b 0

:log_warning
echo %YELLOW%⚠️  %~1%NC%
exit /b 0

:log_error
echo %RED%❌ %~1%NC%
exit /b 0

:log_step
echo %PURPLE%🔸 %~1%NC%
exit /b 0

:get_relative_path
set "path=%~1"
set "%~2=%PROJECT_ROOT%\%path%"
exit /b 0

:validate_environment
call :log_step "Validating environment..."
where jq >nul 2>&1
if errorlevel 1 (
    call :log_error "jq is required (install https://github.com/stedolan/jq/releases)"
    exit /b 1
)
call :log_success "Environment validation passed"
exit /b 0

REM Read a value from localization.json using jq (returns empty string when missing/null)
:get_localization_config
set "key=%~1"
set "result="
if exist "%LOCALIZATION_CONFIG%" (
    for /f "usebackq tokens=*" %%i in (`jq -c "%key% // empty" "%LOCALIZATION_CONFIG%" 2^>nul`) do set "result=%%i"
)
if "%result%"=="null" set "result="
set "%~2=%result%"
exit /b 0

REM Google Sheets configuration (active + legacy)
:get_active_sheet_id
call :get_localization_config ".googleSheets.active.sheetId" value
set "%~1=%value%"
exit /b 0

:get_active_sheet_gids_json
call :get_localization_config ".googleSheets.active.sheetGids" value
if "%value%"=="" set "value=[]"
set "%~1=%value%"
exit /b 0

:get_active_sheet_tabs_json
call :get_localization_config ".googleSheets.active.tabs" value
if "%value%"=="" set "value=[]"
set "%~1=%value%"
exit /b 0

:get_active_sheet_columns_json
call :get_localization_config ".googleSheets.active.columns" value
if "%value%"=="" set "value={}"
set "%~1=%value%"
exit /b 0

:get_legacy_sheet_id
call :get_localization_config ".googleSheets.legacy.sheetId" value
set "%~1=%value%"
exit /b 0

:get_legacy_sheet_gids_json
call :get_localization_config ".googleSheets.legacy.sheetGids" value
if "%value%"=="" set "value=[]"
set "%~1=%value%"
exit /b 0

:get_legacy_sheet_columns_json
call :get_localization_config ".googleSheets.legacy.columns" value
if "%value%"=="" set "value={}"
set "%~1=%value%"
exit /b 0

:get_localization_sa_path
call :get_localization_config ".googleSheets.auth.serviceAccountPath" value
if "%value%"=="" (
    set "%~1="
) else (
    call :get_relative_path "%value%" resolved
    set "%~1=%resolved%"
)
exit /b 0

:get_localization_sa_path_env
call :get_localization_config ".googleSheets.auth.serviceAccountPathEnv" value
if "%value%"=="" set "value=LOCALIZATION_SA_PATH"
set "%~1=%value%"
exit /b 0

:get_localization_sa_json_env
call :get_localization_config ".googleSheets.auth.serviceAccountJsonEnv" value
if "%value%"=="" set "value=LOCALIZATION_SA_JSON"
set "%~1=%value%"
exit /b 0

REM Language configuration
:get_language_mapping_json
call :get_localization_config ".languages.mapping" value
if "%value%"=="" set "value={}"
set "%~1=%value%"
exit /b 0

:get_supported_languages_json
call :get_localization_config ".languages.supported" value
if "%value%"=="" set "value=[]"
set "%~1=%value%"
exit /b 0

:get_default_language
call :get_localization_config ".languages.default" value
set "%~1=%value%"
exit /b 0

REM Path configuration
:get_i18n_dir
call :get_localization_config ".paths.i18nDir" value
if "%value%"=="" (
    set "%~1="
) else (
    call :get_relative_path "%value%" resolved
    set "%~1=%resolved%"
)
exit /b 0

:get_template_dir
call :get_localization_config ".paths.templateDir" value
if "%value%"=="" (
    set "%~1="
) else (
    call :get_relative_path "%value%" resolved
    set "%~1=%resolved%"
)
exit /b 0

:get_temp_dir
call :get_localization_config ".paths.tempDir" value
if "%value%"=="" (
    set "%~1="
) else (
    call :get_relative_path "%value%" resolved
    set "%~1=%resolved%"
)
exit /b 0

:get_legacy_arb_dir
call :get_localization_config ".paths.legacyArbDir" value
if "%value%"=="" (
    set "%~1="
) else (
    call :get_relative_path "%value%" resolved
    set "%~1=%resolved%"
)
exit /b 0

:get_slang_config_path
call :get_localization_config ".paths.slangConfig" value
if "%value%"=="" (
    set "%~1="
) else (
    call :get_relative_path "%value%" resolved
    set "%~1=%resolved%"
)
exit /b 0

:get_l10n_output_dir
call :get_localization_config ".paths.outputDir" value
if "%value%"=="" (
    set "%~1="
) else (
    call :get_relative_path "%value%" resolved
    set "%~1=%resolved%"
)
exit /b 0

REM Generation configuration
:get_generation_author
call :get_localization_config ".generation.author" value
set "%~1=%value%"
exit /b 0

:get_generation_encoding
call :get_localization_config ".generation.encoding" value
set "%~1=%value%"
exit /b 0

:escape_json_path
set "path_val=%~1"
set "path_val=%path_val:\=\\%"
set "%~2=%path_val%"
exit /b 0

:validate_localization_config
call :log_step "Validating localization configuration..."

if not exist "%LOCALIZATION_CONFIG%" (
    call :log_error "Localization configuration not found: %LOCALIZATION_CONFIG%"
    exit /b 1
)

call :get_active_sheet_id active_sheet_id
call :get_i18n_dir i18n_dir

if "%active_sheet_id%"=="" (
    call :log_error "Active sheet ID not configured in localization.json"
    exit /b 1
)

if "%i18n_dir%"=="" (
    call :log_error "i18n directory not configured in localization.json"
    exit /b 1
)

call :log_success "Localization configuration is valid"
exit /b 0

:show_localization_config
setlocal enabledelayedexpansion
echo.
call :log_step "Localization Configuration"
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
set "modules="
call :get_active_sheet_id active_sheet_id
echo Active Sheet ID: %active_sheet_id%
for /f "usebackq tokens=*" %%m in (`jq -r ".googleSheets.active.tabs[].module" "%LOCALIZATION_CONFIG%" 2^>nul`) do (
    if defined modules (set "modules=!modules!,%%m") else set "modules=%%m"
)
if defined modules (
    echo Active Sheet Tabs: !modules!
) else (
    echo Active Sheet Tabs: (none)
)
call :get_localization_sa_path sa_path
call :get_localization_sa_path_env sa_env
call :get_localization_sa_json_env sa_json_env
echo Service Account Path: %sa_path%
echo Service Account Env (path/json): %sa_env%/%sa_json_env%
set "active_gids="
for /f "usebackq tokens=*" %%i in (`jq -r ".googleSheets.active.sheetGids[]" "%LOCALIZATION_CONFIG%" 2^>nul`) do (
    if defined active_gids (set "active_gids=!active_gids! %%i") else set "active_gids=%%i"
)
if defined active_gids (
    echo Active Sheet GIDs: !active_gids!
) else (
    echo Active Sheet GIDs: (from tab gids)
)
call :get_legacy_sheet_id legacy_id
set "legacy_gids="
for /f "usebackq tokens=*" %%i in (`jq -r ".googleSheets.legacy.sheetGids[]" "%LOCALIZATION_CONFIG%" 2^>nul`) do (
    if defined legacy_gids (set "legacy_gids=!legacy_gids! %%i") else set "legacy_gids=%%i"
)
echo Legacy Sheet ID: %legacy_id%
if defined legacy_gids (
    echo Legacy Sheet GIDs: !legacy_gids!
) else (
    echo Legacy Sheet GIDs: (none)
)
call :get_default_language default_lang
call :get_supported_languages_json supported_langs
echo Default Language: %default_lang%
echo Supported Languages: %supported_langs%
call :get_i18n_dir i18n_dir
call :get_temp_dir temp_dir
call :get_template_dir template_dir
call :get_slang_config_path slang_cfg
call :get_l10n_output_dir output_dir
echo i18n Directory: %i18n_dir%
echo Temp Directory: %temp_dir%
echo Template Directory: %template_dir%
echo Slang Config: %slang_cfg%
echo Generated Output: %output_dir%
call :get_generation_author gen_author
echo Generation Author: %gen_author%
echo ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
echo.
endlocal
exit /b 0

REM Create Python configuration file for scripts (mirrors Linux config shape)
:create_python_config
set "config_file=%PROJECT_ROOT%\.localization_config.json"

call :get_active_sheet_id active_sheet_id
call :get_active_sheet_gids_json active_sheet_gids
call :get_active_sheet_tabs_json active_tabs
call :get_active_sheet_columns_json active_columns
call :get_legacy_sheet_id legacy_sheet_id
call :get_legacy_sheet_gids_json legacy_gids
call :get_legacy_sheet_columns_json legacy_columns
call :get_localization_sa_path sa_path
call :get_localization_sa_path_env sa_env
call :get_localization_sa_json_env sa_json_env
call :get_language_mapping_json language_mapping
call :get_supported_languages_json supported_languages
call :get_default_language default_language
call :get_i18n_dir i18n_dir
call :get_temp_dir temp_dir
call :get_template_dir template_dir
call :get_legacy_arb_dir legacy_arb_dir
call :get_slang_config_path slang_config
call :get_l10n_output_dir output_dir
call :get_generation_author generation_author
call :get_generation_encoding generation_encoding

call :escape_json_path "%PROJECT_ROOT%" project_root_json
call :escape_json_path "%sa_path%" sa_path_json
call :escape_json_path "%i18n_dir%" i18n_dir_json
call :escape_json_path "%temp_dir%" temp_dir_json
call :escape_json_path "%template_dir%" template_dir_json
call :escape_json_path "%legacy_arb_dir%" legacy_arb_dir_json
call :escape_json_path "%slang_config%" slang_config_json
call :escape_json_path "%output_dir%" output_dir_json

(
    echo {
    echo   "project_root": "%project_root_json%",
    echo   "active_sheet": {
    echo     "sheet_id": "%active_sheet_id%",
    echo     "sheet_gids": %active_sheet_gids%,
    echo     "tabs": %active_tabs%,
    echo     "columns": %active_columns%
    echo   },
    echo   "legacy_sheet": {
    echo     "sheet_id": "%legacy_sheet_id%",
    echo     "sheet_gids": %legacy_gids%,
    echo     "columns": %legacy_columns%
    echo   },
    echo   "auth": {
    echo     "service_account_path": "%sa_path_json%",
    echo     "service_account_path_env": "%sa_env%",
    echo     "service_account_json_env": "%sa_json_env%"
    echo   },
    echo   "languages": {
    echo     "mapping": %language_mapping%,
    echo     "supported": %supported_languages%,
    echo     "default": "%default_language%"
    echo   },
    echo   "paths": {
    echo     "i18n_dir": "%i18n_dir_json%",
    echo     "temp_dir": "%temp_dir_json%",
    echo     "template_dir": "%template_dir_json%",
    echo     "legacy_arb_dir": "%legacy_arb_dir_json%",
    echo     "slang_config": "%slang_config_json%",
    echo     "output_dir": "%output_dir_json%"
    echo   },
    echo   "generation": {
    echo     "author": "%generation_author%",
    echo     "encoding": "%generation_encoding%"
    echo   }
    echo }
) > "%config_file%"

set "%~1=%config_file%"
exit /b 0
