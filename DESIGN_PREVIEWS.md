# FlightyClone - Design Previews & UI Components

This document describes the visual design and UI components of FlightyClone. Screenshots can be generated using Xcode's Preview Canvas.

## Visual Design System

### Color Palette

#### Status Colors
- **Blue** (#007AFF): Scheduled, Boarding, Normal operations
- **Green** (#34C759): Departed, En Route, Success states
- **Purple** (#AF52DE): Landing, Landed, Completion
- **Orange** (#FF9500): Warnings, Delays, Attention needed
- **Red** (#FF3B30): Cancelled, Diverted, Errors
- **Gray** (#8E8E93): Unknown, Disabled, Secondary text

#### Background Colors
- **Primary**: System background (adaptive)
- **Secondary**: Secondary system background
- **Material**: Ultra thin material (glassmorphic effects)

### Typography

- **Large Title**: Display names, main headers (34pt, bold)
- **Title**: Section headers (28pt, bold)
- **Title 2**: Subsection headers (22pt, bold)
- **Headline**: Flight callsigns, important text (17pt, semibold)
- **Body**: Main content (17pt, regular)
- **Callout**: Supporting info (16pt, regular)
- **Subheadline**: Secondary info (15pt, regular)
- **Footnote**: Metadata (13pt, regular)
- **Caption**: Labels (12pt, regular)
- **Caption 2**: Smallest text (11pt, regular)

### Spacing

- **Extra Small**: 4pt
- **Small**: 8pt
- **Medium**: 12pt
- **Regular**: 16pt
- **Large**: 20pt
- **Extra Large**: 24pt
- **Section**: 32pt

### Corner Radius

- **Small**: 8pt (buttons, badges)
- **Medium**: 12pt (cards, containers)
- **Large**: 16pt (major sections)
- **Circular**: Infinite (pills, indicators)

## Screen Designs

### 1. Flight List View

**Layout**: Navigation stack with tab bar
**Components**:
- Search bar at top
- Pull-to-refresh control
- Flight rows with:
  - Flight callsign (headline)
  - Route (SFO → JFK) (subheadline, secondary)
  - Status badge (capsule with color)
  - Delay indicator (if applicable)
  - Altitude and speed (trailing, caption)
  - Star icon (if tracked)

**Empty State**: Airplane icon with "No Flights Available"

**Preview Code**:
```swift
#Preview {
    FlightListView()
        .environmentObject(FlightStore.mock())
}
```

### 2. Flight Detail View

**Layout**: Scrollable detail view
**Sections**:

#### Header
- Large callsign display (largeTitle)
- Route (title2, secondary)
- Status badge

#### Interactive Map (300pt height)
- Flight position with airplane icon
- Departure airport (green marker)
- Arrival airport (red marker)
- Realistic elevation map style
- Rotated airplane icon based on heading

#### Timeline
- Three-item vertical timeline:
  - **Departure**: Time, airport name, green
  - **En Route**: Current position, blue
  - **Arrival**: Time, airport name, purple
- Progress indicators (filled/unfilled circles)
- Connecting lines between items

#### Flight Stats Grid (2 columns)
- Altitude card
- Speed card
- Heading card
- Country card
- Each with icon, label, value

#### Delay Confidence (if applicable)
- Orange background with warning icon
- Confidence level with percentage
- Estimated delay in minutes
- List of contributing factors

#### Aircraft Info (if available)
- Model, manufacturer, registration
- Operator information

#### Quick Actions
- Three equal-width buttons:
  - Share (square.and.arrow.up icon)
  - Calendar (calendar.badge.plus icon)
  - Notify (bell icon)
- Blue tinted backgrounds

**Preview Code**:
```swift
#Preview {
    NavigationStack {
        FlightDetailView(flight: .mock())
            .environmentObject(FlightStore.mock())
    }
}
```

### 3. Search View

**Layout**: Navigation stack with search field
**Components**:
- Search field with scope selector (Flights/Airports)
- Results list with appropriate row types
- Empty state: Magnifying glass with "No results found"

**Flight Results**: Standard flight rows
**Airport Results**:
- Airport code (headline, blue)
- Airport name (subheadline)
- City, Country (caption, secondary)

**Preview Code**:
```swift
#Preview {
    SearchView()
        .environmentObject(FlightStore.mock())
}
```

### 4. Tracked Flights View

**Layout**: Navigation stack with list
**Components**:
- Enhanced flight rows with:
  - Star icon (yellow)
  - Departure/arrival times
  - Delay warnings
  - Live Activity indicator (green dot)

**Empty State**: Star icon with "No Tracked Flights"
**Message**: "Tap the star icon on any flight to track it here"

**Preview Code**:
```swift
#Preview {
    TrackedFlightsView()
        .environmentObject(FlightStore.mock())
        .environmentObject(AppEnvironment.shared)
}
```

### 5. Settings View

**Layout**: Grouped list style
**Sections**:

#### Notifications
- Status row (Enabled/Disabled)
- Enable button (if disabled)

#### Data
- Clear Cache button
- Refresh All Flights button

#### About
- OpenSky TOS link
- About FlightyClone button
- Version number row

**Footer**: OpenSky Network attribution (caption, centered)

**Preview Code**:
```swift
#Preview {
    SettingsView()
        .environmentObject(AppEnvironment.shared)
}
```

## Widget Designs

### Small Widget (158 x 158)

**Layout**: Compact flight info
**Content**:
- Airplane icon + callsign (top)
- Route (middle)
- Status badge (bottom)

**Preview Code**:
```swift
#Preview(as: .systemSmall) {
    FlightWidget()
} timeline: {
    FlightWidgetEntry(date: .now, flight: .mock())
}
```

### Medium Widget (338 x 158)

**Layout**: Horizontal split
**Left Side**:
- Airplane icon + callsign
- Route
- Status badge

**Right Side**:
- Altitude (large number + "ft")
- Speed (number + "kts")

### Large Widget (338 x 354)

**Layout**: Comprehensive info card
**Content**:
- Header with icon, callsign, status
- Route display
- Stats grid (altitude, speed, heading)
- Arrival time
- Delay warning (if applicable)

## Live Activity Designs

### Lock Screen (Notification Style)

**Layout**: Horizontal banner
**Left Side**:
- Airplane icon
- Callsign (headline)
- Route (subheadline)
- Status badge

**Right Side**:
- Altitude (large)
- Speed (smaller)
- Delay indicator (if applicable)

### Dynamic Island - Compact

**Leading**: Airplane icon (blue)
**Trailing**: Altitude shorthand (e.g., "35k")

### Dynamic Island - Expanded

**Leading**: Icon + callsign + route
**Trailing**: Altitude + speed
**Center**:
- Departure/arrival times
- Progress bar
- Status text
- Delay warning (if applicable)

**Preview Code**:
```swift
#Preview("Notification", as: .content) {
    FlightLiveActivity()
} contentStates: {
    FlightActivityAttributes.ContentState(...)
}
```

## Reusable Components

### StatusBadge

**Style**: Capsule shape
**Content**: Status text (caption)
**Colors**: Status-specific with 0.2 opacity background

### DelayIndicator

**Style**: Warning triangle + minutes
**Color**: Orange
**Format**: "+15m"

### StatCard

**Layout**: Vertical stack
**Content**:
- Icon (top, title2, blue)
- Label (caption, secondary)
- Value (subheadline, bold)
**Background**: .background with 8pt corners

### TimelineItem

**Layout**: Horizontal stack
**Components**:
- Circle indicator (40pt, filled/unfilled)
- Icon inside circle (white)
- Text info (title, time, location)
- Checkmark (if completed)

### InfoRow

**Layout**: Horizontal stack with spacer
**Left**: Label (secondary)
**Right**: Value (bold)

### ActionButton

**Layout**: Vertical button
**Content**:
- Icon (title2)
- Label (caption)
**Style**: Blue tinted background, rounded

## Accessibility Features

### VoiceOver Labels

All interactive elements have descriptive labels:
- "Track this flight" for star button
- "Share flight details" for share button
- Flight callsign with route for list items
- Status descriptions (e.g., "Flight status: En Route")

### Dynamic Type

All text scales with system font size settings.
Minimum tested sizes: Extra Small to Accessibility Extra Extra Extra Large

### Color Contrast

- Status colors meet WCAG AA standards
- High contrast mode supported
- Color blind friendly palette

### Reduced Motion

- Animations can be disabled
- Alternative static presentations
- No essential info conveyed only through motion

## Dark Mode Support

All colors and materials adapt automatically:
- System backgrounds (adaptive)
- Dynamic colors for text
- Material effects (ultra thin, thin, regular)
- Custom colors with dark variants

## Localization

All strings use localized keys:
```swift
Text("tab.flights")  // "Flights"
Text("status.enroute")  // "En Route"
Text("action.share")  // "Share"
```

Supported languages (with placeholders):
- English (en) - Complete
- Spanish (es)
- French (fr)
- German (de)

## Design Principles

1. **Clarity**: Information hierarchy is clear
2. **Efficiency**: Common tasks in 1-2 taps
3. **Consistency**: Patterns repeated throughout
4. **Feedback**: Actions provide immediate response
5. **Accessibility**: Usable by everyone
6. **Beauty**: Delightful visual design

## Generating Screenshots

### In Xcode

1. Open any View file with `#Preview`
2. Show Preview Canvas (Cmd+Option+Return)
3. Right-click preview → "Export Preview"
4. Save as PNG

### Using Simulator

1. Run app in simulator
2. Navigate to desired screen
3. File → New Screen Recording (or Screenshot)
4. Save to desktop

### Suggested Screenshots

1. Flight List (with 5+ flights)
2. Flight Detail (with map visible)
3. Search Results (showing matches)
4. Tracked Flights (with 2+ tracked)
5. Small Widget
6. Medium Widget
7. Large Widget
8. Live Activity on Lock Screen
9. Dynamic Island Expanded
10. Settings View

## Asset Requirements

For App Store submission:
- App Icon: 1024x1024
- Screenshots: 
  - 6.7" (iPhone 15 Pro Max): 1290 x 2796
  - 6.5" (iPhone 14 Pro Max): 1284 x 2778
  - 5.5" (iPhone 8 Plus): 1242 x 2208

## Design Tools

Recommended for mockups:
- Figma (UI design)
- Sketch (UI design)
- Adobe XD (UI design)
- SF Symbols (Apple icons)

---

**All designs follow Apple's Human Interface Guidelines**

For more details, see:
- [HIG - iOS](https://developer.apple.com/design/human-interface-guidelines/ios)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Accessibility](https://developer.apple.com/accessibility/)
