#!/usr/bin/env python3
"""Generate QR code icon for app launcher"""

from PIL import Image, ImageDraw
import os

# Define icon sizes for different densities
sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

def create_qr_icon(size):
    """Create a QR code-like icon"""
    # Create image with white background
    img = Image.new('RGB', (size, size), color='white')
    draw = ImageDraw.Draw(img)
    
    # Draw blue border (QRmed color from login screen)
    border_width = max(1, size // 16)
    draw.rectangle(
        [(0, 0), (size - 1, size - 1)],
        outline='#2563EB',
        width=border_width
    )
    
    # Draw QR-like pattern (corners and center dots)
    cell_size = size // 7
    
    # Top-left corner pattern
    draw.rectangle([(cell_size, cell_size), (cell_size * 3, cell_size * 3)], fill='#2563EB')
    
    # Top-right corner pattern
    draw.rectangle([(size - cell_size * 3, cell_size), (size - cell_size, cell_size * 3)], fill='#2563EB')
    
    # Bottom-left corner pattern
    draw.rectangle([(cell_size, size - cell_size * 3), (cell_size * 3, size - cell_size)], fill='#2563EB')
    
    # Center pattern (QR-like)
    center = size // 2
    center_cell = size // 14
    draw.rectangle(
        [(center - center_cell, center - center_cell), (center + center_cell, center + center_cell)],
        fill='#2563EB'
    )
    
    # Add some pattern in between
    for i in range(1, 6):
        if i % 2 == 0:
            x = cell_size + i * cell_size
            draw.rectangle([(x, cell_size), (x + cell_size // 2, cell_size * 2)], fill='#2563EB')
            y = cell_size + i * cell_size
            draw.rectangle([(cell_size, y), (cell_size * 2, y + cell_size // 2)], fill='#2563EB')
    
    return img

def main():
    base_path = r'C:\Users\Welcome\Documents\QRmed\android\app\src\main\res'
    
    for folder, size in sizes.items():
        folder_path = os.path.join(base_path, folder)
        if not os.path.exists(folder_path):
            os.makedirs(folder_path)
        
        icon_path = os.path.join(folder_path, 'ic_launcher.png')
        img = create_qr_icon(size)
        img.save(icon_path)
        print(f"Created {icon_path} ({size}x{size})")

if __name__ == '__main__':
    main()
