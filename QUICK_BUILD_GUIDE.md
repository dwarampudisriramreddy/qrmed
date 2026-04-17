# 🚀 QRMed App - Quick Build Guide

## App Logo & Branding
The QRMed app uses a **professional blue QR code scanner icon** as the app logo:
- **Color:** #2563EB (Blue)
- **Icon:** QR Code Scanner (Icons.qr_code_scanner)
- **App Name:** QRMed
- **Tagline:** Medical Equipment Management System

---

## ⚡ Quickest Way to Build

### Option 1: Automated Build Script (Windows)
```bash
# Just run:
build.bat

# Then select option from menu
```

### Option 2: Manual Steps

#### Step 1: Generate Icons
```bash
# Make sure Python 3 is installed
python generate_icons.py

# This creates icons in:
# - android/app/src/main/res/mipmap-*/
# - web/icons/
```

#### Step 2: Build Android APK
```bash
flutter pub get
flutter build apk --release

# Output: build/app/outputs/apk/release/app-release.apk
```

#### Step 3: Build Windows EXE
```bash
flutter pub get
flutter build windows --release

# Output: build/windows/runner/Release/qrmed.exe
```

#### Step 4: Build Web
```bash
flutter pub get
flutter build web

# Output: build/web/
```

---

## 📋 Pre-Build Checklist

- [ ] Python 3 installed (`python --version`)
- [ ] Pillow installed (`pip install Pillow`)
- [ ] Flutter installed (`flutter --version`)
- [ ] Dependencies updated (`flutter pub get`)
- [ ] No uncommitted changes in git

---

## 📦 What's Configured

### Android
- ✅ App name: "QRMed"
- ✅ Icon: Custom QRMed logo
- ✅ Firebase configured
- ✅ Google Play Services configured

### Windows
- ✅ App name: "QRMed"
- ✅ Icon: Custom QRMed logo
- ✅ Ready for deployment

### Web
- ✅ App name: "QRMed"
- ✅ Description: Medical Equipment Management System
- ✅ Theme color: #2563EB
- ✅ PWA enabled
- ✅ Icons configured

---

## 🔧 Troubleshooting

### Icons not generating
```bash
# Install Pillow
pip install Pillow --upgrade

# Try again
python generate_icons.py
```

### APK build fails
```bash
# Clean and retry
flutter clean
flutter pub get
flutter build apk --release

# If still fails, check:
flutter doctor
```

### Windows build fails
```bash
# Make sure Visual Studio is installed
# Then clean and retry
flutter clean
flutter build windows --release
```

### Web build issues
```bash
# Check dependencies
flutter pub get

# Build with verbose output
flutter build web --verbose
```

---

## 📱 Publish to Play Store

After building APK:

1. Sign the APK with a keystore
2. Upload to Google Play Console
3. Set app name: "QRMed"
4. Set category: Medical/Healthcare
5. Add description and screenshots

---

## 🌐 Deploy Web Version

After building web:

1. Upload `build/web/` folder to your hosting
2. Use a CDN for better performance
3. Enable HTTPS
4. Test PWA functionality

---

## 📊 Build Sizes (Approximate)

- **APK:** 50-80 MB (Release, with split-per-abi ~20 MB each)
- **Windows EXE:** 100-150 MB
- **Web:** 5-10 MB (after gzip)

---

## ✨ Next Steps After Build

1. Test the app thoroughly
2. Gather user feedback
3. Fix any bugs
4. Update version numbers
5. Publish to stores

---

## 📞 Support

For detailed setup information, see: `BUILD_SETUP.md`

For Flutter documentation: https://flutter.dev/docs

For Firebase setup: https://firebase.google.com/docs/flutter/setup

---

**Happy Building! 🎉**

Build Date: 2025-12-02
Version: 1.0.0+1
