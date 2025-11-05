import Foundation
@testable import FlightyClone

struct MockData {
    static let openSkyStatesResponse: OpenSkyResponse? = {
        let states = [
            createMockState(
                icao24: "a12345",
                callsign: "UAL123",
                originCountry: "United States",
                longitude: -122.4,
                latitude: 37.7,
                baroAltitude: 10000,
                velocity: 250,
                trueTrack: 90
            ),
            createMockState(
                icao24: "b67890",
                callsign: "DLH456",
                originCountry: "Germany",
                longitude: 8.5,
                latitude: 50.0,
                baroAltitude: 11000,
                velocity: 280,
                trueTrack: 180
            ),
            createMockState(
                icao24: "c11111",
                callsign: "BAW789",
                originCountry: "United Kingdom",
                longitude: -0.4,
                latitude: 51.4,
                baroAltitude: 5000,
                velocity: 150,
                trueTrack: 270
            ),
        ]
        
        return OpenSkyResponse(time: Int(Date().timeIntervalSince1970), states: states)
    }()
    
    static let openSkyFlights: [OpenSkyFlight]? = [
        OpenSkyFlight(
            icao24: "a12345",
            firstSeen: Int(Date().addingTimeInterval(-3600).timeIntervalSince1970),
            estDepartureAirport: "KSFO",
            lastSeen: Int(Date().timeIntervalSince1970),
            estArrivalAirport: "KJFK",
            callsign: "UAL123",
            estDepartureAirportHorizDistance: 100,
            estDepartureAirportVertDistance: 50,
            estArrivalAirportHorizDistance: 200,
            estArrivalAirportVertDistance: 100,
            departureAirportCandidatesCount: 1,
            arrivalAirportCandidatesCount: 1
        ),
    ]
    
    private static func createMockState(
        icao24: String,
        callsign: String,
        originCountry: String,
        longitude: Double,
        latitude: Double,
        baroAltitude: Double,
        velocity: Double,
        trueTrack: Double
    ) -> OpenSkyStateVector {
        // This is a workaround since OpenSkyStateVector uses custom decoding
        // In a real scenario, we would create from JSON
        let json = """
        [
            "\(icao24)",
            "\(callsign)",
            "\(originCountry)",
            \(Int(Date().timeIntervalSince1970)),
            \(Int(Date().timeIntervalSince1970)),
            \(longitude),
            \(latitude),
            \(baroAltitude),
            false,
            \(velocity),
            \(trueTrack),
            0,
            null,
            \(baroAltitude + 50),
            null,
            false,
            0
        ]
        """
        
        return try! JSONDecoder().decode(OpenSkyStateVector.self, from: json.data(using: .utf8)!)
    }
    
    static func mockFlight(
        id: String = UUID().uuidString,
        callsign: String = "UAL123",
        status: FlightStatus = .enRoute,
        withAirports: Bool = true,
        withDelayConfidence: Bool = true
    ) -> Flight {
        var flight = Flight(
            id: id,
            icao24: "a12345",
            callsign: callsign,
            originCountry: "United States",
            position: Flight.Position(latitude: 37.7749, longitude: -122.4194, onGround: false),
            velocity: Flight.Velocity(horizontal: 250, vertical: 0, heading: 90),
            altitude: Flight.Altitude(barometric: 10000, geometric: 10050),
            status: status,
            departureAirport: withAirports ? AirportDatabase.lookup(icao: "KSFO") : nil,
            arrivalAirport: withAirports ? AirportDatabase.lookup(icao: "KJFK") : nil,
            aircraft: Aircraft.mock(),
            estimatedDeparture: Date().addingTimeInterval(-3600),
            actualDeparture: Date().addingTimeInterval(-3500),
            estimatedArrival: Date().addingTimeInterval(14400),
            actualArrival: nil,
            lastUpdate: Date(),
            delayConfidence: withDelayConfidence ? DelayConfidence(
                probability: 0.3,
                factors: [.weather, .airTrafficControl],
                estimatedDelayMinutes: 15
            ) : nil
        )
        
        return flight
    }
    
    static let sampleFlights: [Flight] = [
        mockFlight(id: "1", callsign: "UAL123", status: .enRoute),
        mockFlight(id: "2", callsign: "DLH456", status: .boarding),
        mockFlight(id: "3", callsign: "BAW789", status: .landed),
        mockFlight(id: "4", callsign: "AAL100", status: .departed),
        mockFlight(id: "5", callsign: "SWA200", status: .scheduled),
    ]
}
