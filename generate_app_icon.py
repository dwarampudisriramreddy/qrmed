#!/usr/bin/env python3
"""
QRmed App Icon Generator
Generates QR code-style app icons for all Android densities
Matches the login screen icon (Icons.qr_code_scanner)
"""

from PIL import Image, ImageDraw
import os
import sys

def create_qr_icon(size, bg_color='white', qr_color='#2563EB'):
    """
    Create a QR code-style icon
    
    Args:
        size: Icon size in pixels (e.g., 48, 72, 96, etc.)
        bg_color: Background color
        qr_color: QR pattern color (blue from login screen)
    
    Returns:
        PIL.Image object
    """
    # Create image with background
    img = Image.new('RGB', (size, size), color=bg_color)
    draw = ImageDraw.Draw(img)
    
    # Convert color to RGB if hex
    if isinstance(qr_color, str):
        qr_color = tuple(int(qr_color.lstrip('#')[i:i+2], 16) for i in (0, 2, 4))
    
    # Border
    border_width = max(1, size // 16)
    draw.rectangle(
        [(0, 0), (size-1, size-1)],
        outline=qr_color,
        width=border_width
    )
    
    # Cell size for grid
    cell = size // 7
    margin = cell // 2
    
    # Position detection patterns (3 corners) - 2x2 cells each
    pattern_size = cell * 2
    
    # Top-left
    draw.rectangle(
        [(margin, margin), (margin + pattern_size, margin + pattern_size)],
        fill=qr_color
    )
    
    # Top-right
    draw.rectangle(
        [(size - margin - pattern_size, margin), (size - margin, margin + pattern_size)],
        fill=qr_color
    )
    
    # Bottom-left
    draw.rectangle(
        [(margin, size - margin - pattern_size), (margin + pattern_size, size - margin)],
        fill=qr_color
    )
    
    # Center timing pattern
    center = size // 2
    center_size = size // 12
    draw.rectangle(
        [(center - center_size, center - center_size), 
         (center + center_size, center + center_size)],
        fill=qr_color
    )
    
    # Add data pattern
    for i in range(1, 6):
        if i % 2 == 0:
            x = margin + i * cell // 2
            y = margin + i * cell // 2
            if x < size - margin and y < size - margin:
                small_cell = cell // 3
                draw.rectangle(
                    [(x, y), (x + small_cell, y + small_cell)],
                    fill=qr_color
                )
    
    return img

def main():
    """Generate app icons for all Android densities"""
    
    # Android density mapping
    densities = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    
    base_path = r'C:\Users\Welcome\Documents\QRmed\android\app\src\main\res'
    
    print("=" * 70)
    print("QRmed App Icon Generator")
    print("=" * 70)
    print("\nGenerating QR code-style app icons for all Android densities...")
    print("\nMatching login screen icon: Icons.qr_code_scanner")
    print("-" * 70)
    
    try:
        for density, size in densities.items():
            # Create directory
            dir_path = os.path.join(base_path, density)
            os.makedirs(dir_path, exist_ok=True)
            
            # Create and save icon
            icon = create_qr_icon(size)
            icon_path = os.path.join(dir_path, 'ic_launcher.png')
            icon.save(icon_path, 'PNG', quality=95)
            
            print(f"  ✓ {density:20} ({size:3}x{size:3}px) -> ic_launcher.png")
        
        print("-" * 70)
        print("\n✓ SUCCESS: All icons generated!")
        print("\nNext steps:")
        print("  1. Build the APK: flutter build apk --release")
        print("  2. The app icon will now match the login screen QR code icon")
        print("\n" + "=" * 70)
        return 0
        
    except Exception as e:
        print(f"\n✗ ERROR: {e}", file=sys.stderr)
        print("\nTroubleshooting:")
        print("  - Ensure PIL/Pillow is installed: pip install Pillow")
        print("  - Check directory permissions for android/app/src/main/res/")
        print("=" * 70)
        return 1

if __name__ == '__main__':
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        print("\n\nCancelled by user")
        sys.exit(1)
