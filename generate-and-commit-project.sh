#!/bin/bash
set -e

# FlightyClone Project Generation Script
# This script MUST be run on macOS with Xcode 15.4 installed
# Purpose: Generate the .xcodeproj file in format 76 for CI compatibility

echo "=================================================="
echo "FlightyClone Project Generation Script"
echo "=================================================="
echo ""

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ ERROR: This script must be run on macOS"
    echo "   Current OS: $OSTYPE"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ ERROR: Xcode is not installed"
    echo "   Please install Xcode 15.4 from https://developer.apple.com/download/"
    exit 1
fi

# Check Xcode version
XCODE_VERSION=$(xcodebuild -version | head -n 1 | awk '{print $2}')
echo "📱 Detected Xcode version: $XCODE_VERSION"

if [[ ! "$XCODE_VERSION" =~ ^15\.4 ]]; then
    echo "⚠️  WARNING: Xcode 15.4 is required for CI compatibility"
    echo "   Current version: $XCODE_VERSION"
    echo "   The generated project may not work in CI!"
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Aborted"
        exit 1
    fi
fi

# Check if XcodeGen is installed
if ! command -v xcodegen &> /dev/null; then
    echo "❌ ERROR: XcodeGen is not installed"
    echo "   Install it with: brew install xcodegen"
    exit 1
fi

XCODEGEN_VERSION=$(xcodegen --version)
echo "🔧 XcodeGen version: $XCODEGEN_VERSION"
echo ""

# Navigate to FlightyClone directory
if [ ! -d "FlightyClone" ]; then
    echo "❌ ERROR: FlightyClone directory not found"
    echo "   Make sure you're running this script from the repository root"
    exit 1
fi

cd FlightyClone

# Check if project.yml exists
if [ ! -f "project.yml" ]; then
    echo "❌ ERROR: project.yml not found in FlightyClone/"
    exit 1
fi

echo "📄 Found project.yml"
echo ""

# Verify project.yml has correct settings
if ! grep -q 'xcodeVersion: "15.4"' project.yml; then
    echo "⚠️  WARNING: project.yml doesn't specify xcodeVersion: \"15.4\""
    echo "   The project format may not be compatible with CI"
fi

# Remove existing .xcodeproj if it exists
if [ -d "FlightyClone.xcodeproj" ]; then
    echo "🗑️  Removing existing FlightyClone.xcodeproj..."
    rm -rf FlightyClone.xcodeproj
fi

# Generate the project
echo "🔨 Generating Xcode project..."
echo "   Command: xcodegen generate --spec project.yml"
echo ""

if xcodegen generate --spec project.yml; then
    echo ""
    echo "✅ Project generated successfully!"
else
    echo ""
    echo "❌ ERROR: XcodeGen failed to generate the project"
    exit 1
fi

# Verify the project was created
if [ ! -f "FlightyClone.xcodeproj/project.pbxproj" ]; then
    echo "❌ ERROR: project.pbxproj was not created"
    exit 1
fi

# Check the project format
OBJECT_VERSION=$(grep "objectVersion = " FlightyClone.xcodeproj/project.pbxproj | head -n 1 | sed 's/.*objectVersion = \([0-9]*\);/\1/')
echo ""
echo "📋 Project format check:"
echo "   Object Version: $OBJECT_VERSION"

case "$OBJECT_VERSION" in
    "56")
        echo "   ✅ Format 76 (Xcode 15.4) - CI Compatible!"
        ;;
    "60")
        echo "   ❌ Format 77 (Xcode 16+) - NOT CI Compatible!"
        echo "   The CI uses Xcode 15.4 and cannot read this format."
        echo "   Please switch to Xcode 15.4 and regenerate."
        exit 1
        ;;
    *)
        echo "   ⚠️  Unknown format: $OBJECT_VERSION"
        echo "   Expected: 56 (Xcode 15.4)"
        ;;
esac

# Go back to repo root
cd ..

# Check if file is tracked by git
echo ""
echo "📦 Git status check..."

if git ls-files | grep -q "FlightyClone/FlightyClone.xcodeproj/project.pbxproj"; then
    echo "   ✅ project.pbxproj is already tracked"
else
    echo "   ℹ️  project.pbxproj is not yet tracked (first time)"
fi

# Stage the file
echo ""
echo "📝 Staging project.pbxproj..."
git add FlightyClone/FlightyClone.xcodeproj/project.pbxproj

# Check if there are changes
if git diff --cached --quiet; then
    echo "   ℹ️  No changes to commit (file already up to date)"
else
    echo "   ✅ Changes staged"
    
    # Show what changed
    echo ""
    echo "📊 Changes to be committed:"
    git diff --cached --stat FlightyClone/FlightyClone.xcodeproj/project.pbxproj
fi

# Commit the changes
echo ""
read -p "Commit the generated project? (Y/n): " -n 1 -r
echo

if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo "⏸️  Skipping commit. You can commit manually with:"
    echo "   git commit -m \"chore: generate Xcode project with format 76 for CI compatibility\""
    exit 0
fi

if git diff --cached --quiet; then
    echo "ℹ️  Nothing to commit"
else
    git commit -m "chore: generate Xcode project with format 76 for CI compatibility

- Generated with XcodeGen $(xcodegen --version)
- Using Xcode $XCODE_VERSION
- Project format: $OBJECT_VERSION (compatible with CI Xcode 15.4)
- Ensures CI can build without format mismatch errors"
    
    echo ""
    echo "✅ Changes committed!"
fi

# Offer to push
echo ""
read -p "Push to remote? (Y/n): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    CURRENT_BRANCH=$(git branch --show-current)
    echo "🚀 Pushing to origin/$CURRENT_BRANCH..."
    
    if git push origin "$CURRENT_BRANCH"; then
        echo ""
        echo "✅ Successfully pushed!"
    else
        echo ""
        echo "❌ Push failed. You may need to:"
        echo "   - Set up your git remote"
        echo "   - Authenticate with GitHub"
        echo "   - Resolve any conflicts"
    fi
else
    echo "⏸️  Skipping push. Push manually with:"
    echo "   git push origin $(git branch --show-current)"
fi

echo ""
echo "=================================================="
echo "✅ PROJECT GENERATION COMPLETE"
echo "=================================================="
echo ""
echo "Next steps:"
echo "1. Monitor CI at: https://github.com/YOUR_REPO/actions"
echo "2. Verify all checks pass (especially Build and Test)"
echo "3. If CI still fails, check CI logs for errors"
echo ""
echo "Documentation:"
echo "- GENERATE_PROJECT.md - Detailed generation guide"
echo "- CI_FINAL_STATUS.md - Complete CI/CD status"
echo "- NEXT_STEPS.md - Action items"
echo ""
