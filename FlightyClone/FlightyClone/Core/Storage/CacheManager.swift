import Foundation

actor CacheManager {
    private var cache: [String: CacheEntry] = [:]
    private let defaultTTL: TimeInterval
    
    struct CacheEntry {
        let data: Data
        let expiresAt: Date
    }
    
    init(defaultTTL: TimeInterval = 300) {
        self.defaultTTL = defaultTTL
    }
    
    func store<T: Encodable>(_ value: T, key: String, ttl: TimeInterval? = nil) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(value)
            let expiresAt = Date().addingTimeInterval(ttl ?? defaultTTL)
            cache[key] = CacheEntry(data: data, expiresAt: expiresAt)
        } catch {
            print("❌ Failed to cache value for key \(key): \(error)")
        }
    }
    
    func retrieve<T: Decodable>(key: String) -> T? {
        guard let entry = cache[key] else {
            return nil
        }
        
        if Date() > entry.expiresAt {
            cache.removeValue(forKey: key)
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: entry.data)
        } catch {
            print("❌ Failed to decode cached value for key \(key): \(error)")
            cache.removeValue(forKey: key)
            return nil
        }
    }
    
    func invalidate(key: String) {
        cache.removeValue(forKey: key)
    }
    
    func invalidateAll() {
        cache.removeAll()
    }
    
    func clearExpired() {
        let now = Date()
        cache = cache.filter { $0.value.expiresAt > now }
    }
}
