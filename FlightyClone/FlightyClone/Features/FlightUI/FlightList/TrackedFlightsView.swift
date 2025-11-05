import SwiftUI

struct TrackedFlightsView: View {
    @EnvironmentObject var flightStore: FlightStore
    
    var trackedFlights: [Flight] {
        flightStore.getTrackedFlights()
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if trackedFlights.isEmpty {
                    ContentUnavailableView(
                        "No Tracked Flights",
                        systemImage: "star",
                        description: Text("Tap the star icon on any flight to track it here")
                    )
                } else {
                    List {
                        ForEach(trackedFlights) { flight in
                            NavigationLink(destination: FlightDetailView(flight: flight)) {
                                TrackedFlightRow(flight: flight)
                            }
                        }
                    }
                    .refreshable {
                        await flightStore.refreshFlights()
                    }
                }
            }
            .navigationTitle("Tracked Flights")
        }
        .task {
            if flightStore.flights.isEmpty {
                await flightStore.refreshFlights()
            }
        }
    }
}

struct TrackedFlightRow: View {
    let flight: Flight
    @EnvironmentObject var appEnvironment: AppEnvironment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(flight.displayCallsign)
                    .font(.headline)
                
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(.yellow)
                
                Spacer()
                
                StatusBadge(status: flight.status)
            }
            
            if let route = flight.route {
                Text(route)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                if let departure = flight.estimatedDeparture {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Departure")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(departure.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                if let arrival = flight.estimatedArrival {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Arrival")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(arrival.formatted(date: .omitted, time: .shortened))
                            .font(.caption)
                    }
                }
            }
            
            if let delayConfidence = flight.delayConfidence,
               delayConfidence.probability > 0.5 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Potential delay: \(delayConfidence.estimatedDelayMinutes) min")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            
            if appEnvironment.liveActivityManager.activeActivities[flight.id] != nil {
                HStack {
                    Image(systemName: "circle.fill")
                        .font(.caption2)
                        .foregroundStyle(.green)
                    Text("Live Activity Active")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let store = FlightStore(client: OpenSkyClient(
        configuration: AppConfiguration.shared,
        cacheManager: CacheManager(),
        useMockData: true
    ))
    store.trackFlight("test-flight-1")
    
    return TrackedFlightsView()
        .environmentObject(store)
        .environmentObject(AppEnvironment.shared)
}
