//
//  PersistentCacheUnit.swift
//  CacheKit
//
//  Created by Brett Hamlin on 2/20/20.
//

import Foundation

public enum PersistentCacheDataType {
    case data(data: Data)
    case file(file: URL)
    case alreadyStoredFile(fileName: String)
}

enum PersistentCacheSector {
    case header
    case metaData
    case cachedData
}

public final class PersistentCacheUnit: CacheUnit {
    private enum HeaderKeys {
        static var cacheKey = "_cacheKey"
        static var expiration = "_expiration"
        static var fileName = "_fileName"
        static var version = "_version"
    }

    public static var cacheType: CacheType = .persistentType
    public let cacheKey: CacheKey
    public var expired: Bool {
        return Date().timeIntervalSinceNow > self.expiration.timeIntervalSinceNow
    }
    let fileName: String
    public var data: Data {
        cacheManager.data(for: .cachedData, with: fileName) ?? Data()
    }
    public let metaData: [String:Any]?
    private let cacheManager: PersistentCacheManager
    private let expiration: Date
    private let cacheId: CacheId
    private var expirationTimer: Timer?

    init?(cacheKey: CacheKey, cacheManager: PersistentCacheManager, expiration: Date, dataType: PersistentCacheDataType, metaData: [String:Any]?) {
        self.cacheKey = cacheKey
        self.cacheManager = cacheManager
        self.expiration = expiration
        self.metaData = metaData

        switch dataType {
        case .data(let data):
            self.cacheId = NSUUID().uuidString
            self.fileName = cacheId
            saveCache(data: data, expiration: expiration, metaData: metaData)
        case .file(let fileURL):
            self.fileName = NSUUID().uuidString
            self.cacheId = fileName
            guard let data = cacheManager.data(contentsOf: fileURL) else { return nil }
            saveCache(data: data, expiration: expiration, metaData: metaData)
        case .alreadyStoredFile(let fileName):
            self.fileName = fileName
            self.cacheId = fileName
        }

        let expirationTime = max(self.expiration.timeIntervalSinceNow - Date().timeIntervalSinceNow, 1)
        OperationQueue.main.addOperation {
            self.expirationTimer = Timer.scheduledTimer(withTimeInterval: expirationTime, repeats: false) { [weak self] _ in
                self?.expire()
            }
        }
    }

    convenience init?(with cachedDataContainerFileName: String, cacheManager: PersistentCacheManager) {
        guard let headerData = cacheManager.data(for: .header, with: cachedDataContainerFileName),
        let header = try? JSONSerialization.jsonObject(with: headerData, options: []) as? [String: Any],
        let cacheKey = header[HeaderKeys.cacheKey] as? String,
        let expirationStr = header[HeaderKeys.expiration] as? String,
        let expiration = ISO8601DateFormatter().date(from: expirationStr)
        else { return nil }

        var metaData:[String:Any]?
        if let metaDataData = cacheManager.data(for: .metaData, with: cachedDataContainerFileName),
            let jsonMetaData = try? JSONSerialization.jsonObject(with: metaDataData, options: []) as? [String: Any] {
            metaData = jsonMetaData
        }

        self.init(cacheKey: cacheKey, cacheManager: cacheManager, expiration: expiration, dataType: .alreadyStoredFile(fileName: cachedDataContainerFileName), metaData: metaData)
    }

    private func saveCache(data: Data, expiration: Date, metaData: [String:Any]?) {
        let cacheKitVersion = Bundle(identifier: "org.cocoapods.CacheKit")?.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

        let expirationStr = ISO8601DateFormatter.string(from: expiration,
                                                        timeZone: .current,
                                                        formatOptions: [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime, .withTimeZone])
        let header = [HeaderKeys.fileName : fileName,
                      HeaderKeys.cacheKey : cacheKey,
                      HeaderKeys.expiration : expirationStr,
                      HeaderKeys.version : cacheKitVersion]

        guard let headerData = try? JSONSerialization.data(withJSONObject: header, options: []) else { return }

        var metaDataData: Data?
        if let metaData = metaData {
            do {
                metaDataData = try JSONSerialization.data(withJSONObject: metaData, options: [])
            }
            catch {
                return
            }
        }

        var headerLength = UInt(headerData.count)
        var metaLength = UInt(metaDataData?.count ?? 0)
        let lengthDescriptionBytes = UInt(MemoryLayout<UInt>.size) * 2

        // total offset from data must be less than UInt.max otherwise do not cache
        guard headerLength + metaLength + lengthDescriptionBytes < UInt.max else { return }

        var container = Data()

        let headerDataLength = Data(bytes: &headerLength, count: MemoryLayout.size(ofValue: headerLength))
        container.append(headerDataLength)

        let metaDataLength = Data(bytes: &metaLength, count: MemoryLayout.size(ofValue: metaLength))
        container.append(metaDataLength)

        container.append(headerData)

        if let metaDataData = metaDataData {
            container.append(metaDataData)
        }

        container.append(data)
        cacheManager.saveCache(with: container, fileName: fileName)
    }

    func expire() {        
        log(description, category: .expire, type: .info)
        expirationTimer?.invalidate()
        cacheManager.removeCache(for: cacheKey)
    }
}

extension PersistentCacheUnit: CustomStringConvertible {
    public var description: String {
        let expireString = expired ? "true" : "expiring due to duplicate cacheKey being added"
        return  """
                CacheKey: \(cacheKey)
                CacheType: persistent
                CacheId: \(cacheId)
                Expired: \(expireString)
                """
    }
}
