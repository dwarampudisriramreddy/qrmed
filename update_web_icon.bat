@echo off
REM Copy Android app icon to web favicon and icons
copy "android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png" "web\favicon.png"
copy "android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png" "web\icons\Icon-512.png"
copy "android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png" "web\icons\Icon-192.png"
echo Web icons updated successfully!
pause
