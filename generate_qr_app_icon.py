#!/usr/bin/env python3
"""Generate QR code icons for Android app"""

try:
    from PIL import Image, ImageDraw
except ImportError:
    print("ERROR: PIL/Pillow is not installed")
    print("Install with: pip install Pillow")
    exit(1)

import os

def create_qr_icon(size):
    """Create a QR code-style icon (size x size pixels)"""
    # White background
    img = Image.new('RGB', (size, size), color='white')
    draw = ImageDraw.Draw(img)
    
    # Blue color matching login screen
    blue = '#2563EB'
    
    # Draw thick blue border
    border = max(2, size // 20)
    draw.rectangle(
        [(border, border), (size - border - 1, size - border - 1)],
        outline=blue,
        width=border
    )
    
    # Calculate grid size
    grid = size // 7
    
    # Top-left position marker (2x2 grid cells)
    x, y = grid, grid
    w = grid * 2
    draw.rectangle([(x, y), (x + w, y + w)], fill=blue)
    
    # Top-right position marker
    x = size - grid * 3
    y = grid
    draw.rectangle([(x, y), (x + w, y + w)], fill=blue)
    
    # Bottom-left position marker
    x = grid
    y = size - grid * 3
    draw.rectangle([(x, y), (x + w, y + w)], fill=blue)
    
    # Center timing pattern
    center = size // 2
    csize = grid // 2
    draw.rectangle(
        [(center - csize, center - csize), (center + csize, center + csize)],
        fill=blue
    )
    
    # Add some random pattern details
    for i in range(1, 6):
        if i % 2 == 0:
            px = grid + i * grid // 2
            py = grid + i * grid // 2
            if px < size - grid and py < size - grid:
                draw.rectangle([(px, py), (px + grid // 3, py + grid // 3)], fill=blue)
    
    return img

def main():
    """Generate icons for all Android densities"""
    base_path = r'C:\Users\Welcome\Documents\QRmed\android\app\src\main\res'
    
    sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192,
    }
    
    print("Generating QR code icons for all densities...")
    
    for folder, size in sizes.items():
        folder_path = os.path.join(base_path, folder)
        os.makedirs(folder_path, exist_ok=True)
        
        icon_path = os.path.join(folder_path, 'ic_launcher.png')
        img = create_qr_icon(size)
        img.save(icon_path, 'PNG')
        print(f"  ✓ {folder:20} ({size:3}x{size:3}) -> {icon_path}")
    
    print("\nIcon generation complete!")
    return True

if __name__ == '__main__':
    success = main()
    exit(0 if success else 1)
