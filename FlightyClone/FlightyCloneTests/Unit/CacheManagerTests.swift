import XCTest
@testable import FlightyClone

final class CacheManagerTests: XCTestCase {
    var cacheManager: CacheManager!
    
    override func setUp() async throws {
        cacheManager = CacheManager(defaultTTL: 5.0)
    }
    
    override func tearDown() async throws {
        await cacheManager.invalidateAll()
        cacheManager = nil
    }
    
    func testStoreAndRetrieve() async throws {
        struct TestData: Codable, Equatable {
            let value: String
        }
        
        let testData = TestData(value: "test")
        await cacheManager.store(testData, key: "test-key")
        
        let retrieved: TestData? = await cacheManager.retrieve(key: "test-key")
        XCTAssertEqual(retrieved, testData)
    }
    
    func testExpiration() async throws {
        struct TestData: Codable, Equatable {
            let value: String
        }
        
        let testData = TestData(value: "test")
        await cacheManager.store(testData, key: "test-key", ttl: 0.1)
        
        // Should be available immediately
        let retrieved1: TestData? = await cacheManager.retrieve(key: "test-key")
        XCTAssertEqual(retrieved1, testData)
        
        // Wait for expiration
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        // Should be expired
        let retrieved2: TestData? = await cacheManager.retrieve(key: "test-key")
        XCTAssertNil(retrieved2)
    }
    
    func testInvalidate() async throws {
        struct TestData: Codable {
            let value: String
        }
        
        let testData = TestData(value: "test")
        await cacheManager.store(testData, key: "test-key")
        await cacheManager.invalidate(key: "test-key")
        
        let retrieved: TestData? = await cacheManager.retrieve(key: "test-key")
        XCTAssertNil(retrieved)
    }
    
    func testInvalidateAll() async throws {
        struct TestData: Codable {
            let value: String
        }
        
        await cacheManager.store(TestData(value: "test1"), key: "key1")
        await cacheManager.store(TestData(value: "test2"), key: "key2")
        await cacheManager.invalidateAll()
        
        let retrieved1: TestData? = await cacheManager.retrieve(key: "key1")
        let retrieved2: TestData? = await cacheManager.retrieve(key: "key2")
        
        XCTAssertNil(retrieved1)
        XCTAssertNil(retrieved2)
    }
}
