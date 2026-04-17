import shutil
import os

os.chdir(r'C:\Users\Welcome\Documents\QRmed')

# Copy Android icon to web favicon
shutil.copy(
    r'android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png',
    r'web\favicon.png'
)
print("✓ Favicon updated")

# Copy to Icon-512.png
shutil.copy(
    r'android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png',
    r'web\icons\Icon-512.png'
)
print("✓ Icon-512.png updated")

# Copy to Icon-192.png
shutil.copy(
    r'android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png',
    r'web\icons\Icon-192.png'
)
print("✓ Icon-192.png updated")

# Copy maskable versions
shutil.copy(
    r'android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png',
    r'web\icons\Icon-maskable-512.png'
)
print("✓ Icon-maskable-512.png updated")

shutil.copy(
    r'android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png',
    r'web\icons\Icon-maskable-192.png'
)
print("✓ Icon-maskable-192.png updated")

print("\nAll web icons updated successfully!")
