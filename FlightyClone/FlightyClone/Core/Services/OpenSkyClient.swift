import Foundation

actor OpenSkyClient {
    private let configuration: AppConfiguration
    private let session: URLSession
    private let cacheManager: CacheManager
    private let useMockData: Bool
    
    private var lastRequestTime: Date?
    private let rateLimitDelay: TimeInterval = 1.0
    
    init(
        configuration: AppConfiguration,
        cacheManager: CacheManager,
        useMockData: Bool = false
    ) {
        self.configuration = configuration
        self.cacheManager = cacheManager
        self.useMockData = useMockData
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = configuration.requestTimeout
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        self.session = URLSession(configuration: config)
    }
    
    enum OpenSkyError: LocalizedError {
        case invalidURL
        case invalidResponse
        case httpError(statusCode: Int)
        case decodingError(Error)
        case rateLimitExceeded
        case networkError(Error)
        case noData
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .invalidResponse:
                return "Invalid response from server"
            case .httpError(let code):
                return "HTTP error: \(code)"
            case .decodingError(let error):
                return "Failed to decode response: \(error.localizedDescription)"
            case .rateLimitExceeded:
                return "Rate limit exceeded. Please try again later."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .noData:
                return "No data received from server"
            }
        }
    }
    
    func fetchAllFlightStates() async throws -> [OpenSkyStateVector] {
        if useMockData {
            return try await loadMockStates()
        }
        
        if let cached: OpenSkyResponse = cacheManager.retrieve(key: "all_states") {
            return cached.states
        }
        
        let endpoint = "/states/all"
        let response: OpenSkyResponse = try await request(endpoint: endpoint)
        
        cacheManager.store(response, key: "all_states", ttl: AppConstants.Cache.flightStatesTTL)
        
        return response.states
    }
    
    func fetchFlightsByAircraft(icao24: String) async throws -> [OpenSkyFlight] {
        if useMockData {
            return try await loadMockFlights()
        }
        
        let cacheKey = "flights_\(icao24)"
        if let cached: OpenSkyFlightsResponse = cacheManager.retrieve(key: cacheKey) {
            return cached.flights
        }
        
        let now = Date()
        let begin = Int(now.addingTimeInterval(-86400).timeIntervalSince1970)
        let end = Int(now.timeIntervalSince1970)
        
        let endpoint = "/flights/aircraft?icao24=\(icao24)&begin=\(begin)&end=\(end)"
        let flights: [OpenSkyFlight] = try await request(endpoint: endpoint)
        
        let response = OpenSkyFlightsResponse(flights: flights)
        cacheManager.store(response, key: cacheKey, ttl: AppConstants.Cache.flightDetailTTL)
        
        return flights
    }
    
    func fetchArrivalsByAirport(icao: String, begin: Date, end: Date) async throws -> [OpenSkyFlight] {
        if useMockData {
            return try await loadMockFlights()
        }
        
        let beginTimestamp = Int(begin.timeIntervalSince1970)
        let endTimestamp = Int(end.timeIntervalSince1970)
        
        let endpoint = "/flights/arrival?airport=\(icao)&begin=\(beginTimestamp)&end=\(endTimestamp)"
        let flights: [OpenSkyFlight] = try await request(endpoint: endpoint)
        
        return flights
    }
    
    func fetchDeparturesByAirport(icao: String, begin: Date, end: Date) async throws -> [OpenSkyFlight] {
        if useMockData {
            return try await loadMockFlights()
        }
        
        let beginTimestamp = Int(begin.timeIntervalSince1970)
        let endTimestamp = Int(end.timeIntervalSince1970)
        
        let endpoint = "/flights/departure?airport=\(icao)&begin=\(beginTimestamp)&end=\(endTimestamp)"
        let flights: [OpenSkyFlight] = try await request(endpoint: endpoint)
        
        return flights
    }
    
    private func request<T: Decodable>(endpoint: String, retryCount: Int = 0) async throws -> T {
        try await enforceRateLimit()
        
        guard let url = URL(string: configuration.openSkyBaseURL.absoluteString + endpoint) else {
            throw OpenSkyError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw OpenSkyError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                do {
                    let result = try decoder.decode(T.self, from: data)
                    return result
                } catch {
                    throw OpenSkyError.decodingError(error)
                }
                
            case 429:
                if retryCount < configuration.maxRetryAttempts {
                    let delay = exponentialBackoff(attempt: retryCount)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await request(endpoint: endpoint, retryCount: retryCount + 1)
                } else {
                    throw OpenSkyError.rateLimitExceeded
                }
                
            case 500...599:
                if retryCount < configuration.maxRetryAttempts {
                    let delay = exponentialBackoff(attempt: retryCount)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await request(endpoint: endpoint, retryCount: retryCount + 1)
                } else {
                    throw OpenSkyError.httpError(statusCode: httpResponse.statusCode)
                }
                
            default:
                throw OpenSkyError.httpError(statusCode: httpResponse.statusCode)
            }
            
        } catch let error as OpenSkyError {
            throw error
        } catch {
            if retryCount < configuration.maxRetryAttempts {
                let delay = exponentialBackoff(attempt: retryCount)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await request(endpoint: endpoint, retryCount: retryCount + 1)
            } else {
                throw OpenSkyError.networkError(error)
            }
        }
    }
    
    private func enforceRateLimit() async throws {
        if let lastRequest = lastRequestTime {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequest)
            if timeSinceLastRequest < rateLimitDelay {
                let sleepTime = rateLimitDelay - timeSinceLastRequest
                try await Task.sleep(nanoseconds: UInt64(sleepTime * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
    }
    
    private func exponentialBackoff(attempt: Int) -> TimeInterval {
        let baseDelay = 1.0
        let maxDelay = 32.0
        let delay = min(baseDelay * pow(2.0, Double(attempt)), maxDelay)
        let jitter = Double.random(in: 0...0.3) * delay
        return delay + jitter
    }
    
    private func loadMockStates() async throws -> [OpenSkyStateVector] {
        guard let mockData = MockData.openSkyStatesResponse else {
            throw OpenSkyError.noData
        }
        return mockData.states
    }
    
    private func loadMockFlights() async throws -> [OpenSkyFlight] {
        guard let mockFlights = MockData.openSkyFlights else {
            throw OpenSkyError.noData
        }
        return mockFlights
    }
}

struct OpenSkyResponse: Codable {
    let time: Int
    let states: [OpenSkyStateVector]
}

struct OpenSkyFlightsResponse: Codable {
    let flights: [OpenSkyFlight]
}

struct OpenSkyStateVector: Codable {
    let icao24: String
    let callsign: String?
    let originCountry: String
    let timePosition: Int?
    let lastContact: Int
    let longitude: Double?
    let latitude: Double?
    let baroAltitude: Double?
    let onGround: Bool
    let velocity: Double?
    let trueTrack: Double?
    let verticalRate: Double?
    let sensors: [Int]?
    let geoAltitude: Double?
    let squawk: String?
    let spi: Bool
    let positionSource: Int
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        
        icao24 = try container.decode(String.self)
        callsign = try container.decodeIfPresent(String.self)
        originCountry = try container.decode(String.self)
        timePosition = try container.decodeIfPresent(Int.self)
        lastContact = try container.decode(Int.self)
        longitude = try container.decodeIfPresent(Double.self)
        latitude = try container.decodeIfPresent(Double.self)
        baroAltitude = try container.decodeIfPresent(Double.self)
        onGround = try container.decode(Bool.self)
        velocity = try container.decodeIfPresent(Double.self)
        trueTrack = try container.decodeIfPresent(Double.self)
        verticalRate = try container.decodeIfPresent(Double.self)
        sensors = try container.decodeIfPresent([Int].self)
        geoAltitude = try container.decodeIfPresent(Double.self)
        squawk = try container.decodeIfPresent(String.self)
        spi = try container.decode(Bool.self)
        positionSource = try container.decode(Int.self)
    }
}

struct OpenSkyFlight: Codable {
    let icao24: String
    let firstSeen: Int
    let estDepartureAirport: String?
    let lastSeen: Int
    let estArrivalAirport: String?
    let callsign: String?
    let estDepartureAirportHorizDistance: Int?
    let estDepartureAirportVertDistance: Int?
    let estArrivalAirportHorizDistance: Int?
    let estArrivalAirportVertDistance: Int?
    let departureAirportCandidatesCount: Int?
    let arrivalAirportCandidatesCount: Int?
}
