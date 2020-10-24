//
//  CacheKit.swift
//  CacheKit
//
//  Created by Brett Hamlin on 2/19/20.
//

import Foundation

public typealias CacheKey = String
public typealias CacheId = String

public enum CacheType {
    case transientType
    case persistentType
}

public enum CacheUnitConfig {
    case transient(cacheKey: CacheKey, expiration: TimeInterval? = nil, data: Data, metaData: [String:Any]? = nil)
    case persistent(cacheKey: CacheKey, expiration: TimeInterval? = nil, dataType: PersistentCacheDataType, metaData: [String:Any]? = nil)
    
    public func cache(cacheController: CacheController = CacheController.shared) {
        cacheController.createCacheUnit(with: self)
    }
}

public enum CacheDefaultConfig {
    case transient(expiration: TimeInterval = 30)
    case persistent(expiration: TimeInterval = 60 * 60, maxDiskSpaceUsage: UInt = 200)
}

public protocol CacheUnit {
    static var cacheType: CacheType { get }
    var cacheKey: CacheKey { get }
    var metaData: [String : Any]? { get }
    var data: Data { get }
}

protocol CacheManager {
    associatedtype CacheUnitType: CacheUnit

    func createCacheUnit(with config: CacheUnitConfig)
    func cacheUnit(for key: CacheKey) -> CacheUnitType?
    func removeCache(for key: CacheKey)
    func purgeCache()
}
