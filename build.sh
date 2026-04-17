#!/bin/bash
# QRMed App - Build Commands Quick Reference
# For macOS and Linux users

echo "🚀 QRMed App Build Script"
echo "=========================="
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}Select what to build:${NC}"
echo ""
echo "1. Generate Icons (from logo)"
echo "2. Build APK (Android)"
echo "3. Build Web"
echo "4. Build All (Icons + APK + Web)"
echo "5. Clean Build"
echo "6. Exit"
echo ""

read -p "Enter your choice (1-6): " choice

case $choice in
    1)
        echo -e "${YELLOW}Step 1: Installing Pillow (if needed)${NC}"
        pip3 install Pillow --quiet
        echo -e "${BLUE}Step 2: Generating icons...${NC}"
        python3 generate_icons.py
        echo -e "${GREEN}✅ Icons generated!${NC}"
        ;;
    2)
        echo -e "${BLUE}Building Android APK...${NC}"
        flutter pub get
        flutter build apk --release
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ APK built successfully!${NC}"
            echo "Location: build/app/outputs/apk/release/app-release.apk"
        else
            echo -e "${RED}❌ APK build failed${NC}"
        fi
        ;;
    3)
        echo -e "${BLUE}Building Web version...${NC}"
        flutter pub get
        flutter build web
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Web built successfully!${NC}"
            echo "Location: build/web/"
        else
            echo -e "${RED}❌ Web build failed${NC}"
        fi
        ;;
    4)
        echo -e "${BLUE}Building all versions...${NC}"
        echo ""
        
        echo -e "${YELLOW}Step 1: Installing Pillow${NC}"
        pip3 install Pillow --quiet
        
        echo -e "${YELLOW}Step 2: Generating icons${NC}"
        python3 generate_icons.py
        
        echo ""
        echo -e "${YELLOW}Step 3: Getting dependencies${NC}"
        flutter pub get
        
        echo ""
        echo -e "${YELLOW}Step 4: Building APK${NC}"
        flutter build apk --release
        
        echo ""
        echo -e "${YELLOW}Step 5: Building Web${NC}"
        flutter build web
        
        echo ""
        echo -e "${GREEN}✅ All builds completed!${NC}"
        echo "APK: build/app/outputs/apk/release/app-release.apk"
        echo "WEB: build/web/"
        ;;
    5)
        echo -e "${BLUE}Cleaning build directories...${NC}"
        flutter clean
        flutter pub get
        echo -e "${GREEN}✅ Clean complete${NC}"
        ;;
    6)
        echo "Goodbye!"
        exit 0
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac
