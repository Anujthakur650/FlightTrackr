# Contributing to FlightyClone

Thank you for considering contributing to FlightyClone! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on what is best for the community
- Show empathy towards other contributors

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported in Issues
2. Create a new issue with:
   - Clear title and description
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots if applicable
   - Environment details (iOS version, Xcode version)

### Suggesting Features

1. Check if the feature has been suggested
2. Create a new issue with:
   - Clear use case
   - Proposed solution
   - Alternative approaches
   - Potential impact

### Code Contributions

#### 1. Fork and Clone

```bash
# Fork the repository on GitHub
# Then clone your fork
git clone https://github.com/YOUR_USERNAME/flightyclone.git
cd flightyclone
```

#### 2. Create a Branch

```bash
# Create a feature branch
git checkout -b feature/your-feature-name

# Or a bugfix branch
git checkout -b fix/bug-description
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation changes
- `refactor/` - Code refactoring
- `test/` - Test additions/changes

#### 3. Make Your Changes

Follow the coding standards (see below).

#### 4. Write Tests

- Add unit tests for new functionality
- Update existing tests if behavior changes
- Ensure all tests pass
- Aim for high code coverage

```bash
# Run tests
cd FlightyClone
xcodebuild test -scheme FlightyClone -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

#### 5. Commit Your Changes

Use clear, descriptive commit messages:

```bash
git add .
git commit -m "Add delay prediction feature

- Implement DelayConfidence model
- Add delay factors analysis
- Update FlightDetailView with delay info
- Add unit tests for delay calculation"
```

Commit message format:
- First line: Brief summary (50 chars or less)
- Blank line
- Detailed description with bullet points
- Reference issue numbers if applicable

#### 6. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a Pull Request on GitHub with:
- Clear title and description
- Link to related issues
- Screenshots/videos if UI changes
- Notes for reviewers

## Coding Standards

### Swift Style Guide

Follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/).

#### Naming

```swift
// Types: UpperCamelCase
struct FlightDetail { }
class OpenSkyClient { }

// Functions, variables: lowerCamelCase
func fetchFlightData() { }
let flightCount = 10

// Constants: lowerCamelCase
let maximumRetryAttempts = 3

// Boolean names should read as assertions
let isTracked = true
let hasArrived = false
```

#### Code Organization

```swift
// MARK: - Type Definition
struct Flight {
    // MARK: - Properties
    let id: String
    let callsign: String
    
    // MARK: - Computed Properties
    var displayName: String {
        callsign ?? id
    }
    
    // MARK: - Methods
    func track() {
        // Implementation
    }
}

// MARK: - Extensions
extension Flight {
    // Related functionality
}
```

#### SwiftUI Views

```swift
struct FlightDetailView: View {
    // MARK: - Properties
    let flight: Flight
    @State private var isTracked = false
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            content
        }
        .navigationTitle(flight.displayCallsign)
    }
    
    // MARK: - Subviews
    private var content: some View {
        VStack {
            headerView
            statsView
        }
    }
    
    private var headerView: some View {
        // Implementation
    }
}
```

#### Async/Await

```swift
// Prefer async/await over completion handlers
func fetchFlights() async throws -> [Flight] {
    try await client.fetchAllFlightStates()
}

// Mark actor-isolated code appropriately
@MainActor
class FlightStore: ObservableObject {
    // UI updates happen on main actor
}
```

### Architecture Guidelines

#### Feature Structure

```
Features/
├── FeatureName/
│   ├── Views/
│   │   ├── FeatureView.swift
│   │   ├── FeatureDetailView.swift
│   │   └── Components/
│   ├── ViewModels/ (if needed)
│   └── Models/ (feature-specific)
```

#### Dependency Injection

```swift
// Prefer dependency injection
class FlightStore {
    private let client: OpenSkyClient
    
    init(client: OpenSkyClient) {
        self.client = client
    }
}

// Use protocols for testability
protocol FlightDataProviding {
    func fetchFlights() async throws -> [Flight]
}
```

#### Error Handling

```swift
// Define specific errors
enum FlightError: LocalizedError {
    case notFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notFound: return "Flight not found"
        case .invalidData: return "Invalid flight data"
        }
    }
}

// Handle errors gracefully
do {
    let flights = try await fetchFlights()
} catch {
    // Show user-friendly error
    print("Error: \(error.localizedDescription)")
}
```

### Testing Guidelines

#### Unit Tests

```swift
final class FlightStoreTests: XCTestCase {
    var sut: FlightStore!
    var mockClient: MockOpenSkyClient!
    
    override func setUp() {
        mockClient = MockOpenSkyClient()
        sut = FlightStore(client: mockClient)
    }
    
    override func tearDown() {
        sut = nil
        mockClient = nil
    }
    
    func testFetchFlights() async throws {
        // Given
        let expectedFlights = [Flight.mock()]
        mockClient.stubbedFlights = expectedFlights
        
        // When
        await sut.refreshFlights()
        
        // Then
        XCTAssertEqual(sut.flights, expectedFlights)
    }
}
```

#### UI Tests

```swift
final class FlightListUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["USE_MOCK_DATA"] = "1"
        app.launch()
    }
    
    func testDisplaysFlights() {
        // Test implementation
    }
}
```

### Documentation

#### Code Comments

```swift
/// Fetches all current flight states from OpenSky Network API.
///
/// This method implements rate limiting and automatic retry with
/// exponential backoff. Cached results are returned if available
/// and not expired.
///
/// - Returns: Array of flight state vectors
/// - Throws: `OpenSkyError` if the request fails
func fetchAllFlightStates() async throws -> [OpenSkyStateVector] {
    // Implementation
}
```

#### README Updates

- Update README.md if adding new features
- Add usage examples
- Update API documentation
- Keep setup instructions current

### Accessibility

- Add accessibility labels to all interactive elements
- Support Dynamic Type
- Test with VoiceOver
- Ensure sufficient color contrast
- Provide alternatives to motion/animation

```swift
Button("Track Flight") {
    trackFlight()
}
.accessibilityLabel("Track this flight")
.accessibilityHint("Adds the flight to your tracked list")
```

### Localization

- Use localized strings for user-facing text
- Add new strings to Localizable.strings
- Test with different languages

```swift
Text("flight.status.enroute")
    .localized()
```

## Pull Request Process

1. **Self-Review**: Review your own code first
2. **Tests**: Ensure all tests pass
3. **Linting**: Run SwiftLint and fix warnings
4. **Documentation**: Update docs if needed
5. **Description**: Write clear PR description
6. **Review**: Address reviewer feedback
7. **Merge**: Squash and merge when approved

### PR Checklist

- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Tests added/updated
- [ ] All tests pass
- [ ] No SwiftLint warnings
- [ ] Documentation updated
- [ ] Accessibility considered
- [ ] Localization handled
- [ ] Backward compatibility maintained

## Release Process

1. Update version number
2. Update CHANGELOG.md
3. Create release branch
4. Final testing
5. Tag release
6. Build and submit to App Store
7. Merge to main

## Questions?

- Open a GitHub issue
- Check existing documentation
- Review closed issues/PRs

Thank you for contributing! 🎉
