#!/bin/bash

# FlightyClone Setup Script
# This script helps set up the development environment

set -e

echo "🚀 FlightyClone Setup Script"
echo "============================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo -e "${RED}❌ This script requires macOS${NC}"
    exit 1
fi

echo "📋 Checking prerequisites..."
echo ""

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode is not installed${NC}"
    echo "Please install Xcode from the App Store"
    exit 1
else
    echo -e "${GREEN}✅ Xcode is installed${NC}"
    xcodebuild -version
fi

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}⚠️  Homebrew not found. Installing...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo -e "${GREEN}✅ Homebrew is installed${NC}"
fi

# Check for XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo -e "${YELLOW}⚠️  XcodeGen not found. Installing...${NC}"
    brew install xcodegen
else
    echo -e "${GREEN}✅ XcodeGen is installed${NC}"
fi

# Check for SwiftLint (optional)
if ! command -v swiftlint &> /dev/null; then
    echo -e "${YELLOW}⚠️  SwiftLint not found. Installing...${NC}"
    brew install swiftlint
else
    echo -e "${GREEN}✅ SwiftLint is installed${NC}"
fi

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}⚠️  Node.js not found. Installing...${NC}"
    brew install node
else
    echo -e "${GREEN}✅ Node.js is installed${NC}"
    node --version
fi

echo ""
echo "📦 Setting up iOS project..."
cd FlightyClone

# Generate Xcode project
echo "Generating Xcode project..."
xcodegen generate

if [ -f "FlightyClone.xcodeproj/project.pbxproj" ]; then
    echo -e "${GREEN}✅ Xcode project generated${NC}"
else
    echo -e "${RED}❌ Failed to generate Xcode project${NC}"
    exit 1
fi

echo ""
echo "📱 Setting up Backend..."
cd ../Backend

if [ -f "package.json" ]; then
    echo "Installing Node.js dependencies..."
    npm install
    
    if [ ! -f ".env" ]; then
        echo "Creating .env file from template..."
        cp .env.example .env
        echo -e "${YELLOW}⚠️  Please edit Backend/.env with your APNs credentials${NC}"
    fi
    
    echo -e "${GREEN}✅ Backend dependencies installed${NC}"
else
    echo -e "${RED}❌ Backend package.json not found${NC}"
fi

cd ..

echo ""
echo "============================================"
echo -e "${GREEN}✅ Setup complete!${NC}"
echo "============================================"
echo ""
echo "Next steps:"
echo ""
echo "1. Open the Xcode project:"
echo "   cd FlightyClone"
echo "   open FlightyClone.xcodeproj"
echo ""
echo "2. Configure signing:"
echo "   - Select your Team in Signing & Capabilities"
echo "   - Update bundle identifier if needed"
echo ""
echo "3. Run the app:"
echo "   - Select a simulator"
echo "   - Press Cmd+R to build and run"
echo ""
echo "4. (Optional) Start the backend:"
echo "   cd Backend"
echo "   npm start"
echo ""
echo "For detailed instructions, see SETUP.md"
echo ""
echo "Happy coding! 🚀✈️"
