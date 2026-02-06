@echo off
setlocal enabledelayedexpansion

:: ============================================
:: SNES Build Tools - Windows Install Script
:: ============================================

echo.
echo ========================================
echo  SNES Build Tools Installer (Windows)
echo ========================================
echo.

:: --- Determine repo root (directory containing this script) ---
set "REPO_ROOT=%~dp0"
:: Remove trailing backslash
if "%REPO_ROOT:~-1%"=="\" set "REPO_ROOT=%REPO_ROOT:~0,-1%"

echo Repository root: %REPO_ROOT%
echo.

:: --- Configuration ---
set "PVSNESLIB_VERSION=4.5.0"
set "PVSNESLIB_ARCHIVE_NAME=pvsneslib_450_64b_windows.zip"
set "PVSNESLIB_URL=https://github.com/alekmaul/pvsneslib/releases/download/%PVSNESLIB_VERSION%/%PVSNESLIB_ARCHIVE_NAME%"
set "PVSNESLIB_DIR=%REPO_ROOT%\tools\pvsneslib"
set "PVSNESLIB_ZIP=%REPO_ROOT%\tmp\%PVSNESLIB_ARCHIVE_NAME%"
set "BIN_DIR=%PVSNESLIB_DIR%\devkitsnes\bin"
set "TOOLS_DIR=%PVSNESLIB_DIR%\devkitsnes\tools"

:: --- Step 1: Check Prerequisites ---
echo [1/7] Checking prerequisites...
echo.

:: Check for git
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo   [FAIL] git is not installed or not in PATH.
    echo          Install Git from https://git-scm.com/download/win
    echo          Or run: winget install Git.Git
    exit /b 1
)
for /f "tokens=*" %%i in ('git --version') do echo   [OK] %%i

:: Check for make
where make >nul 2>&1
if %errorlevel% neq 0 (
    echo   [WARN] GNU Make is not found in PATH.
    echo          You will need Make to build ROM projects.
    echo          Install options:
    echo            - MSYS2: https://www.msys2.org/ then: pacman -S make
    echo            - Chocolatey: choco install make
    echo            - scoop: scoop install make
    echo          Continuing installation...
) else (
    for /f "tokens=*" %%i in ('make --version 2^>nul') do (
        echo   [OK] %%i
        goto :make_done
    )
    :make_done
)

:: Check for Python
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo   [WARN] Python is not found in PATH.
    echo          Python is needed for font generation scripts.
    echo          Install from https://www.python.org/downloads/
    echo          Or run: winget install Python.Python.3.12
    echo          Continuing installation...
) else (
    for /f "tokens=*" %%i in ('python --version 2^>^&1') do echo   [OK] %%i
)

:: Check for curl
where curl >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo   [FAIL] curl is not available. Required for downloading tools.
    echo          curl is included in Windows 10 1803+. Update Windows or install curl.
    exit /b 1
)

echo.
echo   Prerequisites check complete.
echo.

:: --- Step 2: Create directories ---
echo [2/7] Creating directories...

if not exist "%REPO_ROOT%\tools\pvsneslib" mkdir "%REPO_ROOT%\tools\pvsneslib"
if not exist "%REPO_ROOT%\tools\emulators" mkdir "%REPO_ROOT%\tools\emulators"
if not exist "%REPO_ROOT%\tools\bin" mkdir "%REPO_ROOT%\tools\bin"
if not exist "%REPO_ROOT%\tmp" mkdir "%REPO_ROOT%\tmp"

echo   Directories ready.
echo.

:: --- Step 3: Download PVSnesLib ---
echo [3/7] Downloading PVSnesLib v%PVSNESLIB_VERSION%...

:: Check if already installed (compiler in bin/, not tools/)
if exist "%BIN_DIR%\816-tcc.exe" (
    echo   PVSnesLib is already installed. Skipping download.
    echo   To force reinstall, delete %PVSNESLIB_DIR% and run again.
    goto :skip_download
)

echo   Downloading from: %PVSNESLIB_URL%
echo   Saving to: %PVSNESLIB_ZIP%
echo.

curl -L --progress-bar -o "%PVSNESLIB_ZIP%" "%PVSNESLIB_URL%"
if %errorlevel% neq 0 (
    echo.
    echo   [FAIL] Download failed.
    echo.
    echo   Possible causes:
    echo     - No internet connection
    echo     - URL has changed ^(check https://github.com/alekmaul/pvsneslib/releases^)
    echo.
    echo   Manual download: Download the Windows ZIP from the URL above
    echo   and extract to: %PVSNESLIB_DIR%
    exit /b 1
)

echo.
echo   Download complete.
echo.

:: --- Step 4: Extract PVSnesLib ---
echo [4/7] Extracting PVSnesLib...

:: Clean existing installation (preserve the .gitkeep)
for %%s in (devkitsnes pvsneslib snes-examples vscode-template) do (
    if exist "%PVSNESLIB_DIR%\%%s" rmdir /s /q "%PVSNESLIB_DIR%\%%s" 2>nul
)

:: Extract to a staging directory first to handle the nested "pvsneslib/" root dir.
:: The ZIP contains pvsneslib/pvsneslib/ (inner lib dir has same name as ZIP root).
:: Extracting to staging avoids the collision when moving contents up.
set "STAGING_DIR=%REPO_ROOT%\tmp\_pvsneslib_extract_staging"
if exist "%STAGING_DIR%" rmdir /s /q "%STAGING_DIR%" 2>nul
mkdir "%STAGING_DIR%"

powershell -NoProfile -Command "Expand-Archive -Path '%PVSNESLIB_ZIP%' -DestinationPath '%STAGING_DIR%' -Force" 2>nul
if %errorlevel% neq 0 (
    echo.
    echo   [FAIL] Extraction failed.
    echo   Try extracting manually: %PVSNESLIB_ZIP%
    echo   Extract to: %PVSNESLIB_DIR%
    rmdir /s /q "%STAGING_DIR%" 2>nul
    exit /b 1
)

:: Find the SDK root (may be nested in a "pvsneslib\" subdir)
set "SDK_ROOT=%STAGING_DIR%"
if not exist "%SDK_ROOT%\devkitsnes" (
    echo   Checking for nested directory structure...
    for /d %%d in ("%STAGING_DIR%\*") do (
        if exist "%%d\devkitsnes" (
            set "SDK_ROOT=%%d"
            echo   Found SDK in %%~nxd\
            goto :found_sdk
        )
    )
    echo   [FAIL] Could not find devkitsnes\ directory after extraction.
    rmdir /s /q "%STAGING_DIR%" 2>nul
    exit /b 1
)
:found_sdk

:: Move each subdirectory from staging to final location
for /d %%d in ("%SDK_ROOT%\*") do (
    move "%%d" "%PVSNESLIB_DIR%\%%~nxd" >nul 2>nul
)
:: Move any loose files
for %%f in ("%SDK_ROOT%\*.*") do (
    move "%%f" "%PVSNESLIB_DIR%\" >nul 2>nul
)

:: Clean up staging
rmdir /s /q "%STAGING_DIR%" 2>nul

echo   Extraction complete.
echo.

:skip_download

:: --- Step 5: Verify SDK installation ---
echo [5/7] Verifying PVSnesLib installation...

set "VERIFY_FAILED=0"

:: Compilers are in devkitsnes\bin\
if not exist "%BIN_DIR%\816-tcc.exe" (
    echo   [FAIL] MISSING: devkitsnes\bin\816-tcc.exe ^(C compiler^)
    set "VERIFY_FAILED=1"
) else (
    echo   [OK] 816-tcc.exe      ^(C compiler^)
)

if not exist "%BIN_DIR%\wla-65816.exe" (
    echo   [FAIL] MISSING: devkitsnes\bin\wla-65816.exe ^(assembler^)
    set "VERIFY_FAILED=1"
) else (
    echo   [OK] wla-65816.exe    ^(assembler^)
)

if not exist "%BIN_DIR%\wlalink.exe" (
    echo   [FAIL] MISSING: devkitsnes\bin\wlalink.exe ^(linker^)
    set "VERIFY_FAILED=1"
) else (
    echo   [OK] wlalink.exe      ^(linker^)
)

:: Tools are in devkitsnes\tools\
if not exist "%TOOLS_DIR%\gfx4snes.exe" (
    echo   [FAIL] MISSING: devkitsnes\tools\gfx4snes.exe ^(graphics converter^)
    set "VERIFY_FAILED=1"
) else (
    echo   [OK] gfx4snes.exe     ^(graphics converter^)
)

if not exist "%TOOLS_DIR%\816-opt.exe" (
    echo   [FAIL] MISSING: devkitsnes\tools\816-opt.exe ^(ASM optimizer^)
    set "VERIFY_FAILED=1"
) else (
    echo   [OK] 816-opt.exe      ^(ASM optimizer^)
)

:: snes_rules is at devkitsnes\snes_rules (NOT in lib\)
if not exist "%PVSNESLIB_DIR%\devkitsnes\snes_rules" (
    echo   [FAIL] MISSING: devkitsnes\snes_rules ^(Makefile include^)
    set "VERIFY_FAILED=1"
) else (
    echo   [OK] snes_rules       ^(Makefile include^)
)

:: Check SNES headers
if not exist "%PVSNESLIB_DIR%\pvsneslib\include\snes\video.h" (
    echo   [FAIL] MISSING: pvsneslib\include\snes\video.h ^(SNES headers^)
    set "VERIFY_FAILED=1"
) else (
    echo   [OK] SNES headers     ^(pvsneslib\include\snes\^)
)

if %VERIFY_FAILED%==1 (
    echo.
    echo   [FAIL] PVSnesLib installation is incomplete.
    echo   Some required files are missing.
    echo.
    echo   Try:
    echo     1. Delete %PVSNESLIB_DIR%
    echo     2. Re-run this script
    echo     3. If the problem persists, download manually from:
    echo        https://github.com/alekmaul/pvsneslib/releases/tag/%PVSNESLIB_VERSION%
    exit /b 1
)

echo.
echo   PVSnesLib v%PVSNESLIB_VERSION% verified successfully.
echo.

:: --- Step 6: Install Python dependencies ---
echo [6/7] Installing Python dependencies...

where python >nul 2>&1
if %errorlevel% equ 0 (
    python -m pip install --quiet Pillow 2>nul
    if !errorlevel! equ 0 (
        echo   [OK] Pillow installed.
    ) else (
        echo   [WARN] Failed to install Pillow. Font generation may not work.
        echo          Try manually: python -m pip install Pillow
    )
) else (
    echo   Skipping ^(Python not found^). Install Python to enable font generation.
)
echo.

:: --- Step 7: Create environment script ---
echo [7/7] Creating environment configuration...

:: Build Unix-style path for PVSNESLIB_HOME (snes_rules requires forward slashes)
:: Convert drive letter and backslashes: J:\code\... -> /j/code/...
set "UNIX_PVSNESLIB=%PVSNESLIB_DIR%"
set "UNIX_PVSNESLIB=%UNIX_PVSNESLIB:\=/%"
:: Convert drive letter C: -> /c (lowercase)
for %%a in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
    set "UNIX_PVSNESLIB=!UNIX_PVSNESLIB:%%a:/=/%%a/!"
)
:: Lowercase the drive letter
for %%a in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do (
    set "UNIX_PVSNESLIB=!UNIX_PVSNESLIB:/%%a/=/%%a/!"
)

:: Create env.bat
(
    echo @echo off
    echo :: SNES Build Tools - Environment Setup
    echo :: Run this before building: call env.bat
    echo.
    echo :: Windows-style paths for tool execution
    echo set "PVSNESLIB_HOME=%UNIX_PVSNESLIB%"
    echo set "PATH=%BIN_DIR%;%TOOLS_DIR%;%%PATH%%"
    echo.
    echo echo SNES Build Tools environment configured.
    echo echo   PVSNESLIB_HOME=%%PVSNESLIB_HOME%%
) > "%REPO_ROOT%\env.bat"

echo   [OK] Created env.bat
echo.

:: --- Done ---
echo ========================================
echo  Installation Complete!
echo ========================================
echo.
echo PVSnesLib v%PVSNESLIB_VERSION% installed to:
echo   %PVSNESLIB_DIR%
echo.
echo PVSNESLIB_HOME (Unix-style for Makefiles):
echo   %UNIX_PVSNESLIB%
echo.
echo Next steps:
echo.
echo   1. Set up your environment:
echo      call env.bat
echo.
echo   2. Build the demo ROM:
echo      call env.bat
echo      cd projects\hello-snes-world
echo      make
echo.
echo   3. Verify tools:
echo      scripts\verify_install.bat
echo.

endlocal
exit /b 0
