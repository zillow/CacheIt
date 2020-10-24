//
//  PersistentCache.swift
//  CacheKit
//
//  Created by Brett Hamlin on 2/22/20.
//

import Foundation

typealias PersistentCacheCompletion = () -> Void

public struct PersistentCache {
    let expiration: TimeInterval

    public init(expiration: TimeInterval) {
        self.expiration = expiration
    }
}

// MARK: Non-blocking calls
extension PersistentCache {

    /// Retrieves a value for a key from disk.
    ///
    /// This call does not block.
    ///
    /// - Parameters:
    ///   - key: The key to associate with `value`. If `key` already exists in
    ///     the dictionary, `value` replaces the existing associated value.
    ///
    ///   - completion: The completion handler which returns the value request or nil if it doesn't exist.
    public static func value<T: Any>(forKey key: CacheKey, completion: @escaping (_ value: T?) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let value: T? =  self[key]
            completion(value)
        }
    }

    /// Note: This call does not block.  The completion handler will be called when the data has been written successfully.
    public static func setValue<T: Any>(value: T?, forKey key: CacheKey, completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .utility).async {
            self[key] = value
            completion()
        }
    }

    /// Removes a value for a key from disk.
    ///
    /// This call does not block.
    ///
    /// - Parameters:
    ///   - key: The key associated with `value`.
    public static func removeCache(for key: CacheKey) {
        guard let cacheUnit: PersistentCacheUnit = CacheController.shared.cacheUnit(for: key) else { return }
        cacheUnit.expire()
    }

    /// Removes a value for a key from disk.
    ///
    /// This call does not block.
    ///
    /// - Parameters:
    ///   - key: The key associated with `value`.
    public func removeCache(for key: CacheKey) {
        Self.removeCache(for: key)
    }

    /// Removes all cache from disk.
    ///
    /// This call does not block.
    public static func removeAllCache() {
        CacheController.shared.purgeCache(with: .persistentType)
    }

    /// Removes all cache from disk.
    ///
    /// This call does not block.
    public func removeAllCache() {
        Self.removeAllCache()
    }
}

// MARK: Blocking calls
extension PersistentCache {

    /// Note: This is a blocking call.  It is advisable to call the static function with the completion handler if you intend to call this from the main thread.
    public static subscript<T: Any>(key: CacheKey) -> T? {
        get {
            let cacheUnit: PersistentCacheUnit? = CacheController.shared.cacheUnit(for: key)
            guard let data = cacheUnit?.data else { return nil }
            return NSKeyedUnarchiver.unarchiveObject(with: data) as? T
        }
        set {
            if let data = newValue {
                let archivedData = NSKeyedArchiver.archivedData(withRootObject: data)
                let config = CacheUnitConfig.persistent(cacheKey: key, dataType: .data(data: archivedData))
                CacheController.shared.createCacheUnit(with: config)
            }
            else {
                CacheController.shared.removeCache(with: .persistentType, for: key)
            }
        }
    }

    /// Note: This is a blocking call.  It is advisable to call the static function with the completion handler if you intend to call this from the main thread.
    public subscript<T: Any>(key: CacheKey) -> T? {
        get {
           return type(of: self)[key]
        }
        set {
            if let data = newValue {
                let archivedData = NSKeyedArchiver.archivedData(withRootObject: data)
                let config = CacheUnitConfig.persistent(cacheKey: key, expiration: expiration, dataType: .data(data: archivedData))
                CacheController.shared.createCacheUnit(with: config)
            }
            else {
                type(of: self)[key] = newValue
            }
        }
    }
}

@objc public class NSPersistentCache: NSObject {
    @objc public static override func value(forKey key: String) -> Any? {
        PersistentCache[key]
    }

    @objc public static func set(value: Any, for key: String) {
        PersistentCache[key] = value
    }
}
