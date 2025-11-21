//
//  Utilities/SystemUtilities.swift
//  MacBox
//
//  Created by Tom on 2025/06/8.
//
import Foundation
import AppKit

public final class SystemUtilities {
    public static func getFreeDiskSpace(in directory: URL = FileManager.default.homeDirectoryForCurrentUser) -> Int64? {
        do {
            let values = try directory.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            return values.volumeAvailableCapacityForImportantUsage
        } catch {
            print("Error fetching free disk space: \(error)")
            return Int64(0)
        }
    }
    
    public static func getMainScreenResolution() -> (width: Int, height: Int) {
        guard let screen = NSScreen.main else {
            // Fallback to a reasonable default if screen is not available
            return (width: 1920, height: 1200)
        }
        
        // Get the screen's frame in logical points (not physical pixels)
        // This is the resolution that macOS applications use
        let frame = screen.frame
        
        // Get the visible frame which excludes the menu bar and dock
        let visibleFrame = screen.visibleFrame
        
        let width = Int(frame.width)
        // Use visible height to account for menu bar
        // The visibleFrame excludes menu bar at top and dock at bottom
        let height = Int(visibleFrame.height)
        
        return (width: width, height: height)
    }
}
