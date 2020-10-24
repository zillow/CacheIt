//
//  TransientCacheManager.swift
//  CacheKit
//
//  Created by Brett Hamlin on 2/17/20.
//

import Foundation

class TransientCacheManager: CacheManager {
    private var cache = [CacheKey:TransientCacheUnit]()
    private let queue = DispatchQueue(label: "TransientCacheManagerQueue", attributes: .concurrent)
    private var expiration: TimeInterval

    init() {
        let defaultConfig = CacheDefaultConfig.transient()
        guard case .transient(let expiration) = defaultConfig else {
            assertionFailure("Something very bad went wrong with initializing TransientCacheManager.")
            self.expiration = 0
            return
        }

        self.expiration = expiration
    }

    func removeCache(for key: CacheKey) {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeValue(forKey: key)
        }
    }

    func createCacheUnit(with config: CacheUnitConfig) {
        guard case .transient(let cacheKey, let expiration, let data, let metaData) = config else {
            assertionFailure("Attempting to pass incorrect CacheUnitConfig into TransientCacheManager.")
            return
        }

        let cacheUnit = TransientCacheUnit(cacheKey: cacheKey,
                                           cacheManager: self,
                                           expiration: Date.init(timeIntervalSinceNow: expiration ?? self.expiration),
                                           data: data,
                                           metaData: metaData)

        queue.async(flags: .barrier) { [weak self] in
            self?.cache[cacheKey] = cacheUnit
            log(cacheUnit.description, category: .save, type: .info)
        }
    }

    func cacheUnit(for cacheKey: CacheKey) -> TransientCacheUnit? {
        queue.sync {
          return cache[cacheKey]
        }
    }

    func purgeCache() {
        for cacheKey in cache.keys {
            removeCache(for: cacheKey)
        }
    }

    func setDefault(config: CacheDefaultConfig) {
        guard case .transient(let expiration) = config else {
            assertionFailure("Attempting to set config which is not type transient.")
            return
        }

        self.expiration = expiration
    }
}
