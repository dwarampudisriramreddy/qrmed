@echo off
REM QRMed App Build Script for Windows
REM This script builds the APK, Windows EXE, and Web versions

setlocal enabledelayedexpansion

echo.
echo ========================================
echo QRMed App Build Script
echo ========================================
echo.

REM Check if flutter is installed
flutter --version >nul 2>&1
if errorlevel 1 (
    echo Error: Flutter is not installed or not in PATH
    echo Please install Flutter from https://flutter.dev
    pause
    exit /b 1
)

REM Menu
echo Select what to build:
echo.
echo 1. Generate Icons (from logo)
echo 2. Build APK (Android)
echo 3. Build Windows EXE
echo 4. Build Web
echo 5. Build All (Icons + APK + Windows + Web)
echo 6. Clean Build
echo 7. Exit
echo.

set /p choice="Enter your choice (1-7): "

if "%choice%"=="1" goto generate_icons
if "%choice%"=="2" goto build_apk
if "%choice%"=="3" goto build_windows
if "%choice%"=="4" goto build_web
if "%choice%"=="5" goto build_all
if "%choice%"=="6" goto clean_build
if "%choice%"=="7" goto end
goto invalid_choice

:generate_icons
echo.
echo Generating icons from QRMed logo...
python generate_icons.py
if errorlevel 1 (
    echo Error: Failed to generate icons
    echo Make sure Python 3 and Pillow are installed: pip install Pillow
    pause
    exit /b 1
)
pause
goto end

:build_apk
echo.
echo Building Android APK...
echo.
flutter pub get
flutter build apk --release
if errorlevel 0 (
    echo.
    echo ========================================
    echo ✅ APK built successfully!
    echo ========================================
    echo Location: build\app\outputs\apk\release\app-release.apk
) else (
    echo.
    echo ❌ APK build failed
)
pause
goto end

:build_windows
echo.
echo Building Windows EXE...
echo.
flutter pub get
flutter build windows --release
if errorlevel 0 (
    echo.
    echo ========================================
    echo ✅ Windows EXE built successfully!
    echo ========================================
    echo Location: build\windows\runner\Release\qrmed.exe
) else (
    echo.
    echo ❌ Windows build failed
)
pause
goto end

:build_web
echo.
echo Building Web version...
echo.
flutter pub get
flutter build web
if errorlevel 0 (
    echo.
    echo ========================================
    echo ✅ Web version built successfully!
    echo ========================================
    echo Location: build\web\
) else (
    echo.
    echo ❌ Web build failed
)
pause
goto end

:build_all
echo.
echo Building all versions...
echo.

echo Step 1: Generating icons...
python generate_icons.py
if errorlevel 1 goto build_all_error

echo.
echo Step 2: Getting dependencies...
flutter pub get

echo.
echo Step 3: Building Android APK...
flutter build apk --release
if errorlevel 1 goto build_all_error

echo.
echo Step 4: Building Windows EXE...
flutter build windows --release
if errorlevel 1 goto build_all_error

echo.
echo Step 5: Building Web...
flutter build web
if errorlevel 1 goto build_all_error

echo.
echo ========================================
echo ✅ All builds completed successfully!
echo ========================================
echo.
echo APK: build\app\outputs\apk\release\app-release.apk
echo EXE: build\windows\runner\Release\qrmed.exe
echo WEB: build\web\
echo.
pause
goto end

:build_all_error
echo.
echo ❌ Build failed at one or more steps
echo.
pause
goto end

:clean_build
echo.
echo Cleaning build directories...
flutter clean
flutter pub get
echo ✅ Clean complete
pause
goto end

:invalid_choice
echo Invalid choice
pause
goto end

:end
echo.
echo Thank you for using QRMed Build Script!
echo.
