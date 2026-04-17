#!/usr/bin/env python3
import base64
import os

# Simple 48x48 blue PNG icon
# This is the smallest size needed
ICON_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAAF0lEQVR4nGNkGAGgGo2CUTAKRsEoGAWjYBSMglGgZgAAAA//aVRYdFhNTDpjb20uYWRvYmUueG1wAAAAAAA8P3hwYWNrZXQgYmVnaW49Iu+7vyIgaWQ9Ilc1TTBNcENlaGlIelJlU3pOVGN6a2M5ZCIgPz4KPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNi4wLWMwMDIgNzkuMTY0NTY4LCAyMDIwLzA0LzI5LTE3OjU2OjU3ICAgICAgICAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iPgogICAgICAgICA8eG1wOkNyZWF0b3JUb29sIkFkb2JlIFBob3Rvc2hvcCAyMS4wIChXaW5kb3dzKSI8L3htcDpDcmVhdG9yVG9vbD4KICAgICAgPC9yZGY6RGVzY3JpcHRpb24+CiAgIDwvcmRmOlJERj4KPC94OnhtcG1ldGE+Cvy0EGwAAAA7SURBVHic7ZExAQAwDAPAtf+BtsOA1SIAAFV93Q+3pKSEhISEhISEhISEhISEhISEhISEhISEhISEhISExA8BHW+4mfQwg5gAAAAASUVORK5CYII="

def create_all_icons():
    """Create icon files in all Android directories"""
    sizes = {
        'mipmap-mdpi': (48, 48),
        'mipmap-hdpi': (72, 72),
        'mipmap-xhdpi': (96, 96),
        'mipmap-xxhdpi': (144, 144),
        'mipmap-xxxhdpi': (192, 192),
    }
    
    icon_data = base64.b64decode(ICON_BASE64)
    
    for dir_name, (width, height) in sizes.items():
        path = f'android/app/src/main/res/{dir_name}'
        os.makedirs(path, exist_ok=True)
        
        icon_file = f'{path}/ic_launcher.png'
        with open(icon_file, 'wb') as f:
            f.write(icon_data)
        
        print(f"✅ Created {dir_name}/ic_launcher.png")

if __name__ == '__main__':
    create_all_icons()
    print("Done! Icons created successfully.")
