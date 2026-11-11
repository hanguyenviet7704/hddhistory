@echo off
setlocal enabledelayedexpansion
set STATUS=0
set ROOT=%~dp0
set ROOT=%ROOT:~0,-1%

call :check "build\build_apk.bat" "build_apk"
call :check "build\build_appbundle.bat" "build_appbundle"
call :check "localization\localization.bat" "localization"
call :check "config\flutterfire_config.bat" "flutterfire_config"
call :presence "resource\generate_file.bat" "generate_file"
call :presence "resource\reset_app.bat" "reset_app"

goto :done

:check
set FILE=%~1
set LABEL=%~2
if not exist "%ROOT%\%FILE%" (
  echo [warn] %LABEL% missing (%FILE%)
  goto :eof
)
call "%ROOT%\%FILE%" --help >NUL 2>&1
set CODE=%errorlevel%
if %CODE% LEQ 1 (
  echo [ok] %LABEL% (--help exit %CODE%)
) else (
  echo [fail] %LABEL% (--help exit %CODE%)
  set STATUS=1
)
goto :eof

:presence
set FILE=%~1
set LABEL=%~2
if not exist "%ROOT%\%FILE%" (
  echo [warn] %LABEL% missing (%FILE%)
  goto :eof
)
echo [ok] %LABEL% present
goto :eof

:done
if %STATUS%==0 (
  echo Smoke checks passed.
) else (
  echo Smoke checks completed with issues.
)
endlocal & exit /b %STATUS%
