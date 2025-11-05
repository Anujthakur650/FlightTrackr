import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            FlightListView()
                .tabItem {
                    Label("Flights", systemImage: "airplane")
                }
                .tag(0)
            
            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            TrackedFlightsView()
                .tabItem {
                    Label("Tracked", systemImage: "star.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .task {
            await requestPermissions()
        }
    }
    
    private func requestPermissions() async {
        let granted = await appEnvironment.requestNotificationPermissions()
        if granted {
            appEnvironment.registerForPushNotifications()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppEnvironment.shared)
        .environmentObject(AppEnvironment.shared.flightStore)
        .environmentObject(AppEnvironment.shared.notificationManager)
}
