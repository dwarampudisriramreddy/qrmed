@echo off
REM Generate QR code icons for Android
cd /d C:\Users\Welcome\Documents\QRmed

REM Check if python is available
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo Python not found in PATH. Trying python3...
    python3 --version >nul 2>&1
    if %errorlevel% neq 0 (
        echo ERROR: Python is not installed or not in PATH
        exit /b 1
    )
    set PYTHON=python3
) else (
    set PYTHON=python
)

echo Running QR icon generator...
%PYTHON% generate_qr_icon.py
if %errorlevel% neq 0 (
    echo ERROR: Failed to generate icons
    exit /b 1
)

echo Icons generated successfully!
pause
