
//
//  Utilities/SystemUtilities.swift
//  MacBox
//
//  Created by Tom on 2025/06/8.
//
import Foundation

public final class SystemUtilities {
    static func getFreeDiskSpace(in directory: URL = FileManager.default.homeDirectoryForCurrentUser) -> Int64? {
        do {
            let values = try directory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            return values.volumeAvailableCapacityForImportantUsage
        } catch {
            print("Error fetching free disk space: \(error)")
            return Int64(0)
        }
    }
}
