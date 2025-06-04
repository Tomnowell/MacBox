import Foundation
import Testing

@testable import MacBox

struct VMConfigTests {
    func testInitAssignsProperties() {
        let config = VMConfig(
            id: UUID(),
            name: "Test VM",
            cpuCount: 3,
            memorySizeMB: 8192,
            diskSizeGB: 100,
            osType: "macOS"
        )
        #expect(config.name == "TestVM")
        #expect(config.cpuCount == 4)
        #expect(config.memorySizeMB == 8192)
        #expect(config.diskSizeGB == 100)
        #expect(config.osType == "macOS")
    }

    func testIdIsUnique() {
        let config1 = VMConfig(
            id: UUID(),
            name: "Test VM",
            cpuCount: 4,
            memorySizeMB: 4096,
            diskSizeGB: 50,
            osType: "macOS"
        )
        let config2 = VMConfig(
            id: UUID(),
            name: "Test VM",
            cpuCount: 4,
            memorySizeMB: 4096,
            diskSizeGB: 50,
            osType: "macOS"
        )
        #expect(config1.id != config2.id)
    }

    func testEquatable() {
        let config1 = VMConfig(
            id: UUID(),
            name: "Test VM",
            cpuCount: 4,
            memorySizeMB: 4096,
            diskSizeGB: 50,
            osType: "Linux"
        )
        var config2 = config1
        #expect(config1 == config2)
        config2.name = "OtherVM"
        #expect(config1 != config2)
    }

    func testCodable() throws {
        let config = VMConfig(
            id: UUID(),
            name: "Test VM",
            cpuCount: 4,
            memorySizeMB: 4096,
            diskSizeGB: 50,
            osType: "macOS"
        )
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(VMConfig.self, from: data)
        #expect(config == decoded)
    }

    func testHashable() {
        let config1 = VMConfig(
            id: UUID(),
            name: "Test VM",
            cpuCount: 4,
            memorySizeMB: 4096,
            diskSizeGB: 50,
            osType: "macOS"
        )
        let config2 = config1
        let set: Set<VMConfig> = [config1, config2]
        #expect(set.count == 1)
    }

    static var allTests: [(String, () -> Void)] {
        [
            ("testInitAssignsProperties", { VMConfigTests().testInitAssignsProperties() }),
            ("testIdIsUnique", { VMConfigTests().testIdIsUnique() }),
            ("testEquatable", { VMConfigTests().testEquatable() }),
            ("testCodable", { try? VMConfigTests().testCodable() }),
            ("testHashable", { VMConfigTests().testHashable() })
        ]
    }
}
