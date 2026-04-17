#!/usr/bin/env python3
"""
One-liner icon generator for QRmed app
Creates QR-style icons for all Android densities
"""

def main():
    import os
    import sys
    
    # Try PIL first (best quality)
    try:
        from PIL import Image, ImageDraw
        use_pil = True
    except ImportError:
        use_pil = False
        print("Warning: PIL not found, using basic image creation")
    
    base_path = r'C:\Users\Welcome\Documents\QRmed\android\app\src\main\res'
    
    # Density mapping
    sizes = [
        ('mipmap-mdpi', 48),
        ('mipmap-hdpi', 72),
        ('mipmap-xhdpi', 96),
        ('mipmap-xxhdpi', 144),
        ('mipmap-xxxhdpi', 192),
    ]
    
    print("Generating QR code app icons...\n")
    
    if use_pil:
        # High quality icon generation with PIL
        for density, size in sizes:
            dir_path = os.path.join(base_path, density)
            os.makedirs(dir_path, exist_ok=True)
            
            # Create QR-style icon
            img = Image.new('RGB', (size, size), 'white')
            draw = ImageDraw.Draw(img)
            
            # Blue color
            blue = (37, 99, 235)  # #2563EB
            
            # Draw border
            border = max(1, size // 16)
            draw.rectangle([(0, 0), (size-1, size-1)], outline=blue, width=border)
            
            # Cell size
            cell = size // 7
            m = cell // 2
            
            # Position markers (corners)
            pat_size = cell * 2
            draw.rectangle([(m, m), (m+pat_size, m+pat_size)], fill=blue)
            draw.rectangle([(size-m-pat_size, m), (size-m, m+pat_size)], fill=blue)
            draw.rectangle([(m, size-m-pat_size), (m+pat_size, size-m)], fill=blue)
            
            # Center
            c = size // 2
            cs = size // 12
            draw.rectangle([(c-cs, c-cs), (c+cs, c+cs)], fill=blue)
            
            # Save
            icon_path = os.path.join(dir_path, 'ic_launcher.png')
            img.save(icon_path, 'PNG')
            print(f"  ✓ {density:20} ({size:3}x{size:3}px)")
    
    else:
        # Fallback: Create minimal valid PNG files
        # This is a minimal valid 1x1 white PNG
        minimal_png = bytes.fromhex(
            '89504e470d0a1a0a0000000d49484452000000010000000108020000009044710d0a'
            '0000000c49444154085b630f0000010001010140110e170000000049454e44ae426082'
        )
        
        for density, size in sizes:
            dir_path = os.path.join(base_path, density)
            os.makedirs(dir_path, exist_ok=True)
            icon_path = os.path.join(dir_path, 'ic_launcher.png')
            
            with open(icon_path, 'wb') as f:
                f.write(minimal_png)
            
            print(f"  ! {density:20} ({size:3}x{size:3}px) - Basic PNG")
        
        print("\nWarning: Using minimal fallback icons")
        print("For better quality icons, install Pillow: pip install Pillow")
    
    print("\n✓ Done! Icons created for all Android densities")
    print("\nNext: flutter build apk --release")

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
        exit(1)
