//
//  VMManagerTest.swift
//  VMManagerTests
//
//  Created by Tom on 2025/06/02.
import Testing
import Foundation


@testable import MacBox


@Suite("VMManagerTests")
struct VMManagerTests {

    @Test("testAddVM")
    func testAddVM() async throws {
        let manager = VMManager()
        let vm = VMConfig(
            id: UUID(),
            name: "Test VM",
            cpuCount: 4,
            memorySizeMB: 4096,
            diskSizeGB: 50,
            osType: "macOS"
        )
        #expect(manager.vmList.isEmpty)
        manager.addVM(vm)
        #expect(manager.vmList.count == 1)
        #expect(manager.vmList.first == vm)
    }

    @Test("testRemoveVM")
    func testRemoveVM() async throws {
        let manager = VMManager()
        let vm1 = VMConfig(
            id: UUID(),
            name: "VM 1",
            cpuCount: 4,
            memorySizeMB: 4096,
            diskSizeGB: 50,
            osType: "macOS"
        )
        let vm2 = VMConfig(
            id: UUID(),
            name: "VM2",
            cpuCount: 4,
            memorySizeMB: 4096,
            diskSizeGB: 50,
            osType: "macOS"
        )
        manager.addVM(vm1)
        manager.addVM(vm2)
        #expect(manager.vmList.count == 2)
        manager.removeVM(vm1)
        #expect(manager.vmList.count == 1)
        #expect(manager.vmList.first == vm2)
    }

    @Test("testRemoveVM_NotInList")
    func testRemoveVM_NotInList() async throws {
        let manager = VMManager()
        let vm1 = VMConfig(
            id: UUID(),
            name: "VM1",
            cpuCount: 4,
            memorySizeMB: 4096,
            diskSizeGB: 50,
            osType: "macOS"
        )
        let vm2 = VMConfig(
            id: UUID(),
            name: "VM2",
            cpuCount: 4,
            memorySizeMB: 4096,
            diskSizeGB: 50,
            osType: "macOS"
        )
        manager.addVM(vm1)
        #expect(manager.vmList.count == 1)
        manager.removeVM(vm2)
        #expect(manager.vmList.count == 1)
        #expect(manager.vmList.first == vm1)
    }
}
