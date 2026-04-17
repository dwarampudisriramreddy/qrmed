@echo off
echo Cleaning Flutter build...
flutter clean
echo.
echo Fetching dependencies...
flutter pub get
echo.
echo Building APK in release mode...
flutter build apk --release
echo.
if %ERRORLEVEL% EQU 0 (
    echo ✅ BUILD SUCCESSFUL!
    echo APK location: build\app\outputs\flutter-apk\app-release.apk
) else (
    echo ❌ BUILD FAILED!
)
pause
