import SwiftUI

struct FlightListView: View {
    @EnvironmentObject var flightStore: FlightStore
    @State private var searchText = ""
    
    var filteredFlights: [Flight] {
        if searchText.isEmpty {
            return flightStore.flights
        } else {
            return flightStore.searchFlights(query: searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if flightStore.isLoading && flightStore.flights.isEmpty {
                    ProgressView("Loading flights...")
                } else if let error = flightStore.error {
                    ErrorView(error: error) {
                        Task {
                            await flightStore.refreshFlights()
                        }
                    }
                } else if flightStore.flights.isEmpty {
                    ContentUnavailableView(
                        "No Flights Available",
                        systemImage: "airplane.departure",
                        description: Text("Pull to refresh or check your connection")
                    )
                } else {
                    List {
                        ForEach(filteredFlights.prefix(100)) { flight in
                            NavigationLink(destination: FlightDetailView(flight: flight)) {
                                FlightRowView(flight: flight)
                            }
                        }
                    }
                    .refreshable {
                        await flightStore.refreshFlights()
                    }
                }
            }
            .navigationTitle("Flights")
            .searchable(text: $searchText, prompt: "Search flights, airports...")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await flightStore.refreshFlights()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(flightStore.isLoading)
                }
            }
        }
        .task {
            if flightStore.flights.isEmpty {
                await flightStore.refreshFlights()
            }
            flightStore.startAutoRefresh()
        }
        .onDisappear {
            flightStore.stopAutoRefresh()
        }
    }
}

struct FlightRowView: View {
    let flight: Flight
    @EnvironmentObject var flightStore: FlightStore
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(flight.displayCallsign)
                        .font(.headline)
                    
                    if flightStore.isTracked(flight.id) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                    }
                }
                
                if let route = flight.route {
                    Text(route)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                HStack {
                    StatusBadge(status: flight.status)
                    
                    if let delayConfidence = flight.delayConfidence,
                       delayConfidence.probability > 0.5 {
                        DelayIndicator(confidence: delayConfidence)
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if let altitude = flight.altitude?.baroFeet {
                    Text("\(Int(altitude)) ft")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let speed = flight.velocity?.speedKnots {
                    Text("\(Int(speed)) kts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if flight.position?.onGround == true {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct StatusBadge: View {
    let status: FlightStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch status.color {
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "red": return .red
        default: return .gray
        }
    }
}

struct DelayIndicator: View {
    let confidence: DelayConfidence
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("+\(confidence.estimatedDelayMinutes)m")
        }
        .font(.caption)
        .foregroundStyle(.orange)
    }
}

struct ErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            
            Text("Error Loading Flights")
                .font(.headline)
            
            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview("Flight List") {
    let store = FlightStore(client: OpenSkyClient(
        configuration: AppConfiguration.shared,
        cacheManager: CacheManager(),
        useMockData: true
    ))
    
    return NavigationStack {
        FlightListView()
            .environmentObject(store)
    }
}

#Preview("Flight Row") {
    FlightRowView(flight: .mock())
        .environmentObject(FlightStore(client: OpenSkyClient(
            configuration: AppConfiguration.shared,
            cacheManager: CacheManager(),
            useMockData: true
        )))
        .padding()
}
