import XCTest
@testable import FlightyClone

@MainActor
final class FlightStoreTests: XCTestCase {
    var flightStore: FlightStore!
    var client: OpenSkyClient!
    
    override func setUp() async throws {
        client = OpenSkyClient(
            configuration: AppConfiguration.shared,
            cacheManager: CacheManager(),
            useMockData: true
        )
        flightStore = FlightStore(client: client)
    }
    
    override func tearDown() async throws {
        flightStore = nil
        client = nil
    }
    
    func testRefreshFlights() async throws {
        await flightStore.refreshFlights()
        
        XCTAssertFalse(flightStore.flights.isEmpty, "Should have flights after refresh")
        XCTAssertFalse(flightStore.isLoading, "Should not be loading after refresh completes")
        XCTAssertNil(flightStore.error, "Should not have error on successful refresh")
    }
    
    func testTrackFlight() {
        let flightId = "test-flight-1"
        
        XCTAssertFalse(flightStore.isTracked(flightId), "Flight should not be tracked initially")
        
        flightStore.trackFlight(flightId)
        XCTAssertTrue(flightStore.isTracked(flightId), "Flight should be tracked after tracking")
        
        flightStore.untrackFlight(flightId)
        XCTAssertFalse(flightStore.isTracked(flightId), "Flight should not be tracked after untracking")
    }
    
    func testSearchFlights() async throws {
        await flightStore.refreshFlights()
        
        let results = flightStore.searchFlights(query: "UAL")
        XCTAssertFalse(results.isEmpty, "Should find flights matching query")
    }
    
    func testCalculateDelayConfidence() {
        let flight = MockData.mockFlight(withDelayConfidence: false)
        let confidence = flightStore.calculateDelayConfidence(for: flight)
        
        // With mock data showing normal conditions, confidence should be nil or low
        if let confidence = confidence {
            XCTAssertLessThanOrEqual(confidence.probability, 0.5)
        }
    }
}
