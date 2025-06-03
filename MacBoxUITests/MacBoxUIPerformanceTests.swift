//
//  MacBoxUIPerformanceTests.swift
//  MacBox
//
//  Created by Tom on 2025/06/03.
//
import XCTest

final class MacBoxLaunchPerformanceTests: XCTestCase {

    @MainActor
    func testLaunchPerformance() throws {
        // Ensure the original appearance is saved
        let originalAppearance = getSystemAppearance()

        defer {
            setSystemAppearance(to: originalAppearance)
        }

        let app = XCUIApplication()
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            app.terminate()
        }
        
    }
    
    func getSystemAppearance() -> String? {
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["read", "-g", "AppleInterfaceStyle"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func setSystemAppearance(to style: String?) {
        let task = Process()
        task.launchPath = "/usr/bin/defaults"

        if let style = style {
            task.arguments = ["write", "-g", "AppleInterfaceStyle", "-string", style]
        } else {
            task.arguments = ["remove", "-g", "AppleInterfaceStyle"]
        }

        task.launch()
        task.waitUntilExit()

        // Optional: refresh UI system-wide
        Process.launchedProcess(launchPath: "/usr/bin/killall", arguments: ["SystemUIServer"])
    }
}

