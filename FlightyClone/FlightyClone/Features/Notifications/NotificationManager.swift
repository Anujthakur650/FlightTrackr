import Foundation
import UserNotifications

@MainActor
class NotificationManager: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var deviceToken: String?
    
    private let backendURL: URL
    private let liveActivityManager: LiveActivityManager
    
    init(backendURL: URL, liveActivityManager: LiveActivityManager) {
        self.backendURL = backendURL
        self.liveActivityManager = liveActivityManager
        super.init()
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound, .criticalAlert]
            )
            isAuthorized = granted
            return granted
        } catch {
            print("❌ Failed to request notification authorization: \(error)")
            return false
        }
    }
    
    func registerDevice(token: String) async {
        deviceToken = token
        
        guard let url = URL(string: backendURL.absoluteString + "/register-device") else {
            print("❌ Invalid backend URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "deviceToken": token,
            "platform": "iOS"
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Device registered successfully")
            } else {
                print("⚠️ Device registration returned non-200 status")
            }
        } catch {
            print("❌ Failed to register device: \(error.localizedDescription)")
        }
    }
    
    func subscribeToFlight(_ flight: Flight, types: [NotificationType]) async {
        guard let token = deviceToken else {
            print("⚠️ No device token available")
            return
        }
        
        guard let url = URL(string: backendURL.absoluteString + "/subscribe") else {
            print("❌ Invalid backend URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "deviceToken": token,
            "flightId": flight.id,
            "icao24": flight.icao24,
            "callsign": flight.callsign ?? "",
            "notificationTypes": types.map { $0.rawValue }
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Subscribed to flight notifications")
                scheduleLocalNotifications(for: flight, types: types)
            }
        } catch {
            print("❌ Failed to subscribe to flight: \(error.localizedDescription)")
        }
    }
    
    func unsubscribeFromFlight(_ flightId: String) async {
        guard let token = deviceToken else { return }
        
        guard let url = URL(string: backendURL.absoluteString + "/unsubscribe") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "deviceToken": token,
            "flightId": flightId
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("✅ Unsubscribed from flight notifications")
                cancelLocalNotifications(for: flightId)
            }
        } catch {
            print("❌ Failed to unsubscribe from flight: \(error.localizedDescription)")
        }
    }
    
    func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        guard let flightId = userInfo["flightId"] as? String else {
            return
        }
        
        switch response.actionIdentifier {
        case "TRACK_FLIGHT":
            print("User wants to track flight: \(flightId)")
            
        case "VIEW_DETAILS":
            print("User wants to view flight details: \(flightId)")
            
        case UNNotificationDefaultActionIdentifier:
            print("User tapped notification for flight: \(flightId)")
            
        default:
            break
        }
    }
    
    private func scheduleLocalNotifications(for flight: Flight, types: [NotificationType]) {
        for type in types {
            let content = UNMutableNotificationContent()
            content.title = notificationTitle(for: type, flight: flight)
            content.body = notificationBody(for: type, flight: flight)
            content.sound = .default
            content.categoryIdentifier = "FLIGHT_UPDATE"
            content.userInfo = [
                "flightId": flight.id,
                "type": type.rawValue
            ]
            
            if let triggerDate = estimatedNotificationTime(for: type, flight: flight) {
                let components = Calendar.current.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: triggerDate
                )
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
                
                let identifier = "\(flight.id)_\(type.rawValue)"
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("❌ Failed to schedule notification: \(error)")
                    }
                }
            }
        }
    }
    
    private func cancelLocalNotifications(for flightId: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let identifiers = requests
                .filter { $0.identifier.starts(with: flightId) }
                .map { $0.identifier }
            
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
        }
    }
    
    private func notificationTitle(for type: NotificationType, flight: Flight) -> String {
        let callsign = flight.displayCallsign
        
        switch type {
        case .departure:
            return "\(callsign) Departing Soon"
        case .arrival:
            return "\(callsign) Arriving Soon"
        case .delay:
            return "\(callsign) Delayed"
        case .gate:
            return "\(callsign) Gate Change"
        case .boarding:
            return "\(callsign) Now Boarding"
        case .status:
            return "\(callsign) Status Update"
        }
    }
    
    private func notificationBody(for type: NotificationType, flight: Flight) -> String {
        switch type {
        case .departure:
            if let airport = flight.departureAirport {
                return "Departing from \(airport.displayCode) in 30 minutes"
            }
            return "Departing in 30 minutes"
            
        case .arrival:
            if let airport = flight.arrivalAirport {
                return "Arriving at \(airport.displayCode) in 30 minutes"
            }
            return "Arriving in 30 minutes"
            
        case .delay:
            if let confidence = flight.delayConfidence {
                return "Potential delay of \(confidence.estimatedDelayMinutes) minutes (\(confidence.confidenceLevel) confidence)"
            }
            return "Flight may be delayed"
            
        case .gate:
            return "Gate information updated"
            
        case .boarding:
            return "Boarding has started"
            
        case .status:
            return "Flight status: \(flight.status.displayName)"
        }
    }
    
    private func estimatedNotificationTime(for type: NotificationType, flight: Flight) -> Date? {
        switch type {
        case .departure:
            return flight.estimatedDeparture?.addingTimeInterval(-1800) // 30 min before
        case .arrival:
            return flight.estimatedArrival?.addingTimeInterval(-1800)
        case .boarding:
            return flight.estimatedDeparture?.addingTimeInterval(-2700) // 45 min before
        default:
            return nil
        }
    }
}

enum NotificationType: String, CaseIterable, Codable {
    case departure
    case arrival
    case delay
    case gate
    case boarding
    case status
    
    var displayName: String {
        switch self {
        case .departure: return "Departure"
        case .arrival: return "Arrival"
        case .delay: return "Delays"
        case .gate: return "Gate Changes"
        case .boarding: return "Boarding"
        case .status: return "Status Updates"
        }
    }
}
