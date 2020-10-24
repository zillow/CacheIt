//
//  TransientCacheTests.swift
//  UnitTests
//
//  Created by Brett Hamlin on 2/21/20.
//

import XCTest
import CacheIt

class TransientCacheTests: XCTestCase {

    enum TestData {
        static let cacheKey = "testCacheKey"
        static let cacheKeyExpiredTime: TimeInterval = 1
        static let cacheKeyExpiredNotificationName = Notification.Name("testCacheKeyExpired")
        static let cacheTestDataKey = "Brett"
        static let cacheTestDataValue = "Hamlin"
        static let cache = [TestData.cacheTestDataKey : TestData.cacheTestDataValue]
        static let cacheTestMetaDataKey = "MimeType"
        static let cacheTestMetaDataValue = "JSON"
        static let metaData = [TestData.cacheTestMetaDataKey : TestData.cacheTestMetaDataValue]
        static let customCacheConfigExpiration: TimeInterval = 1
    }

    lazy var data: Data = {
        do {
            return try JSONSerialization.data(withJSONObject: TestData.cache, options: [])
        }
        catch {
            XCTFail("Unable to load data.")
            return Data()
        }
    }()

    override func setUp() {
        let test = "1234"
        
        CacheController.shared.resetAllSettings()
        super.setUp()
    }

    func testTransientCache() {
        let config = CacheUnitConfig.transient(cacheKey: TestData.cacheKey, data: data)
        CacheController.shared.createCacheUnit(with: config)

        let fetchedCache: TransientCacheUnit? = CacheController.shared.cacheUnit(for: TestData.cacheKey)
        guard let data = fetchedCache?.data,
            let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
            let firstValue = jsonObject[TestData.cacheTestDataKey] else {
                XCTFail("Problem with data.")
                return
        }

        XCTAssertEqual(firstValue, TestData.cacheTestDataValue)
    }

    func testStaticTransientCacheSubscript() {
        var transientCacheInstance = TransientCache(expiration: 10)
        transientCacheInstance[TestData.cacheTestDataKey] = TestData.cacheTestDataValue
        let value: String? = transientCacheInstance[TestData.cacheTestDataKey]
        XCTAssertEqual(value, TestData.cacheTestDataValue)
    }

    func testTransientCacheSubscript() {
        TransientCache[TestData.cacheTestDataKey] = TestData.cacheTestDataValue
        let value: String? = TransientCache[TestData.cacheTestDataKey]
        XCTAssertEqual(value, TestData.cacheTestDataValue)
    }

    func testTransientCacheExpired() {
        let config = CacheUnitConfig.transient(cacheKey: TestData.cacheKey, expiration: TestData.cacheKeyExpiredTime, data: data)
        CacheController.shared.createCacheUnit(with: config)

        Timer.scheduledTimer(withTimeInterval: TestData.cacheKeyExpiredTime + 1, repeats: false) { (timer) in
             NotificationCenter.default.post(name: TestData.cacheKeyExpiredNotificationName, object: self)
         }

        let expectation = XCTNSNotificationExpectation(name: TestData.cacheKeyExpiredNotificationName)
        wait(for: [expectation], timeout: TestData.cacheKeyExpiredTime + 5)

        let fetchedCache: TransientCacheUnit? = CacheController.shared.cacheUnit(for: TestData.cacheKey)
        XCTAssertNil(fetchedCache, "Cache still exists")
    }

    func testNSTransientCacheSubscript() {
        TransientCache[TestData.cacheTestDataKey] = TestData.cacheTestDataValue
        let value = NSTransientCache.value(forKey: TestData.cacheTestDataKey) as? String
        XCTAssertEqual(value, TestData.cacheTestDataValue)
    }

    func testTransientCacheMetaData() {
        let config = CacheUnitConfig.transient(cacheKey: TestData.cacheKey, data: data, metaData: TestData.metaData)
        CacheController.shared.createCacheUnit(with: config)

        let fetchedCache: TransientCacheUnit? = CacheController.shared.cacheUnit(for: TestData.cacheKey)
        guard let jsonObject = fetchedCache?.metaData as? [String: String],
            let firstValue = jsonObject[TestData.cacheTestMetaDataKey] else {
                XCTFail("Problem with data.")
                return
        }

        XCTAssertEqual(firstValue, TestData.cacheTestMetaDataValue)
    }

    func testTransientCacheConfigExpiration() {
        CacheController.shared.setDefault(config: CacheDefaultConfig.transient(expiration: TestData.customCacheConfigExpiration), with: .transientType)

        let config = CacheUnitConfig.transient(cacheKey: TestData.cacheKey, data: data)
        CacheController.shared.createCacheUnit(with: config)

        Timer.scheduledTimer(withTimeInterval: TestData.customCacheConfigExpiration + 1, repeats: false) { (timer) in
             NotificationCenter.default.post(name: TestData.cacheKeyExpiredNotificationName, object: self)
         }

        let expectation = XCTNSNotificationExpectation(name: TestData.cacheKeyExpiredNotificationName)
        wait(for: [expectation], timeout: TestData.customCacheConfigExpiration + 5)

        let fetchedCache: TransientCacheUnit? = CacheController.shared.cacheUnit(for: TestData.cacheKey)
        XCTAssertNil(fetchedCache, "Cache still exists")
    }

    func testTransientCacheRemoveValue() {
        TransientCache[TestData.cacheTestDataKey] = TestData.cacheTestDataValue
        let valueNotNil: String? = TransientCache[TestData.cacheTestDataKey]
        XCTAssertNotNil(valueNotNil)

        TransientCache[TestData.cacheTestDataKey] = nil as String?
        let valueNil: String? = TransientCache[TestData.cacheTestDataKey]
        XCTAssertNil(valueNil)
    }

    func testRemoveStaticTransientCacheSubscript() {
        TransientCache[TestData.cacheTestDataKey] = TestData.cacheTestDataValue

        let valueNotNil: String? = TransientCache[TestData.cacheTestDataKey]
        XCTAssertNotNil(valueNotNil)

        TransientCache.removeCache(for: TestData.cacheTestDataKey)
        let valueNil: String? = TransientCache[TestData.cacheTestDataKey]
        XCTAssertNil(valueNil)
    }

    func testRemoveStaticTransient() {
        TransientCache[TestData.cacheTestDataKey] = TestData.cacheTestDataValue

        let valueNotNil: String? = TransientCache[TestData.cacheTestDataKey]
        XCTAssertNotNil(valueNotNil)

        TransientCache.removeAllCache()
        let valueNil: String? = TransientCache[TestData.cacheTestDataKey]
        XCTAssertNil(valueNil)
    }
}
