# QRMed App Build Setup Guide

## App Branding

The QRMed app uses a professional blue QR code scanner icon as the app logo across all platforms:
- **App Color:** Blue (#2563EB)
- **Logo:** QR Code Scanner Icon (Icons.qr_code_scanner)
- **App Name:** QRMed
- **Description:** Medical Equipment Management System

## Platform-Specific Setup

### 1. Android APK Build

**App Name Configuration:**
- ✅ Updated in: `android/app/src/main/AndroidManifest.xml`
- App label: `android:label="QRMed"`

**Icon Setup (Choose One Method):**

#### Method A: Using Flutter Launcher Icons (Recommended)
```bash
# Add flutter_launcher_icons package
flutter pub get

# Generate icons from a base image
# Place your QRMed logo image at: assets/logo/qrmed_logo.png

# Run the icon generator
flutter pub run flutter_launcher_icons

# Or for Android only:
flutter pub run flutter_launcher_icons:main
```

**Icon Size Requirements:**
- Source image: 1024x1024 PNG (recommended)
- The tool automatically generates:
  - mipmap-mdpi: 48x48
  - mipmap-hdpi: 72x72
  - mipmap-xhdpi: 96x96
  - mipmap-xxhdpi: 144x144
  - mipmap-xxxhdpi: 192x192

#### Method B: Manual Icon Placement
Place PNG files in these directories:
```
android/app/src/main/res/
  ├── mipmap-mdpi/ic_launcher.png (48x48)
  ├── mipmap-hdpi/ic_launcher.png (72x72)
  ├── mipmap-xhdpi/ic_launcher.png (96x96)
  ├── mipmap-xxhdpi/ic_launcher.png (144x144)
  └── mipmap-xxxhdpi/ic_launcher.png (192x192)
```

**Build APK:**
```bash
# Debug APK
flutter build apk

# Release APK (optimized)
flutter build apk --release

# Split APKs by architecture (smaller sizes)
flutter build apk --split-per-abi
```

**Output:**
- Debug: `build/app/outputs/apk/debug/app-debug.apk`
- Release: `build/app/outputs/apk/release/app-release.apk`

---

### 2. Windows EXE Build

**Configuration File:** `windows/runner/Runner.rc`

The Windows build uses the icon from the resource file. For custom icon:

1. Create a 256x256 PNG icon
2. Convert to ICO format (using online tool or ImageMagick):
   ```bash
   convert qrmed_logo.png -define icon:auto-resize=256,128,96,64,48,32,16 app_icon.ico
   ```
3. Replace: `windows/runner/resources/app_icon.ico`

**Build EXE:**
```bash
# Debug build
flutter build windows

# Release build (optimized)
flutter build windows --release
```

**Output:**
- `build/windows/runner/Release/qrmed.exe`

**App Title Update:**
- File: `windows/runner/main.cpp`
- The app window will show "QRMed" as title

---

### 3. Web Build

**Configuration:**
- ✅ `web/index.html` - Updated with QRMed branding
- ✅ `web/manifest.json` - PWA manifest configured
- Theme Color: #2563EB (Blue)
- Background Color: #2563EB

**Icon Files:**
Icons are located in `web/icons/`:
- `Icon-192.png` - Mobile app icon
- `Icon-512.png` - Large icon
- `Icon-maskable-192.png` - Maskable icon (modern)
- `Icon-maskable-512.png` - Maskable icon (modern)

Replace these with QRMed logo in the specified sizes.

**Build Web:**
```bash
# Build web version
flutter build web

# Build with base href (if deploying to subdirectory)
flutter build web --base-href="/qrmed/"
```

**Output:**
- `build/web/` - Ready for deployment

**Features:**
- Progressive Web App (PWA) support
- Offline capability with service workers
- Installable on mobile and desktop

---

## Icon Generation from QRMed Logo

### Using Python PIL/Pillow:
```python
from PIL import Image, ImageDraw
import os

def create_qrmed_icon(size=1024, output_path='qrmed_logo.png'):
    # Create image
    img = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw blue circle background
    margin = size * 0.1
    draw.ellipse(
        [margin, margin, size - margin, size - margin],
        fill='#2563EB'
    )
    
    # Draw QR symbol
    qr_size = size * 0.5
    qr_margin = (size - qr_size) / 2
    draw.rectangle(
        [qr_margin, qr_margin, qr_margin + qr_size, qr_margin + qr_size],
        outline='white',
        width=int(size * 0.05)
    )
    
    img.save(output_path)
    print(f"Icon created: {output_path}")

create_qrmed_icon()
```

---

## Build Checklist

- [ ] Android APK
  - [ ] Icon placed in mipmap directories
  - [ ] App name "QRMed" in AndroidManifest.xml
  - [ ] Google Play Services configured
  - [ ] App signed with keystore

- [ ] Windows EXE
  - [ ] Icon converted to ICO format
  - [ ] Placed in `windows/runner/resources/`
  - [ ] Signed (optional but recommended)

- [ ] Web
  - [ ] Icon files in `web/icons/`
  - [ ] manifest.json configured
  - [ ] index.html updated
  - [ ] Hosted on web server

---

## Flutter Commands Reference

```bash
# Get dependencies
flutter pub get

# Clean build
flutter clean

# Build all platforms
flutter build apk --release
flutter build windows --release
flutter build web

# Check project setup
flutter doctor

# Show build info
flutter pub global activate devtools
flutter pub global run devtools
```

---

## Quick Start (APK Only)

1. Place logo at: `assets/logo/qrmed_logo.png`
2. Run: `flutter pub run flutter_launcher_icons`
3. Build: `flutter build apk --release`
4. Find APK at: `build/app/outputs/apk/release/app-release.apk`

---

## Support

For icon generation tools:
- **Android Icons:** [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/)
- **Icon Converters:** [CloudConvert](https://cloudconvert.com/) or [Online Convert](https://image.online-convert.com/)
- **Flutter Launcher Icons:** [pub.dev Package](https://pub.dev/packages/flutter_launcher_icons)

