from PIL import Image, ImageDraw, ImageFont
import os

def create_branding_image(text="SUPREME BIOMEDICAL", output_path='assets/branding.png'):
    # Create a transparent image for branding (text at the bottom)
    # Typically, branding is placed at the bottom 1/4 of the splash screen.
    # We'll create a wide image with the text.
    width, height = 1000, 200
    img = Image.new('RGBA', (width, height), (255, 255, 255, 0))
    draw = ImageDraw.Draw(img)
    
    # Try to use a default font
    try:
        # On Windows, Arial is usually available
        font = ImageFont.truetype("arial.ttf", 60)
    except:
        # Fallback to default
        font = ImageFont.load_default()
    
    # Calculate text position (centered)
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (width - text_width) // 2
    y = (height - text_height) // 2
    
    # Draw text in black (as in web splash) or white?
    # Web splash has color: #000000; font-weight: bold;
    draw.text((x, y), text, fill="black", font=font)
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    img.save(output_path, 'PNG')
    print(f"✅ Branding image created: {output_path}")

def create_android_12_splash_icon(input_path='assets/supreme_logo_transparent.png', output_path='assets/splash_icon_android_12.png'):
    # Android 12 icons are 288x288dp. 
    # The icon should be within a 192dp diameter circle.
    # So the logo should be about 2/3 of the size.
    img = Image.open(input_path)
    
    # Create a square canvas
    size = max(img.size)
    canvas = Image.new('RGBA', (size, size), (255, 255, 255, 0))
    
    # Scale down the logo to fit in the safe circle (66% of canvas size)
    scale_factor = 0.6
    new_size = int(size * scale_factor)
    img_resized = img.resize((new_size, new_size), Image.Resampling.LANCZOS)
    
    # Paste centered
    offset = (size - new_size) // 2
    canvas.paste(img_resized, (offset, offset), img_resized if img_resized.mode == 'RGBA' else None)
    
    # Save
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    canvas.save(output_path, 'PNG')
    print(f"✅ Android 12 splash icon created: {output_path}")

if __name__ == '__main__':
    create_branding_image()
    # Using the transparent logo if available as it's cleaner
    if os.path.exists('assets/supreme_logo_transparent.png'):
        create_android_12_splash_icon('assets/supreme_logo_transparent.png')
    else:
        create_android_12_splash_icon('assets/supreme_logo_transparent.png')
