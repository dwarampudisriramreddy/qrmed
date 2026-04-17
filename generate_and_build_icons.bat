@echo off
REM QRmed Icon Generator using Python
REM This creates simple blue icons for the app

cd /d C:\Users\Welcome\Documents\QRmed

python generate_simple_icons.py

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Icons generated successfully!
    echo Now building APK...
    flutter clean
    flutter pub get
    flutter build apk --release
) else (
    echo Error generating icons
    exit /b 1
)
