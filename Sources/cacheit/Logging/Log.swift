//
//  Log.swift
//  
//
//  Created by Brett Hamlin on 7/29/20.
//

import Foundation
import os.log

typealias LoggingLevel = CacheController.LoggingLevel
private var currentLogLevel: LoggingLevel {
    CacheController.shared.loggingLevel
}

enum LogCategory {
    private static var subsystem = Bundle.main.bundleIdentifier!
    private static let osLogSave = OSLog(subsystem: subsystem, category: "save")
    private static let osLogFetch = OSLog(subsystem: subsystem, category: "fetch")
    private static let osLogExpire = OSLog(subsystem: subsystem, category: "expire")

    case save, fetch, expire

    var osLog: OSLog {
        switch self {
        case .save:
            return Self.osLogSave
        case .fetch:
            return Self.osLogFetch
        case .expire:
            return Self.osLogExpire
        }
    }
}

func log(_ message: String, category: LogCategory, type: LoggingLevel) {
    switch type {
    case .debug where currentLogLevel.rawValue >= type.rawValue:
        os_log("\n%{public}@\n\n◾️", log: category.osLog, type: .debug, message)
    case .info where currentLogLevel.rawValue >= type.rawValue:
        os_log("\n%{public}@\n\n◾️", log: category.osLog, type: .info, message)
    default:
        break
    }
}
