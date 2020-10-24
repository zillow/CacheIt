//
//  TransientCacheUnit.swift
//  CacheKit
//
//  Created by Brett Hamlin on 2/17/20.
//

import Foundation

public final class TransientCacheUnit: CacheUnit {
    public static var cacheType: CacheType = .transientType
    public let cacheKey: CacheKey
    public let data: Data
    public let metaData: [String:Any]?
    public var expired: Bool {
        return Date().timeIntervalSinceNow > self.expiration.timeIntervalSinceNow
    }
    private var cacheManager: TransientCacheManager
    private let expiration: Date
    private var expirationTimer: Timer?

    init(cacheKey: CacheKey, cacheManager: TransientCacheManager, expiration: Date, data: Data, metaData: [String:Any]?) {
        self.cacheKey = cacheKey
        self.cacheManager = cacheManager
        self.expiration = expiration
        self.data = data
        self.metaData = metaData

        OperationQueue.main.addOperation {
            self.expirationTimer = Timer.scheduledTimer(withTimeInterval: self.expiration.timeIntervalSinceNow - Date().timeIntervalSinceNow, repeats: false) { [weak self] _ in
                self?.expire()
            }
        }
    }

    func expire() {
        log(description, category: .expire, type: .info)
        expirationTimer?.invalidate()
        cacheManager.removeCache(for: cacheKey)
    }

    deinit {
        expire()
    }
}

extension TransientCacheUnit: CustomStringConvertible {
    public var description: String {
        return  """
                CacheKey: \(cacheKey)
                CacheType: transient
                Expired: \(expired)
                """
    }
}
