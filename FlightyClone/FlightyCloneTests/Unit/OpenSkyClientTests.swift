import XCTest
@testable import FlightyClone

final class OpenSkyClientTests: XCTestCase {
    var client: OpenSkyClient!
    var cacheManager: CacheManager!
    
    override func setUp() async throws {
        cacheManager = CacheManager()
        client = OpenSkyClient(
            configuration: AppConfiguration.shared,
            cacheManager: cacheManager,
            useMockData: true
        )
    }
    
    override func tearDown() async throws {
        client = nil
        cacheManager = nil
    }
    
    func testFetchAllFlightStates() async throws {
        let states = try await client.fetchAllFlightStates()
        
        XCTAssertFalse(states.isEmpty, "Should return flight states")
        XCTAssertEqual(states.first?.callsign?.trimmingCharacters(in: .whitespaces), "UAL123")
    }
    
    func testFetchFlightsByAircraft() async throws {
        let flights = try await client.fetchFlightsByAircraft(icao24: "a12345")
        
        XCTAssertFalse(flights.isEmpty, "Should return flights for aircraft")
        XCTAssertEqual(flights.first?.icao24, "a12345")
    }
    
    func testCaching() async throws {
        // First request
        let states1 = try await client.fetchAllFlightStates()
        XCTAssertFalse(states1.isEmpty)
        
        // Second request should use cache
        let states2 = try await client.fetchAllFlightStates()
        XCTAssertEqual(states1.count, states2.count)
    }
}
