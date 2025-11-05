import SwiftUI

struct SearchView: View {
    @EnvironmentObject var flightStore: FlightStore
    @State private var searchText = ""
    @State private var searchScope: SearchScope = .flights
    
    enum SearchScope: String, CaseIterable {
        case flights = "Flights"
        case airports = "Airports"
    }
    
    var searchResults: [SearchResult] {
        if searchText.isEmpty {
            return []
        }
        
        switch searchScope {
        case .flights:
            return flightStore.searchFlights(query: searchText)
                .map { .flight($0) }
        case .airports:
            return AirportDatabase.search(query: searchText)
                .map { .airport($0) }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if searchResults.isEmpty && !searchText.isEmpty {
                    ContentUnavailableView.search
                } else {
                    ForEach(searchResults) { result in
                        switch result {
                        case .flight(let flight):
                            NavigationLink(destination: FlightDetailView(flight: flight)) {
                                FlightRowView(flight: flight)
                            }
                        case .airport(let airport):
                            NavigationLink(destination: AirportDetailView(airport: airport)) {
                                AirportRowView(airport: airport)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Search")
            .searchable(text: $searchText, prompt: "Search flights or airports")
            .searchScopes($searchScope) {
                ForEach(SearchScope.allCases, id: \.self) { scope in
                    Text(scope.rawValue)
                }
            }
        }
    }
}

enum SearchResult: Identifiable {
    case flight(Flight)
    case airport(Airport)
    
    var id: String {
        switch self {
        case .flight(let flight):
            return "flight_\(flight.id)"
        case .airport(let airport):
            return "airport_\(airport.id)"
        }
    }
}

struct AirportRowView: View {
    let airport: Airport
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(airport.displayCode)
                    .font(.headline)
                    .foregroundStyle(.blue)
                
                Text(airport.name)
                    .font(.subheadline)
            }
            
            Text(airport.location)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct AirportDetailView: View {
    let airport: Airport
    @State private var region: MapCameraPosition
    
    init(airport: Airport) {
        self.airport = airport
        let region = MKCoordinateRegion(
            center: airport.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )
        _region = State(initialValue: .region(region))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Map(position: $region) {
                    Marker(airport.displayCode, coordinate: airport.coordinate)
                        .tint(.blue)
                }
                .frame(height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Airport Information")
                        .font(.headline)
                    
                    InfoRow(label: "ICAO", value: airport.icao)
                    
                    if let iata = airport.iata {
                        InfoRow(label: "IATA", value: iata)
                    }
                    
                    InfoRow(label: "Name", value: airport.name)
                    InfoRow(label: "City", value: airport.city)
                    InfoRow(label: "Country", value: airport.country)
                    InfoRow(label: "Elevation", value: "\(Int(airport.altitude)) m")
                    InfoRow(label: "Timezone", value: airport.timezone)
                    
                    InfoRow(
                        label: "Coordinates",
                        value: "\(airport.latitude.formatted(.number.precision(.fractionLength(4)))), \(airport.longitude.formatted(.number.precision(.fractionLength(4))))"
                    )
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle(airport.displayCode)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SearchView()
        .environmentObject(FlightStore(client: OpenSkyClient(
            configuration: AppConfiguration.shared,
            cacheManager: CacheManager(),
            useMockData: true
        )))
}
