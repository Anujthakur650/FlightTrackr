import Foundation
import CoreLocation

struct Airport: Identifiable, Codable, Hashable {
    let id: String
    let icao: String
    let iata: String?
    let name: String
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let timezone: String
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var displayCode: String {
        iata ?? icao
    }
    
    var displayName: String {
        "\(displayCode) - \(name)"
    }
    
    var location: String {
        "\(city), \(country)"
    }
}

extension Airport {
    static func mock(
        icao: String = "KSFO",
        iata: String = "SFO",
        name: String = "San Francisco International Airport"
    ) -> Airport {
        Airport(
            id: icao,
            icao: icao,
            iata: iata,
            name: name,
            city: "San Francisco",
            country: "United States",
            latitude: 37.6213,
            longitude: -122.3790,
            altitude: 4,
            timezone: "America/Los_Angeles"
        )
    }
}

struct AirportDatabase {
    private static let airports: [String: Airport] = loadAirports()
    
    static func lookup(icao: String) -> Airport? {
        airports[icao.uppercased()]
    }
    
    static func lookup(iata: String) -> Airport? {
        airports.values.first { $0.iata?.uppercased() == iata.uppercased() }
    }
    
    static func search(query: String) -> [Airport] {
        let normalizedQuery = query.lowercased()
        return airports.values.filter { airport in
            airport.icao.lowercased().contains(normalizedQuery) ||
            airport.iata?.lowercased().contains(normalizedQuery) == true ||
            airport.name.lowercased().contains(normalizedQuery) ||
            airport.city.lowercased().contains(normalizedQuery)
        }.sorted { $0.name < $1.name }
    }
    
    private static func loadAirports() -> [String: Airport] {
        // In a real app, this would load from a bundled JSON file
        // For now, we'll return a small set of major airports
        let majorAirports = [
            Airport(id: "KSFO", icao: "KSFO", iata: "SFO", name: "San Francisco International Airport",
                   city: "San Francisco", country: "United States", latitude: 37.6213, longitude: -122.3790,
                   altitude: 4, timezone: "America/Los_Angeles"),
            Airport(id: "KJFK", icao: "KJFK", iata: "JFK", name: "John F. Kennedy International Airport",
                   city: "New York", country: "United States", latitude: 40.6413, longitude: -73.7781,
                   altitude: 4, timezone: "America/New_York"),
            Airport(id: "KLAX", icao: "KLAX", iata: "LAX", name: "Los Angeles International Airport",
                   city: "Los Angeles", country: "United States", latitude: 33.9416, longitude: -118.4085,
                   altitude: 38, timezone: "America/Los_Angeles"),
            Airport(id: "KORD", icao: "KORD", iata: "ORD", name: "O'Hare International Airport",
                   city: "Chicago", country: "United States", latitude: 41.9742, longitude: -87.9073,
                   altitude: 205, timezone: "America/Chicago"),
            Airport(id: "KATL", icao: "KATL", iata: "ATL", name: "Hartsfield-Jackson Atlanta International Airport",
                   city: "Atlanta", country: "United States", latitude: 33.6407, longitude: -84.4277,
                   altitude: 313, timezone: "America/New_York"),
            Airport(id: "EGLL", icao: "EGLL", iata: "LHR", name: "London Heathrow Airport",
                   city: "London", country: "United Kingdom", latitude: 51.4700, longitude: -0.4543,
                   altitude: 25, timezone: "Europe/London"),
            Airport(id: "LFPG", icao: "LFPG", iata: "CDG", name: "Charles de Gaulle Airport",
                   city: "Paris", country: "France", latitude: 49.0097, longitude: 2.5479,
                   altitude: 119, timezone: "Europe/Paris"),
            Airport(id: "EDDF", icao: "EDDF", iata: "FRA", name: "Frankfurt Airport",
                   city: "Frankfurt", country: "Germany", latitude: 50.0379, longitude: 8.5622,
                   altitude: 111, timezone: "Europe/Berlin"),
            Airport(id: "RJTT", icao: "RJTT", iata: "HND", name: "Tokyo Haneda Airport",
                   city: "Tokyo", country: "Japan", latitude: 35.5494, longitude: 139.7798,
                   altitude: 6, timezone: "Asia/Tokyo"),
            Airport(id: "WSSS", icao: "WSSS", iata: "SIN", name: "Singapore Changi Airport",
                   city: "Singapore", country: "Singapore", latitude: 1.3644, longitude: 103.9915,
                   altitude: 6, timezone: "Asia/Singapore"),
        ]
        
        return Dictionary(uniqueKeysWithValues: majorAirports.map { ($0.icao, $0) })
    }
}
