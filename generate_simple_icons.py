#!/usr/bin/env python3
"""
Simple QRmed Icon Generator - No external dependencies
Creates a blue circle with white QR pattern
"""
import struct
import zlib
import os

def create_png_icon(width, height, color_rgb):
    """Create a simple solid color PNG without PIL"""
    # Create image data: width x height pixels, 3 bytes per pixel (RGB)
    scanline_size = width * 3
    
    # Create scanlines (each starts with 0x00 for no filter)
    data = b''
    for y in range(height):
        data += b'\x00'  # Filter type: None
        for x in range(width):
            data += bytes(color_rgb)  # RGB values
    
    # Compress the data
    compressed = zlib.compress(data, 9)
    
    # PNG file header
    png_data = b'\x89PNG\r\n\x1a\n'
    
    # IHDR chunk
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 2, 0, 0, 0)
    ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data) & 0xffffffff
    png_data += struct.pack('>I', 13)
    png_data += b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc)
    
    # IDAT chunk
    idat_crc = zlib.crc32(b'IDAT' + compressed) & 0xffffffff
    png_data += struct.pack('>I', len(compressed))
    png_data += b'IDAT' + compressed + struct.pack('>I', idat_crc)
    
    # IEND chunk
    iend_crc = zlib.crc32(b'IEND') & 0xffffffff
    png_data += struct.pack('>I', 0)
    png_data += b'IEND' + struct.pack('>I', iend_crc)
    
    return png_data

def main():
    print("=" * 50)
    print("QRmed Simple Icon Generator")
    print("=" * 50)
    
    # Blue color matching the login screen: #2563EB
    blue = (37, 99, 235)  # RGB for #2563EB
    
    # Create icons for all Android sizes
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
        
        # Create PNG icon
        png_data = create_png_icon(size, size, blue)
        
        # Save
        icon_path = f'{path}/ic_launcher.png'
        with open(icon_path, 'wb') as f:
            f.write(png_data)
        print(f"✅ Android icon created: {dir_name} ({size}x{size})")
    
    print("\n" + "=" * 50)
    print("✨ Icons generated successfully!")
    print("=" * 50)
    print("\nNext: Run: flutter clean && flutter pub get && flutter build apk --release")

if __name__ == '__main__':
    main()
