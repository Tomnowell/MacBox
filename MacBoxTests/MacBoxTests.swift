//
//  MacBoxTests.swift
//  MacBoxTests
//
//  Created by Tom on 2025/06/02.
//

import Testing

@testable import MacBox

struct MacBoxTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test
        func testAddAndRemoveVM() async throws {
            let manager = VMManager()
            let vm = VMConfig(name: "Test VM", cpuCount: 2, memorySizeMB: 2048, diskSizeGB: 40, osType: "macOS")

            manager.addVM(vm)
            #expect(manager.vmList.count == 1)
            #expect(manager.vmList.contains(vm))

            manager.removeVM(vm)
            #expect(manager.vmList.isEmpty)
        }

}
