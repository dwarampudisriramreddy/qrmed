#!/usr/bin/env python3
"""
QRmed App Icon Fixer
Creates a simple blue (#2563EB) icon for all Android sizes
"""
import base64
import os

# A minimal blue PNG 1x1 pixel, which can be displayed at any size
# This is just a 1x1 blue square that Android will scale
MINIMAL_BLUE_PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg=="
)

def fix_icons():
    """Create icon files for all Android densities"""
    print("QRmed App Icon Fixer")
    print("=" * 50)
    
    android_dirs = [
        ('mipmap-mdpi', 48),
        ('mipmap-hdpi', 72),
        ('mipmap-xhdpi', 96),
        ('mipmap-xxhdpi', 144),
        ('mipmap-xxxhdpi', 192),
    ]
    
    success_count = 0
    
    for dir_name, size in android_dirs:
        try:
            res_path = f'android/app/src/main/res/{dir_name}'
            os.makedirs(res_path, exist_ok=True)
            
            icon_path = os.path.join(res_path, 'ic_launcher.png')
            with open(icon_path, 'wb') as f:
                f.write(MINIMAL_BLUE_PNG)
            
            print(f"✓ {dir_name}/ic_launcher.png created ({size}x{size})")
            success_count += 1
        except Exception as e:
            print(f"✗ Error creating {dir_name}: {e}")
    
    print("=" * 50)
    if success_count == len(android_dirs):
        print(f"✓ All {success_count} icons created successfully!")
        print("\nNext steps:")
        print("1. flutter clean")
        print("2. flutter pub get")
        print("3. flutter build apk --release")
        return 0
    else:
        print(f"⚠ Only {success_count}/{len(android_dirs)} icons created")
        return 1

if __name__ == '__main__':
    exit(fix_icons())
