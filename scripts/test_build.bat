@echo off
setlocal

echo SNES Build Tools - Build Test
echo ==============================
echo.

set "REPO_ROOT=%~dp0.."
if "%REPO_ROOT:~-1%"=="\" set "REPO_ROOT=%REPO_ROOT:~0,-1%"

:: Set up environment
call "%REPO_ROOT%\env.bat" >nul 2>&1

:: Navigate to project
set "PROJECT_DIR=%REPO_ROOT%\projects\hello-snes-world"

echo Building in: %PROJECT_DIR%
echo PVSNESLIB_HOME: %PVSNESLIB_HOME%
echo.

:: Clean first
cd /d "%PROJECT_DIR%"
make clean 2>nul

:: Build
make
if %errorlevel% neq 0 (
    echo.
    echo [FAIL] BUILD FAILED
    echo Check the error messages above.
    exit /b 1
)

:: Check for output ROM
if exist "%PROJECT_DIR%\hello_snes_world.sfc" (
    echo.
    echo [PASS] BUILD SUCCEEDED
    echo ROM: %PROJECT_DIR%\hello_snes_world.sfc
    for %%F in ("%PROJECT_DIR%\hello_snes_world.sfc") do echo Size: %%~zF bytes
) else (
    echo.
    echo [FAIL] BUILD FAILED - ROM file not found
    exit /b 1
)

endlocal
exit /b 0
