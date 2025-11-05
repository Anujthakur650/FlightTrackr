# FlightyClone Setup Guide

This guide will help you set up and run the FlightyClone app locally.

## Prerequisites

- **macOS**: 13.0+ (Ventura or later)
- **Xcode**: 15.0+
- **iOS Device/Simulator**: iOS 16.0+
- **Node.js**: 18+ (for backend)
- **Docker**: (optional, for containerized backend)
- **Apple Developer Account**: Required for push notifications and Live Activities

## Quick Start (5 minutes)

### 1. Generate Xcode Project

We use XcodeGen to generate the Xcode project from `project.yml`:

```bash
# Install XcodeGen (if not already installed)
brew install xcodegen

# Navigate to the project directory
cd FlightyClone

# Generate the Xcode project
xcodegen generate

# Open the project
open FlightyClone.xcodeproj
```

**Alternative: Manual Xcode Project Creation**

If you prefer not to use XcodeGen:

1. Open Xcode
2. Create new iOS App project named "FlightyClone"
3. Add all source files from the repository
4. Configure capabilities (Push Notifications, Background Modes, App Groups)
5. Add test targets

### 2. Configure the App

1. **Update Team ID**:
   - Open `FlightyClone.xcodeproj` in Xcode
   - Select the project in the navigator
   - Under "Signing & Capabilities", select your team
   - Update bundle identifier if needed

2. **Enable Capabilities**:
   - Push Notifications
   - Background Modes (Remote notifications, Background fetch)
   - App Groups (create: `group.com.flightyclone.shared`)

### 3. Run the App (Mock Mode)

The app works out of the box with mock data:

```bash
# In Xcode:
# 1. Select a simulator (iPhone 15 Pro recommended)
# 2. Press Cmd+R to build and run
```

The app will use mock data from `FlightyCloneTests/Mocks/` automatically.

### 4. Set Up Backend (Optional for Push Notifications)

```bash
cd Backend

# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Start the backend
npm start
```

The backend will run on `http://localhost:3000`.

**Note**: Push notifications require APNs configuration (see below).

## Full Setup with APNs (Live Features)

### 1. Apple Developer Portal Setup

#### A. Create App ID

1. Go to [Apple Developer Portal](https://developer.apple.com/)
2. Navigate to Certificates, Identifiers & Profiles
3. Create new App ID:
   - Platform: iOS
   - Description: FlightyClone
   - Bundle ID: `com.flightyclone.app` (or your custom ID)
   - Capabilities: Enable "Push Notifications"
4. Save the App ID

#### B. Create APNs Key

1. In Certificates, Identifiers & Profiles
2. Go to Keys section
3. Click "+" to create new key
4. Name: FlightyClone APNs
5. Enable: Apple Push Notifications service (APNs)
6. Click Continue, then Register
7. **Download the .p8 file** (you can only download once!)
8. Note your Key ID and Team ID

### 2. Configure Backend with APNs

```bash
cd Backend

# Edit .env file
nano .env
```

Add your APNs credentials:

```env
APNS_KEY_ID=ABC123XYZ
APNS_TEAM_ID=DEF456UVW
APNS_KEY_PATH=/path/to/AuthKey_ABC123XYZ.p8
APNS_ENVIRONMENT=development
APNS_BUNDLE_ID=com.flightyclone.app
```

Start the backend:

```bash
npm start
```

Verify APNs configuration:

```bash
curl http://localhost:3000/health
```

Should return:

```json
{
  "status": "ok",
  "apnsConfigured": true,
  ...
}
```

### 3. Configure App for Backend

Update the backend URL in the app:

```bash
# Set environment variable
export BACKEND_URL=http://localhost:3000/api

# Or edit AppConfiguration.swift:
# Replace the backendURL with your backend URL
```

### 4. Test Push Notifications

1. Run the app on a **physical device** (simulator doesn't support push notifications)
2. Grant notification permissions when prompted
3. Track a flight
4. The app will register with the backend
5. Backend will send notifications when flight status changes

### 5. Test Live Activities

1. Run the app on iOS 16+ device
2. Track a flight
3. A Live Activity will appear on the lock screen
4. Pull down from the top-right corner to see Dynamic Island

## Running Tests

### Unit Tests

```bash
# In Xcode:
# Press Cmd+U to run all tests

# Or via command line:
cd FlightyClone
xcodebuild test \
  -scheme FlightyClone \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -enableCodeCoverage YES
```

### UI Tests

```bash
xcodebuild test \
  -scheme FlightyClone \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  -only-testing:FlightyCloneUITests
```

### Backend Tests

```bash
cd Backend
npm test
```

## Development Workflows

### Mock Mode (No Internet Required)

Perfect for:
- Development
- UI testing
- CI/CD
- Demos

Set in `AppEnvironment.swift`:

```swift
let environment = AppEnvironment(configuration: .mock)
```

Or via environment variable:

```bash
export USE_MOCK_DATA=1
```

### Live API Mode

Connect to real OpenSky Network API:

```swift
let environment = AppEnvironment(configuration: .production)
```

**Note**: Respects OpenSky rate limits (10 requests/10 seconds for anonymous users).

## Troubleshooting

### "No Xcode project found"

Generate the project:

```bash
cd FlightyClone
xcodegen generate
```

### "Build Failed: Signing Error"

1. Select project in Xcode
2. Go to Signing & Capabilities
3. Select your team
4. Let Xcode automatically manage signing

### "Push Notifications Not Working"

1. Verify APNs credentials in `.env`
2. Check backend logs: `npm start` should show "✅ APNs provider initialized"
3. Ensure you're using a **physical device** (not simulator)
4. Check provisioning profile includes Push Notifications capability
5. Verify backend is reachable from the app

### "Live Activities Not Appearing"

1. Ensure iOS 16+ is running
2. Check Focus mode settings (may hide Live Activities)
3. Verify "Supports Live Activities" in Info.plist
4. Check ActivityKit framework is linked
5. Try restarting the device

### "Rate Limit Exceeded"

OpenSky API has rate limits:
- Anonymous: 10 requests / 10 seconds
- Authenticated: 400 requests / hour

Solutions:
1. Use mock mode for development
2. Create OpenSky account for higher limits
3. Reduce refresh frequency in app settings
4. Use cached data

### "Backend Connection Failed"

1. Verify backend is running: `curl http://localhost:3000/health`
2. Check firewall settings
3. Ensure correct URL in app configuration
4. Check backend logs for errors

## Docker Deployment

### Build and Run

```bash
# Build image
docker build -t flightyclone-backend Backend/

# Run container
docker run -p 3000:3000 \
  -e APNS_KEY_ID=your_key_id \
  -e APNS_TEAM_ID=your_team_id \
  -e APNS_KEY_PATH=/app/keys/AuthKey.p8 \
  -v /path/to/AuthKey.p8:/app/keys/AuthKey.p8:ro \
  flightyclone-backend
```

### Using Docker Compose

```bash
# Copy and edit .env
cp .env.example .env
nano .env

# Start services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## CI/CD

GitHub Actions workflow runs automatically on push:

```bash
git push origin main
```

The workflow:
1. Builds the app
2. Runs unit tests
3. Runs UI tests
4. Generates coverage report
5. Tests backend
6. Builds Docker image

## Production Deployment

### App Store Submission

1. Archive the app (Product → Archive)
2. Validate the archive
3. Submit to App Store Connect
4. Configure App Store listing
5. Submit for review

### Backend Deployment

Deploy to:
- AWS (EC2, ECS, Lambda)
- Google Cloud (Cloud Run, GKE)
- Heroku
- DigitalOcean
- Your own server

Ensure:
- APNs credentials are secure
- Use production APNs environment
- Set up monitoring and logging
- Configure proper database
- Implement rate limiting
- Set up SSL/TLS

## Additional Resources

- [OpenSky Network API Docs](https://openskynetwork.github.io/opensky-api/rest.html)
- [Apple Push Notifications](https://developer.apple.com/documentation/usernotifications)
- [ActivityKit Documentation](https://developer.apple.com/documentation/activitykit)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)

## Getting Help

- Check the main README.md
- Review the code documentation
- Open a GitHub issue
- Check OpenSky Network status page

## Next Steps

1. ✅ Generate Xcode project
2. ✅ Run app in mock mode
3. ✅ Run tests
4. ⏭️ Configure APNs (optional)
5. ⏭️ Deploy backend (optional)
6. ⏭️ Customize and extend features

Happy coding! 🚀✈️
