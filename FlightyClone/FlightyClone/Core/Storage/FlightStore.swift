import Foundation
import Combine

@MainActor
class FlightStore: ObservableObject {
    @Published var flights: [Flight] = []
    @Published var trackedFlights: Set<String> = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let client: OpenSkyClient
    private var refreshTask: Task<Void, Never>?
    private let refreshInterval: TimeInterval = 10.0
    
    init(client: OpenSkyClient) {
        self.client = client
        loadTrackedFlights()
    }
    
    func startAutoRefresh() {
        stopAutoRefresh()
        
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshFlights()
                try? await Task.sleep(nanoseconds: UInt64((self?.refreshInterval ?? 10) * 1_000_000_000))
            }
        }
    }
    
    func stopAutoRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
    
    func refreshFlights() async {
        isLoading = true
        error = nil
        
        do {
            let states = try await client.fetchAllFlightStates()
            let newFlights = states.compactMap { convertStateToFlight($0) }
            flights = newFlights
        } catch {
            self.error = error
            print("❌ Error fetching flights: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func trackFlight(_ flightId: String) {
        trackedFlights.insert(flightId)
        saveTrackedFlights()
    }
    
    func untrackFlight(_ flightId: String) {
        trackedFlights.remove(flightId)
        saveTrackedFlights()
    }
    
    func isTracked(_ flightId: String) -> Bool {
        trackedFlights.contains(flightId)
    }
    
    func getTrackedFlights() -> [Flight] {
        flights.filter { trackedFlights.contains($0.id) }
    }
    
    func searchFlights(query: String) -> [Flight] {
        let normalizedQuery = query.lowercased()
        
        return flights.filter { flight in
            flight.callsign?.lowercased().contains(normalizedQuery) == true ||
            flight.icao24.lowercased().contains(normalizedQuery) ||
            flight.departureAirport?.icao.lowercased().contains(normalizedQuery) == true ||
            flight.departureAirport?.iata?.lowercased().contains(normalizedQuery) == true ||
            flight.arrivalAirport?.icao.lowercased().contains(normalizedQuery) == true ||
            flight.arrivalAirport?.iata?.lowercased().contains(normalizedQuery) == true
        }
    }
    
    func calculateDelayConfidence(for flight: Flight) -> DelayConfidence? {
        var factors: [DelayConfidence.DelayFactor] = []
        var probability: Double = 0.0
        var estimatedDelayMinutes = 0
        
        if let altitude = flight.altitude?.baroFeet, altitude < 5000 {
            factors.append(.airTrafficControl)
            probability += 0.2
        }
        
        if let velocity = flight.velocity?.speedKnots, velocity < 200, flight.position?.onGround == false {
            factors.append(.weather)
            probability += 0.3
            estimatedDelayMinutes += 15
        }
        
        if flight.status == .boarding {
            factors.append(.historicalPattern)
            probability += 0.1
        }
        
        if probability > 0 {
            return DelayConfidence(
                probability: min(probability, 1.0),
                factors: factors,
                estimatedDelayMinutes: estimatedDelayMinutes
            )
        }
        
        return nil
    }
    
    private func convertStateToFlight(_ state: OpenSkyStateVector) -> Flight? {
        let id = "\(state.icao24)_\(state.lastContact)"
        
        let position: Flight.Position? = if let lat = state.latitude, let lon = state.longitude {
            Flight.Position(latitude: lat, longitude: lon, onGround: state.onGround)
        } else {
            nil
        }
        
        let velocity: Flight.Velocity? = Flight.Velocity(
            horizontal: state.velocity,
            vertical: state.verticalRate,
            heading: state.trueTrack
        )
        
        let altitude: Flight.Altitude? = Flight.Altitude(
            barometric: state.baroAltitude,
            geometric: state.geoAltitude
        )
        
        let status: FlightStatus = state.onGround ? .landed : .enRoute
        
        var flight = Flight(
            id: id,
            icao24: state.icao24,
            callsign: state.callsign,
            originCountry: state.originCountry,
            position: position,
            velocity: velocity,
            altitude: altitude,
            status: status,
            departureAirport: nil,
            arrivalAirport: nil,
            aircraft: nil,
            estimatedDeparture: nil,
            actualDeparture: nil,
            estimatedArrival: nil,
            actualArrival: nil,
            lastUpdate: Date(timeIntervalSince1970: TimeInterval(state.lastContact))
        )
        
        flight.delayConfidence = calculateDelayConfidence(for: flight)
        
        return flight
    }
    
    private func loadTrackedFlights() {
        if let data = UserDefaults.standard.data(forKey: "trackedFlights"),
           let flights = try? JSONDecoder().decode(Set<String>.self, from: data) {
            trackedFlights = flights
        }
    }
    
    private func saveTrackedFlights() {
        if let data = try? JSONEncoder().encode(trackedFlights) {
            UserDefaults.standard.set(data, forKey: "trackedFlights")
        }
    }
}
