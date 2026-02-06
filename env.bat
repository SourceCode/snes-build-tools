@echo off
:: SNES Build Tools - Environment Setup
:: Run this before building: call env.bat
::
:: NOTE: This is a template. The install script overwrites this with
:: absolute paths. If you haven't run install.bat yet, this uses
:: relative paths from the repo root.

:: Get the directory this script lives in
set "SNES_BT_ROOT=%~dp0"
if "%SNES_BT_ROOT:~-1%"=="\" set "SNES_BT_ROOT=%SNES_BT_ROOT:~0,-1%"

:: Build Unix-style path for PVSNESLIB_HOME (required by snes_rules Makefile)
:: snes_rules checks for backslashes and errors out if found
set "PVSNESLIB_HOME=%SNES_BT_ROOT%\tools\pvsneslib"

:: Add both bin/ (compilers) and tools/ (converters) to PATH
set "PATH=%SNES_BT_ROOT%\tools\pvsneslib\devkitsnes\bin;%SNES_BT_ROOT%\tools\pvsneslib\devkitsnes\tools;%PATH%"

echo SNES Build Tools environment configured.
echo   PVSNESLIB_HOME=%PVSNESLIB_HOME%
