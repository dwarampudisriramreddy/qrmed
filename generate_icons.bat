@echo off
REM Generate QR code app icons
setlocal enabledelayedexpansion

echo Generating QR code app icons...
echo.

REM Try to find and use python
set FOUND_PYTHON=0

REM Try python.exe
where python.exe >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_CMD=python.exe
    set FOUND_PYTHON=1
    echo Found: python.exe
    goto :run_script
)

REM Try python
where python >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_CMD=python
    set FOUND_PYTHON=1
    echo Found: python
    goto :run_script
)

REM Try python3
where python3 >nul 2>&1
if %errorlevel% equ 0 (
    set PYTHON_CMD=python3
    set FOUND_PYTHON=1
    echo Found: python3
    goto :run_script
)

if %FOUND_PYTHON% equ 0 (
    echo ERROR: Python not found in PATH
    echo Please install Python or add it to your PATH
    pause
    exit /b 1
)

:run_script
echo Running icon generator...
%PYTHON_CMD% generate_qr_app_icon.py
if %errorlevel% equ 0 (
    echo.
    echo SUCCESS: Icons generated!
    pause
    exit /b 0
) else (
    echo.
    echo ERROR: Icon generation failed
    pause
    exit /b 1
)
