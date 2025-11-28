@echo off
setlocal
set ROOT=%~dp0
set TOOLSDIR=%ROOT%.

call "%TOOLSDIR%\build\build_apk.bat" --help || exit /b 1
call "%TOOLSDIR%\build\build_appbundle.bat" --help || exit /b 1
call "%TOOLSDIR%\config\flutterfire_config.bat" --help || exit /b 1
call "%TOOLSDIR%\distribution\distribute.bat" --help || exit /b 1

echo Smoke tests finished.
endlocal
