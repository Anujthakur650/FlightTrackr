import XCTest
@testable import FlightyClone

final class ModelTests: XCTestCase {
    
    func testFlightModel() {
        let flight = MockData.mockFlight()
        
        XCTAssertNotNil(flight.position)
        XCTAssertNotNil(flight.velocity)
        XCTAssertNotNil(flight.altitude)
        XCTAssertEqual(flight.displayCallsign, "UAL123")
        XCTAssertEqual(flight.route, "SFO → JFK")
    }
    
    func testFlightVelocityConversions() {
        let velocity = Flight.Velocity(horizontal: 100, vertical: 5, heading: 90)
        
        XCTAssertNotNil(velocity.speedKnots)
        XCTAssertNotNil(velocity.speedMPH)
        
        // 100 m/s ≈ 194.384 knots
        XCTAssertEqual(velocity.speedKnots!, 194.384, accuracy: 0.01)
        
        // 100 m/s ≈ 223.694 mph
        XCTAssertEqual(velocity.speedMPH!, 223.694, accuracy: 0.01)
    }
    
    func testFlightAltitudeConversions() {
        let altitude = Flight.Altitude(barometric: 3048, geometric: 3100)
        
        XCTAssertNotNil(altitude.baroFeet)
        XCTAssertNotNil(altitude.geoFeet)
        
        // 3048 meters = 10000 feet
        XCTAssertEqual(altitude.baroFeet!, 10000, accuracy: 1)
    }
    
    func testDelayConfidence() {
        let confidence = DelayConfidence(
            probability: 0.75,
            factors: [.weather, .airTrafficControl],
            estimatedDelayMinutes: 30
        )
        
        XCTAssertEqual(confidence.confidenceLevel, "Medium")
        XCTAssertEqual(confidence.factors.count, 2)
    }
    
    func testAirportDatabase() {
        let sfoByICAO = AirportDatabase.lookup(icao: "KSFO")
        XCTAssertNotNil(sfoByICAO)
        XCTAssertEqual(sfoByICAO?.iata, "SFO")
        
        let sfoByIATA = AirportDatabase.lookup(iata: "SFO")
        XCTAssertNotNil(sfoByIATA)
        XCTAssertEqual(sfoByIATA?.icao, "KSFO")
        
        let searchResults = AirportDatabase.search(query: "francisco")
        XCTAssertFalse(searchResults.isEmpty)
        XCTAssertTrue(searchResults.contains { $0.icao == "KSFO" })
    }
    
    func testAircraftDatabase() {
        let model = AircraftDatabase.modelFromTypeCode("B738")
        XCTAssertEqual(model, "Boeing 737-800")
        
        let manufacturer = AircraftDatabase.manufacturerFromTypeCode("B738")
        XCTAssertEqual(manufacturer, "Boeing")
        
        let airbusManufacturer = AircraftDatabase.manufacturerFromTypeCode("A320")
        XCTAssertEqual(airbusManufacturer, "Airbus")
    }
}
