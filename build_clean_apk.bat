@echo off
echo ========================================
echo QRmed - Complete Clean Build
echo ========================================
echo.

echo Step 1: Removing cached build files...
if exist .dart_tool rmdir /s /q .dart_tool
if exist build rmdir /s /q build
if exist pubspec.lock del pubspec.lock
echo ✓ Cache cleared

echo.
echo Step 2: Running flutter clean...
call flutter clean
echo ✓ Flutter cleaned

echo.
echo Step 3: Getting dependencies...
call flutter pub get
echo ✓ Dependencies fetched

echo.
echo Step 4: Building APK (Release)...
call flutter build apk --release

echo.
if %ERRORLEVEL% EQU 0 (
    echo ========================================
    echo ✅ BUILD SUCCESSFUL!
    echo ========================================
    echo.
    echo APK Location:
    echo build\app\outputs\flutter-apk\app-release.apk
    echo.
) else (
    echo ========================================
    echo ❌ BUILD FAILED!
    echo ========================================
)
echo.
pause
