@echo off
REM Quick Icon Generator for QRmed
REM This batch file generates QR code app icons for all Android densities

setlocal enabledelayedexpansion

color 0A
title QRmed App Icon Generator
cls

echo.
echo ================================================================================
echo                    QRmed App Icon Generator
echo ================================================================================
echo.
echo This tool will replace the default Flutter app icon with a QR code icon
echo that matches the login screen.
echo.

REM Check if Python is available
python.exe --version >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON=python.exe
    echo ✓ Found Python
    goto :check_pillow
)

python --version >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON=python
    echo ✓ Found Python
    goto :check_pillow
)

echo ✗ ERROR: Python is not installed or not in PATH
echo.
echo Please install Python from: https://www.python.org/downloads/
echo And make sure to check "Add Python to PATH" during installation.
pause
exit /b 1

:check_pillow
echo.
echo Checking for PIL/Pillow...
%PYTHON% -c "from PIL import Image" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ PIL/Pillow found
    goto :generate
)

echo ! PIL/Pillow not found - installing...
echo.
%PYTHON% -m pip install --upgrade pip
%PYTHON% -m pip install Pillow

if %errorlevel% neq 0 (
    echo ✗ Failed to install Pillow
    pause
    exit /b 1
)

:generate
echo.
echo ================================================================================
echo Running icon generator...
echo ================================================================================
echo.

%PYTHON% quick_icon_gen.py

if %errorlevel% equ 0 (
    echo.
    echo ================================================================================
    echo ✓ SUCCESS: Icons generated!
    echo ================================================================================
    echo.
    echo Next steps:
    echo   1. Run: flutter clean
    echo   2. Run: flutter pub get
    echo   3. Run: flutter build apk --release
    echo   4. Install and test the APK
    echo.
    echo Your app icon should now match the QR code icon from the login screen.
    echo.
    pause
    exit /b 0
) else (
    echo.
    echo ================================================================================
    echo ✗ ERROR: Icon generation failed
    echo ================================================================================
    pause
    exit /b 1
)
