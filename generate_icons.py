#!/usr/bin/env python3
"""
QRMed App Icon Generator
Generates QRMed logo icons for Android, Windows, and Web
"""

from PIL import Image, ImageDraw
import os
import json

def create_qrmed_icon_base(size=1024, output_path='assets/logo/qrmed_logo.png'):
    """
    Create the base QRMed icon - Blue circle with white QR code icon.
    This will be used for all platform icons.
    """
    # Create RGBA image with transparent background
    img = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    # Draw blue circle background
    margin = size * 0.05
    draw.ellipse(
        [margin, margin, size - margin, size - margin],
        fill='#2563EB',
        outline='#1E40AF',
        width=max(1, int(size * 0.02))
    )
    
    # Draw white border
    border_width = int(size * 0.03)
    border_margin = size * 0.04
    draw.ellipse(
        [border_margin, border_margin, size - border_margin, size - border_margin],
        outline='white',
        width=border_width
    )
    
    # Draw QR code symbol (stylized)
    qr_start = int(size * 0.25)
    qr_end = int(size * 0.75)
    qr_color = 'white'
    
    # Top-left corner pattern
    corner_size = int(size * 0.1)
    draw.rectangle([qr_start, qr_start, qr_start + corner_size, qr_start + corner_size], fill=qr_color)
    draw.rectangle([qr_start + int(corner_size/5), qr_start + int(corner_size/5), qr_start + int(corner_size*0.8), qr_start + int(corner_size*0.8)], fill='#2563EB')
    
    # Top-right corner pattern
    draw.rectangle([qr_end - corner_size, qr_start, qr_end, qr_start + corner_size], fill=qr_color)
    draw.rectangle([qr_end - int(corner_size*0.8), qr_start + int(corner_size/5), qr_end - int(corner_size/5), qr_start + int(corner_size*0.8)], fill='#2563EB')
    
    # Bottom-left corner pattern
    draw.rectangle([qr_start, qr_end - corner_size, qr_start + corner_size, qr_end], fill=qr_color)
    draw.rectangle([qr_start + int(corner_size/5), qr_end - int(corner_size*0.8), qr_start + int(corner_size*0.8), qr_end - int(corner_size/5)], fill='#2563EB')
    
    # Center QR pattern
    center = size // 2
    cell_size = int(size * 0.03)
    for i in range(0, 5):
        for j in range(0, 5):
            if (i + j) % 2 == 0:
                x = center - cell_size * 2 + i * cell_size
                y = center - cell_size * 2 + j * cell_size
                draw.rectangle([x, y, x + cell_size, y + cell_size], fill=qr_color)
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    # Save image
    img.save(output_path, 'PNG')
    print(f"✅ Base icon created: {output_path}")
    return img

def create_android_icons(base_img):
    """Create Android icons in all required sizes."""
    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    
    for dir_name, size in sizes.items():
        path = f'android/app/src/main/res/{dir_name}'
        os.makedirs(path, exist_ok=True)
        
        # Resize and save
        resized = base_img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(f'{path}/ic_launcher.png', 'PNG')
        print(f"✅ Android icon created: {dir_name} ({size}x{size})")

def create_web_icons(base_img):
    """Create web app icons in required sizes."""
    sizes = {
        'Icon-192.png': 192,
        'Icon-512.png': 512,
        'Icon-maskable-192.png': 192,
        'Icon-maskable-512.png': 512,
    }
    
    path = 'web/icons'
    os.makedirs(path, exist_ok=True)
    
    for filename, size in sizes.items():
        resized = base_img.resize((size, size), Image.Resampling.LANCZOS)
        resized.save(f'{path}/{filename}', 'PNG')
        print(f"✅ Web icon created: {filename} ({size}x{size})")

def main():
    """Main icon generation process."""
    print("=" * 50)
    print("QRMed App Icon Generator")
    print("=" * 50)
    
    try:
        # Create base icon
        print("\n📦 Creating base icon (1024x1024)...")
        base_img = create_qrmed_icon_base(1024)
        
        # Create Android icons
        print("\n🤖 Creating Android icons...")
        create_android_icons(base_img)
        
        # Create Web icons
        print("\n🌐 Creating Web icons...")
        create_web_icons(base_img)
        
        print("\n" + "=" * 50)
        print("✨ All icons generated successfully!")
        print("=" * 50)
        print("\nNext steps:")
        print("1. Build APK: flutter build apk --release")
        print("2. Build Windows: flutter build windows --release")
        print("3. Build Web: flutter build web")
        
    except ImportError:
        print("❌ Error: Pillow (PIL) is required")
        print("Install with: pip install Pillow")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == '__main__':
    main()
