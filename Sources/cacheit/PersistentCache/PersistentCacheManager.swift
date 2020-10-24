//
//  PersistentCacheManager.swift
//  CacheKit
//
//  Created by Brett Hamlin on 2/20/20.
//

import Foundation

class PersistentCacheManager: CacheManager {
    private var cache = [CacheKey:PersistentCacheUnit]()
    private let queue = DispatchQueue(label: "PersistentCacheManagerQueue", attributes: .concurrent)
    private var expiration: TimeInterval
    private var maxDiskSpaceUsage: UInt

    private var cacheDirectory: URL = {
        let path = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true).appendingPathComponent("CacheKit", isDirectory: true)
        try? FileManager.default.createDirectory(at: path, withIntermediateDirectories: false, attributes: [:])
        return path
    }()

    init() {
        let defaultConfig = CacheDefaultConfig.persistent()
        guard case .persistent(let expiration, let maxDiskSpaceUsage) = defaultConfig else {
            assertionFailure("Something very bad went wrong with initializing PersistentCacheManager.")
            self.expiration = 0
            self.maxDiskSpaceUsage = 0
            return
        }

        self.expiration = expiration
        self.maxDiskSpaceUsage = maxDiskSpaceUsage

        reloadCache()
    }

    private func reloadCache() {
        guard let cachedFiles = try? FileManager.default.contentsOfDirectory(at: self.cacheDirectory, includingPropertiesForKeys: [], options: [])
            else { return }

        let diskCache = [CacheKey: PersistentCacheUnit](cachedFiles.compactMap {
            guard let cacheUnit = PersistentCacheUnit(with: $0.lastPathComponent, cacheManager: self) else { return nil }
            return (cacheUnit.cacheKey, cacheUnit)
        }, uniquingKeysWith: { (first, _) in first })

        log("CacheIt loading \(diskCache.count) item(s) from disk cache.", category: .fetch, type: .info)
        self.cache.merge(diskCache) {(current, _) in current}
    }

    func removeCache(for key: CacheKey) {
        queue.sync { [weak self] in
            guard let cacheUnit = self?.cache[key],
                 let cacheDirectory = self?.cacheDirectory.appendingPathComponent(cacheUnit.fileName)
            else { return }

            try? FileManager.default.removeItem(at: cacheDirectory)
            self?.cache.removeValue(forKey: key)
        }
    }

    func createCacheUnit(with config: CacheUnitConfig) {
        guard case .persistent(let cacheKey, let expiration, let dataType, let metaData) = config else {
            assertionFailure("Attempting to pass incorrect CacheUnitConfig into PersistentCacheManager.")
            return
        }

        let cacheUnit: PersistentCacheUnit?

        // remove older cache if already exists
        if let cacheUnit = cache[cacheKey] {
            cacheUnit.expire()
        }

        if case .alreadyStoredFile(let fileName) = dataType {
            cacheUnit = PersistentCacheUnit(with: fileName, cacheManager: self)
        }
        else {
            cacheUnit = PersistentCacheUnit(cacheKey: cacheKey,
                                           cacheManager: self,
                                           expiration: Date.init(timeIntervalSinceNow: expiration ?? self.expiration),
                                           dataType: dataType,
                                           metaData: metaData)
        }

        queue.sync { [weak self] in
            if let cacheUnit = cacheUnit {
                self?.cache[cacheKey] = cacheUnit
                log(cacheUnit.description, category: .save, type: .info)
            }
        }
    }

    func cacheUnit(for cacheKey: CacheKey) -> PersistentCacheUnit? {
        queue.sync {
          return cache[cacheKey]
        }
    }

    func saveCache(with data: Data, fileName: String) {
        let filePath = cacheDirectory.appendingPathComponent(fileName, isDirectory: false)

        queue.sync {
            try? data.write(to: filePath)
        }
    }

    func data(contentsOf url: URL) -> Data? {
        queue.sync {
          return try? Data(contentsOf: url)
        }
    }

    private func data<T>(for bytes: Data, copiedTo value: inout T) {
        let bytesCopied = withUnsafeMutableBytes(of: &value, { bytes.copyBytes(to: $0)})
        assert(bytesCopied == MemoryLayout.size(ofValue: value))
    }

    func data(for sector: PersistentCacheSector, with fileName: String) -> Data? {
        queue.sync {
            guard let container = data(contentsOf: cacheDirectory.appendingPathComponent(fileName, isDirectory: false)),
                container.count > 2 else { return nil }

            var headerLength: UInt = 0
            data(for: container[...MemoryLayout<UInt>.size], copiedTo: &headerLength)

            var metaDataLength: UInt = 0
            data(for: container[MemoryLayout<UInt>.size..<(MemoryLayout<UInt>.size * 2)], copiedTo: &metaDataLength)

            let lengthDescriptionBytes = UInt(MemoryLayout<UInt>.size) * 2
            let cacheStart = UInt(lengthDescriptionBytes + headerLength + metaDataLength)

            switch sector {
            case .cachedData:
                return container[cacheStart...]
            case .header:
                return container[lengthDescriptionBytes..<(lengthDescriptionBytes + headerLength)]
            case .metaData:
                return metaDataLength > 0 ? container[(lengthDescriptionBytes + headerLength)..<(lengthDescriptionBytes + headerLength + metaDataLength)] : nil
            }
        }
    }

    func purgeCache() {
        for cacheKey in cache.keys {
            removeCache(for: cacheKey)
        }
    }

    func setDefault(config: CacheDefaultConfig) {
        guard case .persistent(let expiration, let maxDiskSpaceUsage) = config else {
            assertionFailure("Attempting to set config which is not type persistent.")
            return
        }
        self.expiration = expiration
        self.maxDiskSpaceUsage = maxDiskSpaceUsage
    }
}
