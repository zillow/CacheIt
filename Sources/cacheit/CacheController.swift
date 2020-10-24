//
//  CacheController.swift
//  CacheKit
//
//  Created by Brett Hamlin on 2/17/20.
//

import Foundation

public final class CacheController {
    public static let shared = CacheController()
    public var loggingLevel: LoggingLevel = .none
    private lazy var transientCacheManager = TransientCacheManager()
    private lazy var persistentCacheManager = PersistentCacheManager()

    private init() { }

    public func createCacheUnit(with config: CacheUnitConfig) {
        switch config {
        case .transient:
            transientCacheManager.createCacheUnit(with: config)
        case .persistent:
            persistentCacheManager.createCacheUnit(with: config)
        }
    }

    public func cacheUnit<T: CacheUnit>(for key: CacheKey) -> T? {
        switch T.cacheType {
        case .transientType:
            return transientCacheManager.cacheUnit(for: key) as? T ?? nil
        case .persistentType:
            return persistentCacheManager.cacheUnit(for: key) as? T ?? nil
        }
    }

    public func removeCache(with cacheType: CacheType, for key: CacheKey) {
        switch cacheType {
        case .transientType:
            transientCacheManager.removeCache(for: key)
        case .persistentType:
            persistentCacheManager.removeCache(for: key)
        }
    }

    public func purgeCache(with cacheType: CacheType) {
        switch cacheType {
        case .transientType:
            transientCacheManager.purgeCache()
        case .persistentType:
            persistentCacheManager.purgeCache()
        }
    }

    // This function will update all config values for the cache type.  If you leave out
    // a value the cache manager will use its default value.
    public func setDefault(config: CacheDefaultConfig, with cacheType: CacheType) {
        switch cacheType {
        case .transientType:
            transientCacheManager.setDefault(config: config)
        case .persistentType:
            persistentCacheManager.setDefault(config: config)
        }
    }

    public func resetAllSettings() {
        transientCacheManager.purgeCache()
        persistentCacheManager.purgeCache()

        let transientConfig = CacheDefaultConfig.transient()
        transientCacheManager.setDefault(config: transientConfig)

        let persistentConfig = CacheDefaultConfig.persistent()
        persistentCacheManager.setDefault(config: persistentConfig)
    }
}

extension CacheController {
    public enum LoggingLevel: Int {
        case none
        case info
        case debug
    }
}
