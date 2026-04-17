@echo off
cd /d C:\Users\Welcome\Documents\QRmed
echo Building APK...
flutter clean
flutter pub get
flutter build apk --release
echo Build complete!
pause
