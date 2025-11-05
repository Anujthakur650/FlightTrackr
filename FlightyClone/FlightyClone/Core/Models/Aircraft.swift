import Foundation

struct Aircraft: Identifiable, Codable, Hashable {
    let id: String
    let icao24: String
    let registration: String?
    let model: String?
    let manufacturer: String?
    let operator: String?
    let serialNumber: String?
    let typecode: String?
    
    var displayName: String {
        if let model = model {
            return model
        } else if let typecode = typecode {
            return typecode
        } else {
            return registration ?? icao24.uppercased()
        }
    }
    
    var displayManufacturer: String? {
        manufacturer
    }
    
    var displayOperator: String? {
        `operator`
    }
    
    var fullDescription: String {
        var parts: [String] = []
        
        if let manufacturer = manufacturer, let model = model {
            parts.append("\(manufacturer) \(model)")
        } else if let model = model {
            parts.append(model)
        }
        
        if let registration = registration {
            parts.append("(\(registration))")
        }
        
        return parts.isEmpty ? icao24.uppercased() : parts.joined(separator: " ")
    }
}

extension Aircraft {
    static func mock(
        icao24: String = "a12345",
        registration: String = "N12345",
        model: String = "Boeing 737-800"
    ) -> Aircraft {
        Aircraft(
            id: icao24,
            icao24: icao24,
            registration: registration,
            model: model,
            manufacturer: "Boeing",
            operator: "United Airlines",
            serialNumber: "12345",
            typecode: "B738"
        )
    }
}

struct AircraftDatabase {
    private static let typeCodeMap: [String: String] = [
        "A320": "Airbus A320",
        "A321": "Airbus A321",
        "A319": "Airbus A319",
        "A388": "Airbus A380-800",
        "A350": "Airbus A350",
        "B737": "Boeing 737",
        "B738": "Boeing 737-800",
        "B739": "Boeing 737-900",
        "B77W": "Boeing 777-300ER",
        "B788": "Boeing 787-8",
        "B789": "Boeing 787-9",
        "B78X": "Boeing 787-10",
        "E170": "Embraer E170",
        "E190": "Embraer E190",
        "CRJ9": "Bombardier CRJ-900",
        "DH8D": "Bombardier Dash 8 Q400",
    ]
    
    static func modelFromTypeCode(_ typecode: String) -> String? {
        typeCodeMap[typecode.uppercased()]
    }
    
    static func manufacturerFromTypeCode(_ typecode: String) -> String? {
        let code = typecode.uppercased()
        if code.starts(with: "A") {
            return "Airbus"
        } else if code.starts(with: "B") {
            return "Boeing"
        } else if code.starts(with: "E") {
            return "Embraer"
        } else if code.starts(with: "CRJ") || code.starts(with: "DH") {
            return "Bombardier"
        }
        return nil
    }
}
