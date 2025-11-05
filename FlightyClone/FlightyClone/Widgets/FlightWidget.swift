import WidgetKit
import SwiftUI

struct FlightWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FlightWidgetEntry {
        FlightWidgetEntry(date: Date(), flight: .mock())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FlightWidgetEntry) -> Void) {
        let entry = FlightWidgetEntry(date: Date(), flight: .mock())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FlightWidgetEntry>) -> Void) {
        Task {
            let currentDate = Date()
            
            // In a real implementation, fetch tracked flights from shared storage
            let flight = Flight.mock()
            let entry = FlightWidgetEntry(date: currentDate, flight: flight)
            
            // Refresh every 5 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
}

struct FlightWidgetEntry: TimelineEntry {
    let date: Date
    let flight: Flight
}

struct FlightWidgetEntryView: View {
    var entry: FlightWidgetProvider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            SmallFlightWidget(flight: entry.flight)
        case .systemMedium:
            MediumFlightWidget(flight: entry.flight)
        case .systemLarge:
            LargeFlightWidget(flight: entry.flight)
        default:
            SmallFlightWidget(flight: entry.flight)
        }
    }
}

struct SmallFlightWidget: View {
    let flight: Flight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "airplane")
                    .foregroundStyle(.blue)
                Text(flight.displayCallsign)
                    .font(.headline)
            }
            
            if let route = flight.route {
                Text(route)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            HStack {
                Circle()
                    .fill(statusColor(flight.status))
                    .frame(width: 8, height: 8)
                Text(flight.status.displayName)
                    .font(.caption2)
            }
        }
        .padding()
    }
    
    private func statusColor(_ status: FlightStatus) -> Color {
        switch status {
        case .enRoute: return .green
        case .landed: return .purple
        case .cancelled: return .red
        default: return .blue
        }
    }
}

struct MediumFlightWidget: View {
    let flight: Flight
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "airplane")
                        .foregroundStyle(.blue)
                    Text(flight.displayCallsign)
                        .font(.headline)
                }
                
                if let route = flight.route {
                    Text(route)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                HStack {
                    Circle()
                        .fill(statusColor(flight.status))
                        .frame(width: 8, height: 8)
                    Text(flight.status.displayName)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                if let altitude = flight.altitude?.baroFeet {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(altitude))")
                            .font(.title3)
                            .bold()
                        Text("ft")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let speed = flight.velocity?.speedKnots {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(speed))")
                            .font(.title3)
                            .bold()
                        Text("kts")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
    }
    
    private func statusColor(_ status: FlightStatus) -> Color {
        switch status {
        case .enRoute: return .green
        case .landed: return .purple
        case .cancelled: return .red
        default: return .blue
        }
    }
}

struct LargeFlightWidget: View {
    let flight: Flight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "airplane")
                    .font(.title2)
                    .foregroundStyle(.blue)
                Text(flight.displayCallsign)
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Circle()
                    .fill(statusColor(flight.status))
                    .frame(width: 12, height: 12)
            }
            
            if let route = flight.route {
                Text(route)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
            
            HStack {
                StatView(title: "Altitude", value: altitudeString)
                Spacer()
                StatView(title: "Speed", value: speedString)
                Spacer()
                StatView(title: "Heading", value: headingString)
            }
            
            if let arrivalTime = flight.estimatedArrival {
                HStack {
                    Text("Arrives")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(arrivalTime.formatted(date: .omitted, time: .shortened))
                        .bold()
                }
            }
            
            if let delayConfidence = flight.delayConfidence,
               delayConfidence.probability > 0.5 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("Possible delay: \(delayConfidence.estimatedDelayMinutes) min")
                        .font(.caption)
                }
            }
        }
        .padding()
    }
    
    private var altitudeString: String {
        if let altitude = flight.altitude?.baroFeet {
            return "\(Int(altitude)) ft"
        }
        return "N/A"
    }
    
    private var speedString: String {
        if let speed = flight.velocity?.speedKnots {
            return "\(Int(speed)) kts"
        }
        return "N/A"
    }
    
    private var headingString: String {
        if let heading = flight.velocity?.heading {
            return "\(Int(heading))°"
        }
        return "N/A"
    }
    
    private func statusColor(_ status: FlightStatus) -> Color {
        switch status {
        case .enRoute: return .green
        case .landed: return .purple
        case .cancelled: return .red
        default: return .blue
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .bold()
        }
    }
}

@main
struct FlightWidget: Widget {
    let kind: String = "FlightWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FlightWidgetProvider()) { entry in
            FlightWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Flight Tracker")
        .description("Track your flights at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    FlightWidget()
} timeline: {
    FlightWidgetEntry(date: .now, flight: .mock())
}

#Preview(as: .systemMedium) {
    FlightWidget()
} timeline: {
    FlightWidgetEntry(date: .now, flight: .mock())
}

#Preview(as: .systemLarge) {
    FlightWidget()
} timeline: {
    FlightWidgetEntry(date: .now, flight: .mock())
}
