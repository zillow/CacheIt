//
//  PersistentCacheTests.swift
//  UnitTests
//
//  Created by Brett Hamlin on 2/21/20.
//

import XCTest
import CacheIt

class PersistentCacheTests: XCTestCase {

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
        CacheController.shared.resetAllSettings()
        super.setUp()
    }

    func testPersistentDataCache() {
        let config = CacheUnitConfig.persistent(cacheKey: TestData.cacheKey, dataType: .data(data: data))
        CacheController.shared.createCacheUnit(with: config)

        let fetchedCache: PersistentCacheUnit? = CacheController.shared.cacheUnit(for: TestData.cacheKey)
        guard let data = fetchedCache?.data,
            let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
            let firstValue = jsonObject[TestData.cacheTestDataKey] else {
                XCTFail("Problem with data.")
                return
        }

        XCTAssertEqual(firstValue, TestData.cacheTestDataValue)
    }

    func testPersistentFileCache() {
        guard let filePath = Bundle(for: type(of: self)).url(forResource: "PeopleNames", withExtension: "json") else {
            XCTFail("Failed to get JSON file path.")
            return
        }

        let config = CacheUnitConfig.persistent(cacheKey: TestData.cacheKey, dataType: .file(file: filePath))
        CacheController.shared.createCacheUnit(with: config)

        let fetchedCache: PersistentCacheUnit? = CacheController.shared.cacheUnit(for: TestData.cacheKey)
        guard let data = fetchedCache?.data,
            let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: String],
            let firstValue = jsonObject[TestData.cacheTestDataKey] else {
                XCTFail("Problem with data.")
                return
        }

        XCTAssertEqual(firstValue, TestData.cacheTestDataValue)
    }

    func testStaticPersistentCacheSubscript() {
        var persistentCacheInstance = PersistentCache(expiration: 30)
        persistentCacheInstance[TestData.cacheTestDataKey] = TestData.cacheTestDataValue
        let value: String? = persistentCacheInstance[TestData.cacheTestDataKey]
        XCTAssertEqual(value, TestData.cacheTestDataValue)
    }

    func testPersistentCacheSubscript() {
        PersistentCache[TestData.cacheTestDataKey] = TestData.cacheTestDataValue
        let value: String? = PersistentCache[TestData.cacheTestDataKey]
        XCTAssertEqual(value, TestData.cacheTestDataValue)
    }

    func testNSPersistentCacheSubscript() {
        PersistentCache[TestData.cacheTestDataKey] = TestData.cacheTestDataValue
        let value = NSPersistentCache.value(forKey: TestData.cacheTestDataKey) as? String
        XCTAssertEqual(value, TestData.cacheTestDataValue)
    }

    func testPersistentCacheExpired() {
        let config = CacheUnitConfig.persistent(cacheKey: TestData.cacheKey, expiration: TestData.cacheKeyExpiredTime, dataType: .data(data: data))
        CacheController.shared.createCacheUnit(with: config)

        Timer.scheduledTimer(withTimeInterval: TestData.cacheKeyExpiredTime + 1, repeats: false) { (timer) in
             NotificationCenter.default.post(name: TestData.cacheKeyExpiredNotificationName, object: self)
         }

        let expectation = XCTNSNotificationExpectation(name: TestData.cacheKeyExpiredNotificationName)
        wait(for: [expectation], timeout: TestData.cacheKeyExpiredTime + 5)

        let fetchedCache: PersistentCacheUnit? = CacheController.shared.cacheUnit(for: TestData.cacheKey)
        XCTAssertNil(fetchedCache, "Cache still exists")
    }

    func testPersistentCacheMetaData() {
        let config = CacheUnitConfig.persistent(cacheKey: TestData.cacheKey, dataType: .data(data: data), metaData: TestData.metaData)
        CacheController.shared.createCacheUnit(with: config)

        let fetchedCache: PersistentCacheUnit? = CacheController.shared.cacheUnit(for: TestData.cacheKey)
        guard let jsonObject = fetchedCache?.metaData as? [String: String],
            let firstValue = jsonObject[TestData.cacheTestMetaDataKey] else {
                XCTFail("Problem with data.")
                return
        }

        XCTAssertEqual(firstValue, TestData.cacheTestMetaDataValue)
    }

    func testPersistentCacheConfigExpiration() {
        CacheController.shared.setDefault(config: CacheDefaultConfig.persistent(expiration: TestData.customCacheConfigExpiration), with: .persistentType)

        let config = CacheUnitConfig.persistent(cacheKey: TestData.cacheKey, dataType: .data(data: data))
        CacheController.shared.createCacheUnit(with: config)

        Timer.scheduledTimer(withTimeInterval: TestData.customCacheConfigExpiration + 1, repeats: false) { (timer) in
             NotificationCenter.default.post(name: TestData.cacheKeyExpiredNotificationName, object: self)
         }

        let expectation = XCTNSNotificationExpectation(name: TestData.cacheKeyExpiredNotificationName)
        wait(for: [expectation], timeout: TestData.customCacheConfigExpiration + 5)

        let fetchedCache: PersistentCacheUnit? = CacheController.shared.cacheUnit(for: TestData.cacheKey)
        XCTAssertNil(fetchedCache, "Cache still exists")
    }

    func testPersistentCacheRemoveValue() {
        PersistentCache[TestData.cacheTestDataKey] = TestData.cacheTestDataValue
        let valueNotNil: String? = PersistentCache[TestData.cacheTestDataKey]
        XCTAssertNotNil(valueNotNil)

        PersistentCache[TestData.cacheTestDataKey] = nil as String?
        let valueNil: String? = PersistentCache[TestData.cacheTestDataKey]
        XCTAssertNil(valueNil)
    }

    func testPersistentCacheFetchAsync() {
        PersistentCache.setValue(value: TestData.cacheTestDataValue, forKey: TestData.cacheTestDataKey) {
            PersistentCache.value(forKey: TestData.cacheTestDataKey) { (val: String?) in
                XCTAssertNotNil(val)
            }
        }
    }

    func testRemoveStaticPersistentCacheSubscript() {
        PersistentCache[TestData.cacheTestDataKey] = TestData.cacheTestDataValue

        let valueNotNil: String? = PersistentCache[TestData.cacheTestDataKey]
        XCTAssertNotNil(valueNotNil)

        PersistentCache.removeCache(for: TestData.cacheTestDataKey)
        let valueNil: String? = PersistentCache[TestData.cacheTestDataKey]
        XCTAssertNil(valueNil)
    }

    func testRemoveStaticPersistentCache() {
        PersistentCache[TestData.cacheTestDataKey] = TestData.cacheTestDataValue

        let valueNotNil: String? = PersistentCache[TestData.cacheTestDataKey]
        XCTAssertNotNil(valueNotNil)

        PersistentCache.removeAllCache()
        let valueNil: String? = PersistentCache[TestData.cacheTestDataKey]
        XCTAssertNil(valueNil)
    }
}
