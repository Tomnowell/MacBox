//
//  MacBoxUIPerformanceTests.swift
//  MacBox
//
//  Created by Tom on 2025/06/03.
//
import XCTest

final class MacBoxLaunchPerformanceTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchPerformance() throws {
    
        let app = XCUIApplication()
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
            app.terminate()
        }
    }
    
}

