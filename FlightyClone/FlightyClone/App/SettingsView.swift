import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Notifications") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(notificationManager.isAuthorized ? "Enabled" : "Disabled")
                            .foregroundStyle(.secondary)
                    }
                    
                    if !notificationManager.isAuthorized {
                        Button("Enable Notifications") {
                            Task {
                                let granted = await appEnvironment.requestNotificationPermissions()
                                if granted {
                                    appEnvironment.registerForPushNotifications()
                                }
                            }
                        }
                    }
                }
                
                Section("Data") {
                    Button("Clear Cache") {
                        Task {
                            await appEnvironment.cacheManager.invalidateAll()
                        }
                    }
                    
                    Button("Refresh All Flights") {
                        Task {
                            await appEnvironment.flightStore.refreshFlights()
                        }
                    }
                }
                
                Section("About") {
                    Button("OpenSky Network Terms of Service") {
                        if let url = AppConstants.openSkyTOSURL {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    Button("About FlightyClone") {
                        showingAbout = true
                    }
                    
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section {
                    Text(AppConstants.openSkyAttribution)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "airplane.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                    
                    Text("FlightyClone")
                        .font(.title)
                        .bold()
                    
                    Text("Version 1.0.0")
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("A flight tracking app powered by OpenSky Network")
                            .multilineTextAlignment(.center)
                        
                        Text("Features")
                            .font(.headline)
                        
                        FeatureRow(icon: "airplane", text: "Real-time flight tracking")
                        FeatureRow(icon: "bell.fill", text: "Push notifications")
                        FeatureRow(icon: "map", text: "Interactive flight maps")
                        FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Delay predictions")
                        FeatureRow(icon: "calendar", text: "Calendar integration")
                        FeatureRow(icon: "square.and.arrow.up", text: "Easy sharing")
                        
                        Text("Data Source")
                            .font(.headline)
                            .padding(.top)
                        
                        Text(AppConstants.openSkyAttribution)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("The OpenSky Network is a non-profit association that provides open air traffic data for research and non-commercial purposes.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppEnvironment.shared)
        .environmentObject(AppEnvironment.shared.notificationManager)
}
