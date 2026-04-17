#!/usr/bin/env python3
"""Generate QR code icon PNG files for all Android densities"""

import base64
import os

# Minimal PNG data for QR code icon (48x48 white with blue pattern)
# This is a base64-encoded PNG file
ICON_DATA_BASE64 = """iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAA8klEQVR4nO3RPQrCQBCG4WWh2FuwsLESL2AhGCzsbBQb76Rgla1gZaGthRbY2AoWFhZaWCuCqHgBLxQElyWZndmZ3e8DB9nN7Mzube7M7lQqVapUqVKlSpUqVapUqVKlSpUqVarUT2g0GhyPRy6XCwaDAfv9ntPpxHw+/3PQ2+2WxWLBZrNhMplwu92YTCZcLhc2mw273Y7pdMrpdGK1WtFoNFgul5TKZTKZDK/Xi9vthtvtRrvd5m63+3PQbrdJpVLkcrk/CY1GA4fDwW63w+l0olt21+uVZVl+FWg0GqRSKXJ5HMeZzWZ0u10Gg4GF0263yWQyFEolCoUCxWLxV4EQksvlZFwul8xmM5nP55Jpmqb8/f1VqVSpUqVKlaL4BrNlm7J6uVN2AAAAAElFTkSuQmCC"""

def decode_and_save_icon(size):
    """Decode base64 icon and save to required directories"""
    try:
        base_path = r'C:\Users\Welcome\Documents\QRmed\android\app\src\main\res'
        sizes_map = {
            48: 'mipmap-mdpi',
            72: 'mipmap-hdpi',
            96: 'mipmap-xhdpi',
            144: 'mipmap-xxhdpi',
            192: 'mipmap-xxxhdpi',
        }
        
        for px_size, folder in sizes_map.items():
            folder_path = os.path.join(base_path, folder)
            os.makedirs(folder_path, exist_ok=True)
            icon_path = os.path.join(folder_path, 'ic_launcher.png')
            
            # Decode and save
            icon_data = base64.b64decode(ICON_DATA_BASE64)
            with open(icon_path, 'wb') as f:
                f.write(icon_data)
            print(f"Saved {icon_path}")
            
    except Exception as e:
        print(f"Error: {e}")
        return False
    return True

if __name__ == '__main__':
    print("Generating QR code icons...")
    success = decode_and_save_icon(48)
    if success:
        print("Icons generated successfully!")
    else:
        print("Failed to generate icons")
