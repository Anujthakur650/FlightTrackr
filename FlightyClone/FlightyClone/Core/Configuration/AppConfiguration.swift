import Foundation

struct AppConfiguration {
    static let shared = AppConfiguration()
    
    let openSkyBaseURL: URL
    let backendURL: URL
    let requestTimeout: TimeInterval
    let maxRetryAttempts: Int
    let cacheTTL: TimeInterval
    let appGroupIdentifier: String
    
    private init() {
        self.openSkyBaseURL = URL(string: "https://opensky-network.org/api")!
        
        if let backendURLString = ProcessInfo.processInfo.environment["BACKEND_URL"],
           let url = URL(string: backendURLString) {
            self.backendURL = url
        } else {
            self.backendURL = URL(string: "http://localhost:3000/api")!
        }
        
        self.requestTimeout = 30.0
        self.maxRetryAttempts = 3
        self.cacheTTL = 300.0 // 5 minutes
        self.appGroupIdentifier = "group.com.flightyclone.shared"
    }
}

enum AppConstants {
    static let openSkyAttribution = "Data provided by OpenSky Network"
    static let openSkyTOSURL = URL(string: "https://opensky-network.org/about/terms-of-use")!
    
    enum RateLimit {
        static let anonymousRequestsPerInterval = 10
        static let anonymousIntervalSeconds = 10.0
        static let authenticatedRequestsPerHour = 400
    }
    
    enum Cache {
        static let flightStatesTTL: TimeInterval = 300 // 5 minutes
        static let flightDetailTTL: TimeInterval = 600 // 10 minutes
        static let airportInfoTTL: TimeInterval = 86400 // 24 hours
    }
}
