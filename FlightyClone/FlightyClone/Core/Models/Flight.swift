import Foundation
import CoreLocation

struct Flight: Identifiable, Codable, Hashable {
    let id: String
    let icao24: String
    let callsign: String?
    let originCountry: String
    
    var position: Position?
    var velocity: Velocity?
    var altitude: Altitude?
    var status: FlightStatus
    var departureAirport: Airport?
    var arrivalAirport: Airport?
    var aircraft: Aircraft?
    
    var estimatedDeparture: Date?
    var actualDeparture: Date?
    var estimatedArrival: Date?
    var actualArrival: Date?
    
    var lastUpdate: Date
    var delayConfidence: DelayConfidence?
    
    struct Position: Codable, Hashable {
        let latitude: Double
        let longitude: Double
        let onGround: Bool
        
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    struct Velocity: Codable, Hashable {
        let horizontal: Double? // m/s
        let vertical: Double? // m/s
        let heading: Double? // degrees
        
        var speedKnots: Double? {
            horizontal.map { $0 * 1.94384 }
        }
        
        var speedMPH: Double? {
            horizontal.map { $0 * 2.23694 }
        }
    }
    
    struct Altitude: Codable, Hashable {
        let barometric: Double? // meters
        let geometric: Double? // meters
        
        var baroFeet: Double? {
            barometric.map { $0 * 3.28084 }
        }
        
        var geoFeet: Double? {
            geometric.map { $0 * 3.28084 }
        }
    }
    
    var displayCallsign: String {
        callsign?.trimmingCharacters(in: .whitespaces) ?? icao24.uppercased()
    }
    
    var route: String? {
        guard let departure = departureAirport?.iata ?? departureAirport?.icao,
              let arrival = arrivalAirport?.iata ?? arrivalAirport?.icao else {
            return nil
        }
        return "\(departure) → \(arrival)"
    }
    
    var estimatedDelay: TimeInterval? {
        guard let estimated = estimatedArrival,
              let actual = actualArrival ?? estimatedArrival else {
            return nil
        }
        return actual.timeIntervalSince(estimated)
    }
    
    var isDelayed: Bool {
        guard let delay = estimatedDelay else { return false }
        return delay > 900 // 15 minutes
    }
}

enum FlightStatus: String, Codable, CaseIterable {
    case scheduled
    case boarding
    case departed
    case enRoute
    case landing
    case landed
    case cancelled
    case diverted
    case unknown
    
    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .boarding: return "Boarding"
        case .departed: return "Departed"
        case .enRoute: return "En Route"
        case .landing: return "Landing"
        case .landed: return "Landed"
        case .cancelled: return "Cancelled"
        case .diverted: return "Diverted"
        case .unknown: return "Unknown"
        }
    }
    
    var color: String {
        switch self {
        case .scheduled, .boarding: return "blue"
        case .departed, .enRoute: return "green"
        case .landing, .landed: return "purple"
        case .cancelled, .diverted: return "red"
        case .unknown: return "gray"
        }
    }
}

struct DelayConfidence: Codable, Hashable {
    let probability: Double // 0.0 to 1.0
    let factors: [DelayFactor]
    let estimatedDelayMinutes: Int
    
    enum DelayFactor: String, Codable, CaseIterable {
        case weather
        case airTrafficControl
        case mechanicalIssue
        case crewScheduling
        case airportCongestion
        case historicalPattern
        
        var displayName: String {
            switch self {
            case .weather: return "Weather"
            case .airTrafficControl: return "Air Traffic Control"
            case .mechanicalIssue: return "Mechanical Issue"
            case .crewScheduling: return "Crew Scheduling"
            case .airportCongestion: return "Airport Congestion"
            case .historicalPattern: return "Historical Pattern"
            }
        }
    }
    
    var confidenceLevel: String {
        switch probability {
        case 0.8...: return "High"
        case 0.5..<0.8: return "Medium"
        default: return "Low"
        }
    }
}

extension Flight {
    static func mock(
        id: String = UUID().uuidString,
        callsign: String = "UAL123",
        status: FlightStatus = .enRoute
    ) -> Flight {
        Flight(
            id: id,
            icao24: "a12345",
            callsign: callsign,
            originCountry: "United States",
            position: Position(latitude: 37.7749, longitude: -122.4194, onGround: false),
            velocity: Velocity(horizontal: 250, vertical: 0, heading: 90),
            altitude: Altitude(barometric: 10000, geometric: 10050),
            status: status,
            departureAirport: Airport.mock(iata: "SFO", name: "San Francisco International"),
            arrivalAirport: Airport.mock(iata: "JFK", name: "John F. Kennedy International"),
            aircraft: Aircraft.mock(),
            estimatedDeparture: Date().addingTimeInterval(-3600),
            actualDeparture: Date().addingTimeInterval(-3500),
            estimatedArrival: Date().addingTimeInterval(14400),
            actualArrival: nil,
            lastUpdate: Date(),
            delayConfidence: DelayConfidence(
                probability: 0.3,
                factors: [.weather, .airTrafficControl],
                estimatedDelayMinutes: 15
            )
        )
    }
}
