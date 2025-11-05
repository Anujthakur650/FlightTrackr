import XCTest

final class FlightListUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["USE_MOCK_DATA"] = "1"
        app.launch()
    }
    
    func testFlightListDisplayed() throws {
        // Verify the tab bar exists
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
        
        // Verify Flights tab is visible
        let flightsTab = tabBar.buttons["Flights"]
        XCTAssertTrue(flightsTab.exists)
        flightsTab.tap()
        
        // Wait for flights to load
        let flightsList = app.collectionViews.firstMatch
        let exists = flightsList.waitForExistence(timeout: 5)
        XCTAssertTrue(exists, "Flights list should be displayed")
    }
    
    func testSearchFunctionality() throws {
        // Tap Search tab
        let tabBar = app.tabBars.firstMatch
        let searchTab = tabBar.buttons["Search"]
        searchTab.tap()
        
        // Find and tap the search field
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.exists)
        searchField.tap()
        
        // Type search query
        searchField.typeText("UAL")
        
        // Wait for search results
        sleep(1)
        
        // Verify results are displayed
        let searchResults = app.collectionViews.firstMatch
        XCTAssertTrue(searchResults.exists)
    }
    
    func testFlightDetailNavigation() throws {
        // Navigate to Flights tab
        let tabBar = app.tabBars.firstMatch
        let flightsTab = tabBar.buttons["Flights"]
        flightsTab.tap()
        
        // Wait for flights to load
        let flightsList = app.collectionViews.firstMatch
        _ = flightsList.waitForExistence(timeout: 5)
        
        // Tap on first flight if available
        let firstCell = flightsList.cells.firstMatch
        if firstCell.exists {
            firstCell.tap()
            
            // Verify detail view is displayed
            let detailView = app.scrollViews.firstMatch
            let exists = detailView.waitForExistence(timeout: 3)
            XCTAssertTrue(exists, "Flight detail view should be displayed")
            
            // Go back
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    func testTrackFlight() throws {
        // Navigate to Flights tab
        let tabBar = app.tabBars.firstMatch
        let flightsTab = tabBar.buttons["Flights"]
        flightsTab.tap()
        
        // Wait for flights to load
        let flightsList = app.collectionViews.firstMatch
        _ = flightsList.waitForExistence(timeout: 5)
        
        // Tap on first flight
        let firstCell = flightsList.cells.firstMatch
        if firstCell.exists {
            firstCell.tap()
            
            // Tap track/star button
            let starButton = app.navigationBars.buttons.matching(identifier: "star").firstMatch
            if starButton.exists {
                starButton.tap()
                
                // Go back to main view
                app.navigationBars.buttons.firstMatch.tap()
                
                // Navigate to Tracked tab
                let trackedTab = tabBar.buttons["Tracked"]
                trackedTab.tap()
                
                // Verify tracked flights view
                let trackedList = app.collectionViews.firstMatch
                let exists = trackedList.waitForExistence(timeout: 3)
                XCTAssertTrue(exists, "Tracked flights should be displayed")
            }
        }
    }
    
    func testSettingsNavigation() throws {
        // Navigate to Settings tab
        let tabBar = app.tabBars.firstMatch
        let settingsTab = tabBar.buttons["Settings"]
        settingsTab.tap()
        
        // Verify settings view is displayed
        let settingsList = app.tables.firstMatch
        let exists = settingsList.waitForExistence(timeout: 3)
        XCTAssertTrue(exists, "Settings should be displayed")
    }
    
    func testPullToRefresh() throws {
        // Navigate to Flights tab
        let tabBar = app.tabBars.firstMatch
        let flightsTab = tabBar.buttons["Flights"]
        flightsTab.tap()
        
        // Wait for flights to load
        let flightsList = app.collectionViews.firstMatch
        _ = flightsList.waitForExistence(timeout: 5)
        
        // Pull to refresh
        let firstCell = flightsList.cells.firstMatch
        let start = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let finish = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 2.0))
        start.press(forDuration: 0, thenDragTo: finish)
        
        // Wait a moment for refresh to complete
        sleep(2)
        
        // Verify list still exists
        XCTAssertTrue(flightsList.exists)
    }
    
    func testAccessibility() throws {
        // Navigate to Flights tab
        let tabBar = app.tabBars.firstMatch
        let flightsTab = tabBar.buttons["Flights"]
        XCTAssertTrue(flightsTab.isAccessibilityElement)
        
        flightsTab.tap()
        
        // Verify accessibility elements exist
        let flightsList = app.collectionViews.firstMatch
        _ = flightsList.waitForExistence(timeout: 5)
        
        let firstCell = flightsList.cells.firstMatch
        if firstCell.exists {
            XCTAssertTrue(firstCell.isAccessibilityElement || firstCell.children(matching: .any).firstMatch.isAccessibilityElement)
        }
    }
}
