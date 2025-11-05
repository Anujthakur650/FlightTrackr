import Foundation
import SwiftUI

@MainActor
class AppEnvironment: ObservableObject {
    static let shared = AppEnvironment()
    
    enum Configuration {
        case production
        case mock
        
        var useMockData: Bool {
            switch self {
            case .production:
                return ProcessInfo.processInfo.environment["USE_MOCK_DATA"] == "1"
            case .mock:
                return true
            }
        }
    }
    
    let configuration: Configuration
    let openSkyClient: OpenSkyClient
    let flightStore: FlightStore
    let notificationManager: NotificationManager
    let liveActivityManager: LiveActivityManager
    let cacheManager: CacheManager
    
    private init(configuration: Configuration = .production) {
        self.configuration = configuration
        
        let config = AppConfiguration.shared
        self.cacheManager = CacheManager()
        self.openSkyClient = OpenSkyClient(
            configuration: config,
            cacheManager: cacheManager,
            useMockData: configuration.useMockData
        )
        
        self.flightStore = FlightStore(client: openSkyClient)
        self.liveActivityManager = LiveActivityManager()
        self.notificationManager = NotificationManager(
            backendURL: config.backendURL,
            liveActivityManager: liveActivityManager
        )
    }
    
    func requestNotificationPermissions() async -> Bool {
        await notificationManager.requestAuthorization()
    }
    
    func registerForPushNotifications() {
        Task { @MainActor in
            await UIApplication.shared.registerForRemoteNotifications()
        }
    }
}
