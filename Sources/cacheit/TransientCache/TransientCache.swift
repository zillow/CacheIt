//
//  TransientCache.swift
//  CacheKit
//
//  Created by Brett Hamlin on 2/22/20.
//

import Foundation

public struct TransientCache {
    let expiration: TimeInterval

    public init(expiration: TimeInterval) {
        self.expiration = expiration
    }

    public static subscript<T: Any>(key: CacheKey) -> T? {
        get {
            let cacheUnit: TransientCacheUnit? = CacheController.shared.cacheUnit(for: key)
            guard let data = cacheUnit?.data else { return nil }
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? T
        }
        set {
            if let data = newValue {
                let archivedData = NSKeyedArchiver.archivedData(withRootObject: data)
                let config = CacheUnitConfig.transient(cacheKey: key, data: archivedData)
                CacheController.shared.createCacheUnit(with: config)
            }
            else {
                CacheController.shared.removeCache(with: .transientType, for: key)
            }
        }
    }

    public subscript<T: Any>(key: CacheKey) -> T? {
        get {
           return type(of: self)[key]
        }
        set {
            if let data = newValue {
                let archivedData = NSKeyedArchiver.archivedData(withRootObject: data)
                let config = CacheUnitConfig.transient(cacheKey: key, expiration: expiration, data: archivedData)
                CacheController.shared.createCacheUnit(with: config)
            }
            else {
                type(of: self)[key] = newValue
            }
        }
    }

    /// Removes a value for a key from disk.
    ///
    /// - Parameters:
    ///   - key: The key associated with `value`.
    public static func removeCache(for key: CacheKey) {
        guard let cacheUnit: TransientCacheUnit = CacheController.shared.cacheUnit(for: key) else { return }
        cacheUnit.expire()
    }

    /// Removes a value for a key from disk.
    ///
    /// - Parameters:
    ///   - key: The key associated with `value`.
    public func removeCache(for key: CacheKey) {
        Self.removeCache(for: key)
    }

    /// Removes all cache from memory.
    public static func removeAllCache() {
        CacheController.shared.purgeCache(with: .transientType)
    }

    /// Removes all cache from memory.
    public func removeAllCache() {
        Self.removeAllCache()
    }
}

@objc public class NSTransientCache: NSObject {
    @objc public static override func value(forKey key: String) -> Any? {
        TransientCache[key]
    }

    @objc public static func set(value: Any, for key: String) {
        TransientCache[key] = value
    }
}
