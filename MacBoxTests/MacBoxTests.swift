//
//  MacBoxTests.swift
//  MacBoxTests
//
//  Created by Tom on 2025/06/02.
//

import Testing
import Foundation

@testable import MacBox

struct MacBoxTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }
    
    @Test
        func testAddAndRemoveVM() async throws {
            let manager = VMManager()
            let vm = MacBox.VMConfig(
                id: UUID(),
                name: "Test VM",
                cpuCount: 2,
                memorySizeMB: 4096,
                diskSizeGB: 64,
                osType: "macOS" // Replace '.macOS' with the appropriate enum case if needed
            )

            manager.addVM(vm)
            #expect(manager.vmList.count == 1)
            #expect(manager.vmList.contains(where: { $0.id == vm.id && $0.name == vm.name }))
            manager.removeVM(vm)
            #expect(manager.vmList.isEmpty)
        }

}
