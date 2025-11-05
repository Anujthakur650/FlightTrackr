# FlightyClone - iOS Flight Tracking App

A polished iOS flight tracking app inspired by Flighty, built with Swift, SwiftUI, and the OpenSky Network REST API.

## Features

### Core Functionality
- **Real-time Flight Tracking**: Live flight data from OpenSky Network API
- **Flight Details**: Interactive timeline, route map, aircraft information
- **Search**: Find flights by flight number, route, or airport
- **Live Activities**: Track flights on your lock screen (iOS 16+)
- **Widgets**: Quick glance at tracked flights from your home screen
- **Push Notifications**: Get notified about flight status changes

### "1% Better" Features
- **Delay Confidence Heuristic**: Smart predictions for potential delays
- **Quick Actions**: Share flight details or add to calendar in one tap
- **Grouped Notifications**: Intelligent notification grouping for multiple flights
- **Offline Mode**: Cached data for previously viewed flights

### Technical Highlights
- **Clean Architecture**: Modular design with AppCore, FlightUI, Notifications, LiveActivitySupport
- **Robust API Client**: Async/await, automatic retry with exponential backoff, intelligent caching
- **Accessibility**: Full VoiceOver support, Dynamic Type, high contrast modes
- **Localization**: Ready for multiple languages (en, es, fr, de placeholders)
- **Comprehensive Testing**: Unit tests, integration tests, UI tests with mock fixtures

## Architecture

```
FlightyClone/
├── App/                    # App entry point and environment setup
├── Core/                   # Core business logic (AppCore)
│   ├── Models/            # Data models (Flight, Airport, Aircraft)
│   ├── Services/          # OpenSky API client, networking
│   ├── Storage/           # Local persistence and caching
│   └── Configuration/     # App configuration
├── Features/              # Feature modules
│   ├── FlightUI/         # Flight list, detail views, components
│   ├── Notifications/    # Push notification handling
│   └── Search/           # Search functionality
├── LiveActivitySupport/   # Live Activities implementation
├── Widgets/              # Home screen widgets
└── Utilities/            # Shared utilities and extensions
```

## Requirements

- **iOS**: 16.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **Backend**: Node.js 18+ or Python 3.11+ (for APNs service)
- **Docker**: For running the backend service

## Getting Started

### 1. Clone the Repository

```bash
git clone <repository-url>
cd FlightyClone
```

### 2. Install Backend Dependencies

#### Using Node.js:
```bash
cd Backend
npm install
cp .env.example .env
# Edit .env with your APNs credentials
```

#### Using Docker:
```bash
cd Backend
docker build -t flightyclone-backend .
docker run -p 3000:3000 --env-file .env flightyclone-backend
```

### 3. Configure APNs (Apple Push Notification Service)

1. Create an App ID in Apple Developer Portal with Push Notifications capability
2. Generate an APNs Key (.p8 file)
3. Note your Team ID and Key ID
4. Update `Backend/.env`:
   ```
   APNS_KEY_ID=YOUR_KEY_ID
   APNS_TEAM_ID=YOUR_TEAM_ID
   APNS_KEY_PATH=/path/to/AuthKey_XXXXXX.p8
   APNS_ENVIRONMENT=development
   ```

### 4. Configure Live Activities

1. Enable Push Notifications in Xcode project capabilities
2. Add "Supports Live Activities" to Info.plist
3. Configure App Group for widget/activity data sharing

### 5. Build and Run

#### With Live API (requires authentication for some endpoints):
```bash
cd FlightyClone
open FlightyClone.xcodeproj
# Build and run (Cmd+R)
```

#### With Mock Mode (for CI/testing):
The app automatically detects when running in test mode and uses mock fixtures from `FlightyCloneTests/Mocks/`.

To enable mock mode in development:
```swift
// In AppEnvironment.swift
let environment = AppEnvironment(configuration: .mock)
```

### 6. Running Tests

```bash
# Unit tests
xcodebuild test -scheme FlightyClone -destination 'platform=iOS Simulator,name=iPhone 15 Pro'

# UI tests
xcodebuild test -scheme FlightyClone -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -only-testing:FlightyCloneUITests

# With mock fixtures (no network required)
export USE_MOCK_DATA=1
xcodebuild test -scheme FlightyClone -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

## OpenSky Network API

This app uses the [OpenSky Network REST API](https://openskynetwork.github.io/opensky-api/rest.html) for flight data.

### API Endpoints Used
- `GET /api/states/all` - All current flights
- `GET /api/states/all?icao24=<hex>` - Specific aircraft
- `GET /api/flights/aircraft?icao24=<hex>&begin=<time>&end=<time>` - Flight history
- `GET /api/flights/arrival?airport=<icao>&begin=<time>&end=<time>` - Arrivals
- `GET /api/flights/departure?airport=<icao>&begin=<time>&end=<time>` - Departures

### Rate Limits
- **Anonymous**: 10 requests per 10 seconds
- **Authenticated**: 400 requests per hour (4000/day)

The app implements:
- Intelligent caching (5-minute TTL for flight states)
- Exponential backoff retry (3 attempts)
- Request coalescing to minimize API calls
- Offline mode with cached data

### Terms of Service
By using this app, you agree to comply with the [OpenSky Network Terms of Use](https://opensky-network.org/about/terms-of-use). Key points:
- Data is provided for research and non-commercial use
- Attribute OpenSky Network when sharing data
- Do not overload the API with excessive requests
- Consider creating an account for higher rate limits

See `FlightyClone/Resources/OpenSkyTOS.txt` for full terms.

## Backend API Endpoints

The backend service provides APNs integration:

### `POST /api/register-device`
Register a device for push notifications.

```json
{
  "deviceToken": "string",
  "userId": "string (optional)"
}
```

### `POST /api/subscribe`
Subscribe to flight updates.

```json
{
  "deviceToken": "string",
  "flightId": "string",
  "icao24": "string",
  "notificationTypes": ["departure", "arrival", "delay", "gate"]
}
```

### `POST /api/unsubscribe`
Unsubscribe from flight updates.

```json
{
  "deviceToken": "string",
  "flightId": "string"
}
```

### `GET /health`
Health check endpoint.

## Development

### Mock Data
Mock fixtures are located in `FlightyCloneTests/Mocks/`:
- `states-all.json` - Sample flight states
- `flight-detail.json` - Detailed flight information
- `airports.json` - Airport database subset

### Adding New Features
1. Create feature module in `Features/`
2. Define models in `Core/Models/`
3. Add tests in `FlightyCloneTests/Unit/`
4. Update this README

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for consistency (config in `.swiftlint.yml`)
- Prefer composition over inheritance
- Write tests for all business logic

## CI/CD

GitHub Actions workflow (`.github/workflows/ios-ci.yml`) runs on every push:
1. Install dependencies
2. Build app
3. Run unit tests (with mock data)
4. Run UI tests
5. Generate code coverage report
6. Archive build artifacts

## Accessibility

The app is designed with accessibility in mind:
- All interactive elements have accessibility labels
- Supports Dynamic Type (text scaling)
- VoiceOver optimized navigation
- High contrast mode support
- Reduced motion alternatives

## Localization

Supported languages:
- English (en) - Complete
- Spanish (es) - Placeholder
- French (fr) - Placeholder
- German (de) - Placeholder

To add a new language:
1. Add `.lproj` folder in Resources
2. Copy and translate `Localizable.strings`
3. Test with Xcode's language selector

## Troubleshooting

### Push Notifications Not Working
1. Verify APNs credentials in Backend/.env
2. Check provisioning profile has Push Notifications capability
3. Ensure device token is registered via `/api/register-device`
4. Check Backend logs for APNs errors

### Live Activities Not Appearing
1. Verify iOS 16+ is running
2. Check Focus mode settings (Live Activities may be hidden)
3. Ensure "Supports Live Activities" in Info.plist
4. Verify ActivityKit framework is linked

### API Rate Limit Errors
1. Check OpenSky Network status page
2. Consider creating an authenticated account
3. Reduce polling frequency in Settings
4. Use cached data when available

### Build Failures
```bash
# Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData
xcodebuild clean -scheme FlightyClone

# Reset package cache
rm -rf ~/Library/Caches/org.swift.swiftpm
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make small, well-documented commits
4. Add tests for new functionality
5. Update README if needed
6. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- [OpenSky Network](https://opensky-network.org/) for providing free flight data API
- Inspired by the excellent [Flighty app](https://www.flightyapp.com/)
- Icons from SF Symbols

## Contact

For questions or issues, please open a GitHub issue.

---

**Note**: This app is for educational purposes. For production use, ensure compliance with OpenSky Network TOS and Apple's App Store guidelines.
