import Foundation
import ActivityKit

@MainActor
class LiveActivityManager: ObservableObject {
    @Published var activeActivities: [String: Activity<FlightActivityAttributes>] = [:]
    
    func startActivity(for flight: Flight) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("⚠️ Live Activities are not enabled")
            return
        }
        
        let attributes = FlightActivityAttributes(
            flightId: flight.id,
            callsign: flight.displayCallsign,
            route: flight.route ?? "Unknown Route"
        )
        
        let initialState = FlightActivityAttributes.ContentState(
            status: flight.status.displayName,
            departureTime: flight.estimatedDeparture,
            arrivalTime: flight.estimatedArrival,
            currentAltitude: flight.altitude?.baroFeet,
            currentSpeed: flight.velocity?.speedKnots,
            delayMinutes: flight.delayConfidence?.estimatedDelayMinutes ?? 0
        )
        
        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: .token
            )
            
            activeActivities[flight.id] = activity
            print("✅ Started Live Activity for flight \(flight.id)")
            
            for await pushToken in activity.pushTokenUpdates {
                let tokenString = pushToken.map { String(format: "%02x", $0) }.joined()
                print("📱 Live Activity push token: \(tokenString)")
            }
            
        } catch {
            print("❌ Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    func updateActivity(for flight: Flight) async {
        guard let activity = activeActivities[flight.id] else {
            return
        }
        
        let newState = FlightActivityAttributes.ContentState(
            status: flight.status.displayName,
            departureTime: flight.estimatedDeparture,
            arrivalTime: flight.estimatedArrival,
            currentAltitude: flight.altitude?.baroFeet,
            currentSpeed: flight.velocity?.speedKnots,
            delayMinutes: flight.delayConfidence?.estimatedDelayMinutes ?? 0
        )
        
        await activity.update(
            .init(state: newState, staleDate: nil)
        )
        
        print("✅ Updated Live Activity for flight \(flight.id)")
    }
    
    func endActivity(for flightId: String) async {
        guard let activity = activeActivities[flightId] else {
            return
        }
        
        await activity.end(
            .init(state: activity.content.state, staleDate: nil),
            dismissalPolicy: .default
        )
        
        activeActivities.removeValue(forKey: flightId)
        print("✅ Ended Live Activity for flight \(flightId)")
    }
    
    func endAllActivities() async {
        for (flightId, _) in activeActivities {
            await endActivity(for: flightId)
        }
    }
}

struct FlightActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var status: String
        var departureTime: Date?
        var arrivalTime: Date?
        var currentAltitude: Double?
        var currentSpeed: Double?
        var delayMinutes: Int
    }
    
    var flightId: String
    var callsign: String
    var route: String
}
