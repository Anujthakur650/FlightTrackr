import SwiftUI
import MapKit

struct FlightDetailView: View {
    let flight: Flight
    @EnvironmentObject var flightStore: FlightStore
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var appEnvironment: AppEnvironment
    @State private var showingShareSheet = false
    @State private var showingNotificationSettings = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                FlightHeaderView(flight: flight)
                
                if let position = flight.position {
                    FlightMapView(flight: flight)
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                }
                
                FlightTimelineView(flight: flight)
                    .padding(.horizontal)
                
                FlightStatsView(flight: flight)
                    .padding(.horizontal)
                
                if let delayConfidence = flight.delayConfidence {
                    DelayConfidenceView(confidence: delayConfidence)
                        .padding(.horizontal)
                }
                
                if let aircraft = flight.aircraft {
                    AircraftInfoView(aircraft: aircraft)
                        .padding(.horizontal)
                }
                
                QuickActionsView(
                    flight: flight,
                    onShare: { showingShareSheet = true },
                    onAddToCalendar: { addToCalendar() },
                    onNotifications: { showingNotificationSettings = true }
                )
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(flight.displayCallsign)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    toggleTracking()
                } label: {
                    Image(systemName: flightStore.isTracked(flight.id) ? "star.fill" : "star")
                        .foregroundStyle(flightStore.isTracked(flight.id) ? .yellow : .primary)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [createShareText()])
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView(flight: flight)
        }
    }
    
    private func toggleTracking() {
        if flightStore.isTracked(flight.id) {
            flightStore.untrackFlight(flight.id)
            Task {
                await appEnvironment.liveActivityManager.endActivity(for: flight.id)
                await notificationManager.unsubscribeFromFlight(flight.id)
            }
        } else {
            flightStore.trackFlight(flight.id)
            Task {
                await appEnvironment.liveActivityManager.startActivity(for: flight)
                await notificationManager.subscribeToFlight(flight, types: [.departure, .arrival, .delay])
            }
        }
    }
    
    private func createShareText() -> String {
        var text = "Flight \(flight.displayCallsign)"
        if let route = flight.route {
            text += " - \(route)"
        }
        text += "\nStatus: \(flight.status.displayName)"
        if let departure = flight.estimatedDeparture {
            text += "\nDeparture: \(departure.formatted(date: .abbreviated, time: .shortened))"
        }
        if let arrival = flight.estimatedArrival {
            text += "\nArrival: \(arrival.formatted(date: .abbreviated, time: .shortened))"
        }
        return text
    }
    
    private func addToCalendar() {
        // In a real app, this would use EventKit to add to calendar
        print("Adding flight to calendar: \(flight.displayCallsign)")
    }
}

struct FlightHeaderView: View {
    let flight: Flight
    
    var body: some View {
        VStack(spacing: 12) {
            Text(flight.displayCallsign)
                .font(.largeTitle)
                .bold()
            
            if let route = flight.route {
                Text(route)
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            StatusBadge(status: flight.status)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
}

struct FlightMapView: View {
    let flight: Flight
    @State private var region: MapCameraPosition
    
    init(flight: Flight) {
        self.flight = flight
        
        if let position = flight.position {
            let center = position.coordinate
            let region = MKCoordinateRegion(
                center: center,
                span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
            )
            _region = State(initialValue: .region(region))
        } else {
            _region = State(initialValue: .automatic)
        }
    }
    
    var body: some View {
        Map(position: $region) {
            if let position = flight.position {
                Annotation(flight.displayCallsign, coordinate: position.coordinate) {
                    ZStack {
                        Circle()
                            .fill(.blue.opacity(0.3))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "airplane")
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.blue)
                            .clipShape(Circle())
                            .rotationEffect(.degrees(flight.velocity?.heading ?? 0))
                    }
                }
            }
            
            if let departure = flight.departureAirport {
                Marker(departure.displayCode, coordinate: departure.coordinate)
                    .tint(.green)
            }
            
            if let arrival = flight.arrivalAirport {
                Marker(arrival.displayCode, coordinate: arrival.coordinate)
                    .tint(.red)
            }
        }
        .mapStyle(.standard(elevation: .realistic))
    }
}

struct FlightTimelineView: View {
    let flight: Flight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Timeline")
                .font(.headline)
            
            VStack(spacing: 12) {
                if let departure = flight.estimatedDeparture {
                    TimelineItem(
                        title: "Departure",
                        time: departure,
                        location: flight.departureAirport?.displayName ?? "Unknown",
                        icon: "airplane.departure",
                        color: .green,
                        isCompleted: flight.actualDeparture != nil
                    )
                }
                
                TimelineItem(
                    title: "En Route",
                    time: Date(),
                    location: flight.position.map { "\($0.latitude.formatted(.number.precision(.fractionLength(2)))), \($0.longitude.formatted(.number.precision(.fractionLength(2))))" } ?? "Unknown position",
                    icon: "airplane",
                    color: .blue,
                    isCompleted: flight.status == .enRoute
                )
                
                if let arrival = flight.estimatedArrival {
                    TimelineItem(
                        title: "Arrival",
                        time: arrival,
                        location: flight.arrivalAirport?.displayName ?? "Unknown",
                        icon: "airplane.arrival",
                        color: .purple,
                        isCompleted: flight.actualArrival != nil
                    )
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TimelineItem: View {
    let title: String
    let time: Date
    let location: String
    let icon: String
    let color: Color
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCompleted ? color : color.opacity(0.3))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .foregroundStyle(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .bold()
                
                Text(time.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
    }
}

struct FlightStatsView: View {
    let flight: Flight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Flight Stats")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(
                    title: "Altitude",
                    value: flight.altitude?.baroFeet.map { "\(Int($0)) ft" } ?? "N/A",
                    icon: "arrow.up"
                )
                
                StatCard(
                    title: "Speed",
                    value: flight.velocity?.speedKnots.map { "\(Int($0)) kts" } ?? "N/A",
                    icon: "speedometer"
                )
                
                StatCard(
                    title: "Heading",
                    value: flight.velocity?.heading.map { "\(Int($0))°" } ?? "N/A",
                    icon: "location.north"
                )
                
                StatCard(
                    title: "Country",
                    value: flight.originCountry,
                    icon: "globe"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.subheadline)
                .bold()
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct DelayConfidenceView: View {
    let confidence: DelayConfidence
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                
                Text("Delay Prediction")
                    .font(.headline)
            }
            
            HStack {
                Text("Confidence:")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(confidence.confidenceLevel)
                    .bold()
                Text("(\(Int(confidence.probability * 100))%)")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("Estimated Delay:")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(confidence.estimatedDelayMinutes) minutes")
                    .bold()
            }
            
            if !confidence.factors.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Factors:")
                        .foregroundStyle(.secondary)
                    
                    ForEach(confidence.factors, id: \.self) { factor in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.caption2)
                            Text(factor.displayName)
                                .font(.subheadline)
                        }
                    }
                }
            }
        }
        .padding()
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AircraftInfoView: View {
    let aircraft: Aircraft
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Aircraft")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                if let model = aircraft.model {
                    InfoRow(label: "Model", value: model)
                }
                
                if let manufacturer = aircraft.manufacturer {
                    InfoRow(label: "Manufacturer", value: manufacturer)
                }
                
                if let registration = aircraft.registration {
                    InfoRow(label: "Registration", value: registration)
                }
                
                if let operator = aircraft.operator {
                    InfoRow(label: "Operator", value: operator)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

struct QuickActionsView: View {
    let flight: Flight
    let onShare: () -> Void
    let onAddToCalendar: () -> Void
    let onNotifications: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            HStack(spacing: 12) {
                ActionButton(icon: "square.and.arrow.up", title: "Share", action: onShare)
                ActionButton(icon: "calendar.badge.plus", title: "Calendar", action: onAddToCalendar)
                ActionButton(icon: "bell", title: "Notify", action: onNotifications)
            }
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(.blue.opacity(0.1))
            .foregroundStyle(.blue)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct NotificationSettingsView: View {
    let flight: Flight
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var selectedTypes: Set<NotificationType> = [.departure, .arrival, .delay]
    
    var body: some View {
        NavigationStack {
            List {
                Section("Notification Types") {
                    ForEach(NotificationType.allCases, id: \.self) { type in
                        Toggle(type.displayName, isOn: Binding(
                            get: { selectedTypes.contains(type) },
                            set: { isOn in
                                if isOn {
                                    selectedTypes.insert(type)
                                } else {
                                    selectedTypes.remove(type)
                                }
                            }
                        ))
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        Task {
                            await notificationManager.subscribeToFlight(
                                flight,
                                types: Array(selectedTypes)
                            )
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FlightDetailView(flight: .mock())
            .environmentObject(FlightStore(client: OpenSkyClient(
                configuration: AppConfiguration.shared,
                cacheManager: CacheManager(),
                useMockData: true
            )))
            .environmentObject(NotificationManager(
                backendURL: URL(string: "http://localhost:3000/api")!,
                liveActivityManager: LiveActivityManager()
            ))
            .environmentObject(AppEnvironment.shared)
    }
}
