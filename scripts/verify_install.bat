@echo off
setlocal enabledelayedexpansion

echo.
echo SNES Build Tools - Installation Verification
echo ==============================================
echo.

:: --- Determine repo root ---
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
:: Go up one level from scripts\ to repo root
for %%i in ("%SCRIPT_DIR%\..") do set "REPO_ROOT=%%~fi"

:: Source environment
call "%REPO_ROOT%\env.bat" >nul 2>&1

set "PASS=0"
set "FAIL=0"
set "WARN=0"

:: --- Check SDK files directly ---
echo Checking PVSnesLib SDK files...
echo.

call :check_file "%REPO_ROOT%\tools\pvsneslib\devkitsnes\bin\816-tcc.exe" "816-tcc (C compiler)"
call :check_file "%REPO_ROOT%\tools\pvsneslib\devkitsnes\bin\wla-65816.exe" "wla-65816 (assembler)"
call :check_file "%REPO_ROOT%\tools\pvsneslib\devkitsnes\bin\wlalink.exe" "wlalink (linker)"
call :check_file "%REPO_ROOT%\tools\pvsneslib\devkitsnes\tools\gfx4snes.exe" "gfx4snes (graphics converter)"
call :check_file "%REPO_ROOT%\tools\pvsneslib\devkitsnes\tools\816-opt.exe" "816-opt (ASM optimizer)"
call :check_file "%REPO_ROOT%\tools\pvsneslib\devkitsnes\tools\constify.exe" "constify (constant mover)"
call :check_file "%REPO_ROOT%\tools\pvsneslib\devkitsnes\tools\snestools.exe" "snestools (ROM header tool)"
call :check_file "%REPO_ROOT%\tools\pvsneslib\devkitsnes\snes_rules" "snes_rules (Makefile include)"
call :check_file "%REPO_ROOT%\tools\pvsneslib\pvsneslib\include\snes\video.h" "SNES headers"

echo.
echo Checking system tools...
echo.

:: --- Check system prerequisites ---
call :check_cmd "git" "git"
call :check_cmd "make" "GNU Make"
call :check_cmd "python" "Python"
call :check_cmd "curl" "curl"

echo.
echo Checking Python packages...
echo.

:: --- Check Pillow ---
python -c "import PIL; print(PIL.__version__)" >nul 2>&1
if !errorlevel! equ 0 (
    for /f "tokens=*" %%v in ('python -c "import PIL; print(PIL.__version__)"') do (
        echo   [PASS] Pillow v%%v
    )
    set /a PASS+=1
) else (
    echo   [WARN] Pillow not installed ^(needed for font generation^)
    echo          Install with: python -m pip install Pillow
    set /a WARN+=1
)

echo.
echo ==============================================
echo Results: !PASS! passed, !FAIL! failed, !WARN! warnings
echo ==============================================
echo.

if !FAIL! gtr 0 (
    echo Some required tools are missing. Run install.bat to fix.
    exit /b 1
) else (
    if !WARN! gtr 0 (
        echo All required tools present. Some optional tools have warnings.
    ) else (
        echo All tools verified successfully!
    )
    exit /b 0
)

:: --- Subroutines ---

:check_file
if exist "%~1" (
    echo   [PASS] %~2
    set /a PASS+=1
) else (
    echo   [FAIL] %~2 - not found
    echo          Expected: %~1
    set /a FAIL+=1
)
exit /b 0

:check_cmd
where %~1 >nul 2>&1
if !errorlevel! equ 0 (
    echo   [PASS] %~2
    set /a PASS+=1
) else (
    echo   [WARN] %~2 - not found in PATH
    set /a WARN+=1
)
exit /b 0
