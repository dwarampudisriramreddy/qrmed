@echo off
REM QRmed App Icons Setup
REM This script prepares the app with QRmed branding

cd /d "%~dp0"

echo =========================================================
echo QRmed App Icon Setup
echo =========================================================

REM Create a simple Python script to set up icons
(
echo import base64
echo import os
echo.
echo ICON_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAAF0lEQVR4nGNkGAGgGo2CUTAKRsEoGAWjYBSMglGgZgAAAA=="
echo.
echo def setup_icons():
echo     sizes = {
echo         'mipmap-mdpi': 48,
echo         'mipmap-hdpi': 72,
echo         'mipmap-xhdpi': 96,
echo         'mipmap-xxhdpi': 144,
echo         'mipmap-xxxhdpi': 192,
echo     }
echo.
echo     icon_data = base64.b64decode(ICON_BASE64)
echo.
echo     for dir_name, size in sizes.items(^):
echo         path = f'android/app/src/main/res/{dir_name}'
echo         os.makedirs(path, exist_ok=True^)
echo         icon_file = f'{path}/ic_launcher.png'
echo         with open(icon_file, 'wb'^) as f:
echo             f.write(icon_data^)
echo         print(f'Created {dir_name}/ic_launcher.png'^)
echo.
echo if __name__ == '__main__':
echo     setup_icons(^)
echo     print("Icons setup complete!"^)
) > setup_icons_temp.py

echo.
echo Running icon setup...
python setup_icons_temp.py

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =========================================================
    echo Icons setup complete!
    echo =========================================================
    echo.
    echo Next steps:
    echo 1. Run: flutter clean
    echo 2. Run: flutter pub get
    echo 3. Run: flutter build apk --release
    echo.
    del /q setup_icons_temp.py
) else (
    echo.
    echo =========================================================
    echo Error: Could not setup icons
    echo =========================================================
    pause
    exit /b 1
)
