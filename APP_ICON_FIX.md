# QRmed App Icon Fix

## Problem
The app icon in the APK was showing the default Flutter icon instead of the QR code icon displayed in the login screen.

## Solution
Replace all Android app icons (across all density buckets) with a QR code-style icon that matches the login screen's `Icons.qr_code_scanner`.

## What Changed
1. **Updated** `pubspec.yaml` - Added image_path configuration for flutter_launcher_icons
2. **Created** Icon generation scripts:
   - `generate_app_icon.py` - Main icon generator (requires Pillow)
   - `generate_icons.bat` - Batch wrapper for easy execution
   - `simple_icon_decoder.py` - Alternative without PIL dependency

## How to Apply the Fix

### Option 1: Using Python (Recommended)
```bash
# Prerequisites: Python 3.6+ with Pillow
pip install Pillow

# Run the generator
python generate_app_icon.py
```

### Option 2: Using Batch File (Windows)
```cmd
# Simply double-click or run
generate_icons.bat
```

### What Gets Generated
The script creates QR code-style app icons in the following directories:

| Density    | Size  | Path                                   |
|-----------|-------|----------------------------------------|
| ldpi      | 36x36 | `android/app/src/main/res/mipmap-ldpi/ic_launcher.png` |
| mdpi      | 48x48 | `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` |
| hdpi      | 72x72 | `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` |
| xhdpi     | 96x96 | `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` |
| xxhdpi    | 144x144 | `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` |
| xxxhdpi   | 192x192 | `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` |

## Icon Design
The generated icon features:
- **White background** with **blue QR pattern** (matching login screen color #2563EB)
- **Three position detection patterns** (corners) - standard QR code design
- **Center timing pattern** - for QR code authenticity
- **Data pattern** - additional QR code details
- **Blue border** - frame for the icon

## Building and Testing

### 1. Generate the Icons
```bash
python generate_app_icon.py
```

### 2. Build the Release APK
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### 3. Test the APK
- Install on Android device: `flutter install`
- Check app launcher icon - should now show QR code icon
- Compare with login screen icon - should match visually

## Verification
To verify the fix was applied:
1. Check the icon files exist:
   ```bash
   ls android/app/src/main/res/mipmap-*/ic_launcher.png
   ```

2. Verify the icon appears correctly in:
   - App launcher
   - Android Settings > Apps
   - APK package icon (when opening file manager)

## Technical Details

### Flutter Launcher Icons Configuration
The `pubspec.yaml` now includes:
```yaml
flutter_launcher_icons:
  android: "ic_launcher"
  windows: true
  web:
    generate: true
  image_path: "assets/app_icon.png"
```

### Icon Generation Specifications
- **Color Scheme**: Blue (#2563EB) on white background
- **Format**: PNG with 95% quality
- **All densities**: Automatically generated from base template

## Troubleshooting

### Issue: "ModuleNotFoundError: No module named 'PIL'"
**Solution**: Install Pillow
```bash
pip install Pillow
```

### Issue: Icons still show old Flutter icon
**Solution**: 
1. Clean the build: `flutter clean`
2. Rebuild: `flutter build apk --release`
3. Clear app cache on device before reinstalling

### Issue: Icon appears pixelated
**Solution**: The script generates icons at native densities. If still pixelated:
1. Check source icon quality
2. Regenerate with updated `generate_app_icon.py`

## Rollback
If you need to revert to the default Flutter icon:
```bash
flutter pub get
flutter pub run flutter_launcher_icons:main
```

## Files Modified
- `pubspec.yaml` - Configuration update
- `android/app/src/main/res/mipmap-*/ic_launcher.png` - All icon files (created/updated)

## Related Files
- `lib/screens/login_screen.dart` - Uses `Icons.qr_code_scanner` (lines 220)
- `android/app/src/main/AndroidManifest.xml` - References `@mipmap/ic_launcher`

## Notes
- The icon generation is automated and can be re-run anytime
- All changes are isolated to Android resources
- No changes to app code or functionality
- iOS and Windows icons can be configured similarly if needed
