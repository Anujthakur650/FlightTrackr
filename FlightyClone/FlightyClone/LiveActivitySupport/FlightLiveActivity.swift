import ActivityKit
import WidgetKit
import SwiftUI

struct FlightLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FlightActivityAttributes.self) { context in
            // Lock screen / banner UI
            FlightLiveActivityView(context: context)
                .activityBackgroundTint(.black.opacity(0.25))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: "airplane")
                            .foregroundStyle(.blue)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(context.attributes.callsign)
                                .font(.caption)
                                .bold()
                            Text(context.attributes.route)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 4) {
                        if let altitude = context.state.currentAltitude {
                            Text("\(Int(altitude)) ft")
                                .font(.caption)
                        }
                        if let speed = context.state.currentSpeed {
                            Text("\(Int(speed)) kts")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 8) {
                        HStack {
                            if let departure = context.state.departureTime {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Departure")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(departure.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                }
                            }
                            
                            Spacer()
                            
                            if let arrival = context.state.arrivalTime {
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("Arrival")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text(arrival.formatted(date: .omitted, time: .shortened))
                                        .font(.caption)
                                }
                            }
                        }
                        
                        // Flight progress bar
                        if let departure = context.state.departureTime,
                           let arrival = context.state.arrivalTime {
                            let progress = calculateProgress(
                                departure: departure,
                                arrival: arrival
                            )
                            
                            ProgressView(value: progress)
                                .tint(.blue)
                        }
                        
                        Text(context.state.status)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if context.state.delayMinutes > 0 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Delay: \(context.state.delayMinutes) min")
                            }
                            .font(.caption2)
                            .foregroundStyle(.orange)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    // Additional content if needed
                }
            } compactLeading: {
                Image(systemName: "airplane")
                    .foregroundStyle(.blue)
            } compactTrailing: {
                if let altitude = context.state.currentAltitude {
                    Text("\(Int(altitude / 1000))k")
                        .font(.caption2)
                }
            } minimal: {
                Image(systemName: "airplane")
                    .foregroundStyle(.blue)
            }
        }
    }
    
    private func calculateProgress(departure: Date, arrival: Date) -> Double {
        let now = Date()
        let totalDuration = arrival.timeIntervalSince(departure)
        let elapsed = now.timeIntervalSince(departure)
        return min(max(elapsed / totalDuration, 0), 1)
    }
}

struct FlightLiveActivityView: View {
    let context: ActivityViewContext<FlightActivityAttributes>
    
    var body: some View {
        HStack(spacing: 12) {
            // Left side - Flight info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "airplane")
                        .foregroundStyle(.blue)
                    Text(context.attributes.callsign)
                        .font(.headline)
                }
                
                Text(context.attributes.route)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(context.state.status)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.blue.opacity(0.2))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            // Right side - Stats
            VStack(alignment: .trailing, spacing: 4) {
                if let altitude = context.state.currentAltitude {
                    HStack(spacing: 4) {
                        Text("\(Int(altitude))")
                            .font(.title3)
                            .bold()
                        Text("ft")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let speed = context.state.currentSpeed {
                    HStack(spacing: 4) {
                        Text("\(Int(speed))")
                            .font(.subheadline)
                            .bold()
                        Text("kts")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if context.state.delayMinutes > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text("+\(context.state.delayMinutes)m")
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
        .padding()
    }
}

#Preview("Notification", as: .content, using: FlightActivityAttributes(
    flightId: "1",
    callsign: "UAL123",
    route: "SFO → JFK"
)) {
    FlightLiveActivity()
} contentStates: {
    FlightActivityAttributes.ContentState(
        status: "En Route",
        departureTime: Date().addingTimeInterval(-3600),
        arrivalTime: Date().addingTimeInterval(14400),
        currentAltitude: 35000,
        currentSpeed: 450,
        delayMinutes: 0
    )
}
