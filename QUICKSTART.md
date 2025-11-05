# FlightyClone - Quick Start Guide

Get up and running in 5 minutes! ⚡

## Prerequisites

- macOS 13.0+ (Ventura or later)
- Xcode 15.0+
- Homebrew (optional, for automated setup)

## Option 1: Automated Setup (Recommended)

```bash
# Clone the repository
git clone <your-repo-url>
cd FlightyClone

# Run the setup script
./scripts/setup.sh

# Open the project
cd FlightyClone
open FlightyClone.xcodeproj
```

The setup script will:
- ✅ Check for Xcode
- ✅ Install Homebrew (if needed)
- ✅ Install XcodeGen
- ✅ Install SwiftLint
- ✅ Install Node.js
- ✅ Generate Xcode project
- ✅ Install backend dependencies

## Option 2: Manual Setup

### Step 1: Generate Xcode Project

```bash
cd FlightyClone

# Install XcodeGen if not already installed
brew install xcodegen

# Generate the Xcode project
xcodegen generate
```

### Step 2: Open and Configure

```bash
# Open the project
open FlightyClone.xcodeproj
```

In Xcode:
1. Select the FlightyClone project in the navigator
2. Select your Team under "Signing & Capabilities"
3. Build the project (Cmd+B)

### Step 3: Run the App

1. Select a simulator (iPhone 15 Pro recommended)
2. Press Cmd+R to run

The app will automatically use mock data - no setup required!

## Running with Live API

To connect to the real OpenSky Network API:

1. Open `AppEnvironment.swift`
2. Change the configuration:
   ```swift
   let environment = AppEnvironment(configuration: .production)
   ```
3. Rebuild and run

**Note**: OpenSky has rate limits (10 requests/10 seconds for anonymous users).

## Setting Up Push Notifications (Optional)

### 1. Backend Setup

```bash
cd Backend
npm install
cp .env.example .env
```

Edit `.env` and add your APNs credentials:
```env
APNS_KEY_ID=YOUR_KEY_ID
APNS_TEAM_ID=YOUR_TEAM_ID
APNS_KEY_PATH=/path/to/AuthKey.p8
APNS_BUNDLE_ID=com.flightyclone.app
```

Start the backend:
```bash
npm start
```

### 2. iOS App Configuration

In Xcode:
1. Select the project
2. Go to "Signing & Capabilities"
3. Add "Push Notifications" capability
4. Add "Background Modes" capability
   - Check "Remote notifications"

### 3. Test on Device

Push notifications require a physical device:
1. Connect your iPhone/iPad
2. Select it as the build target
3. Run the app (Cmd+R)
4. Grant notification permissions
5. Track a flight to receive notifications

## Common Commands

### Build
```bash
cd FlightyClone
xcodebuild -scheme FlightyClone -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
```

### Run Tests
```bash
xcodebuild -scheme FlightyClone -destination 'platform=iOS Simulator,name=iPhone 15 Pro' test
```

### Lint Code
```bash
swiftlint lint
```

### Clean Build
```bash
xcodebuild clean
rm -rf ~/Library/Developer/Xcode/DerivedData
```

## Project Structure Quick Reference

```
FlightyClone/
├── FlightyClone/
│   ├── App/                    # App entry point
│   ├── Core/                   # Models, services, storage
│   ├── Features/               # UI features
│   ├── LiveActivitySupport/    # Live Activities
│   ├── Widgets/                # Home screen widgets
│   └── Resources/              # Assets, strings
├── FlightyCloneTests/          # Unit tests
└── FlightyCloneUITests/        # UI tests
```

## Key Features to Try

1. **Search Flights**: Tap Search tab, type "UAL" or "SFO"
2. **Track a Flight**: Tap a flight → tap star icon
3. **View Details**: Tap any flight for timeline and map
4. **Quick Actions**: In detail view, try Share/Calendar buttons
5. **Widgets**: Long-press home screen → Add Widget → FlightyClone

## Troubleshooting

### "xcodegen: command not found"
```bash
brew install xcodegen
```

### "Signing Error"
1. Open project in Xcode
2. Select your Team under Signing & Capabilities
3. Let Xcode automatically manage signing

### "Backend won't start"
```bash
cd Backend
rm -rf node_modules
npm install
npm start
```

### "Tests failing"
Make sure mock mode is enabled:
```bash
export USE_MOCK_DATA=1
xcodebuild test ...
```

## Next Steps

- 📖 Read [SETUP.md](SETUP.md) for detailed configuration
- 🎨 Review [CONTRIBUTING.md](CONTRIBUTING.md) for coding standards
- 📝 Check [README.md](README.md) for full feature list
- 🚀 Deploy backend with [docker-compose.yml](docker-compose.yml)

## Getting Help

- 📋 Check existing [GitHub Issues](../../issues)
- 📚 Review the [OpenSky API docs](https://openskynetwork.github.io/opensky-api/)
- 💬 Open a new issue if stuck

## Demo Mode

Perfect for demos and screenshots:

1. Use mock mode (default)
2. Flight data is consistent
3. No internet required
4. Fast and reliable

To enable:
```swift
// In AppEnvironment.swift
let environment = AppEnvironment(configuration: .mock)
```

Or via environment variable:
```bash
export USE_MOCK_DATA=1
```

## One-Line Commands

### Setup Everything
```bash
./scripts/setup.sh && cd FlightyClone && open FlightyClone.xcodeproj
```

### Run Tests Only
```bash
cd FlightyClone && xcodebuild test -scheme FlightyClone -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Start Backend
```bash
cd Backend && npm install && npm start
```

### Docker Backend
```bash
docker-compose up -d
```

---

**That's it! You're ready to fly! ✈️**

For more detailed information, see:
- [SETUP.md](SETUP.md) - Comprehensive setup guide
- [README.md](README.md) - Full documentation
- [CONTRIBUTING.md](CONTRIBUTING.md) - Development guidelines
