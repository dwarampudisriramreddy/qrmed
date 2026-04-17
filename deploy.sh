#!/bin/bash
# QRMed App - Netlify Deployment Script

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting QRmed Web Deployment to Netlify...${NC}"
echo "==========================================="

# Step 1: Clean build
echo -e "${YELLOW}Step 1: Cleaning build directories...${NC}"
flutter clean
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Clean failed. Continuing anyway...${NC}"
fi

# Step 2: Get dependencies
echo -e "${YELLOW}Step 2: Fetching dependencies...${NC}"
flutter pub get
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Failed to fetch dependencies. Stopping.${NC}"
    exit 1
fi

# Step 3: Build Web version
echo -e "${YELLOW}Step 3: Building Flutter Web (Release Mode)...${NC}"
flutter build web --release
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Web built successfully!${NC}"
    echo "Location: build/web/"
else
    echo -e "${RED}❌ Web build failed. Stopping.${NC}"
    exit 1
fi

# Step 4: Deploy to Netlify
echo -e "${YELLOW}Step 4: Deploying build/web/ to Netlify (Production)...${NC}"
if command -v netlify &> /dev/null; then
    # Deploy only the build/web directory to production
    netlify deploy --prod --dir=build/web/
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✨ SUCCESS! Your project has been deployed to Netlify.${NC}"
        echo -e "${BLUE}Project URL: https://qrmed-supreme.netlify.app${NC}"
        echo ""
    else
        echo -e "${RED}❌ Netlify deployment failed.${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ 'netlify' command not found. Please install it with 'npm install -g netlify-cli'.${NC}"
    echo -e "${YELLOW}Manual action required: Run 'netlify deploy --prod --dir=build/web/' manually.${NC}"
    exit 1
fi
