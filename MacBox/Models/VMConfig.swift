import Foundation
import Virtualization

struct VMConfig: Identifiable, Codable, Equatable, Hashable, Sendable {
    var id: UUID
    var name: String
    var cpuCount: Int
    var memorySizeMB: UInt64
    var diskSizeGB: Int
    var osType: String // "macOS14"
    var efiVariableStorePath: String? // Required for ALL modern OS that require EFI boot.
    
    var bootDiskImagePath: String? // Absolute paths to attached disk images
    var installMediaPath: String? // Optional boot/install ISO image
    var networkType: String? // e.g., "NAT", "Bridged", "HostOnly"
    
    var storageDevices: [String]

    init(
        id: UUID = UUID(),
        name: String = "MacBox VM",
        cpuCount: Int = 1,
        memorySizeMB: UInt64 = 4096,
        diskSizeGB: Int = 10,
        osType: String = "MacOs15",
        efiVariableStorePath: String? = nil,
        bootDiskImagePath: String? = nil,
        installMediaPath: String? = nil,
        networkType: String? = nil,
        storageDevices: [String] = []
    ) {
        self.id = id
        self.name = name
        self.cpuCount = cpuCount
        self.memorySizeMB = memorySizeMB
        self.diskSizeGB = diskSizeGB
        self.osType = osType
        self.efiVariableStorePath = efiVariableStorePath
        self.bootDiskImagePath = bootDiskImagePath
        self.installMediaPath = installMediaPath
        self.networkType = networkType
        self.storageDevices = storageDevices
    }

    // MARK: - Codable conformance
    enum CodingKeys: String, CodingKey {
        case id, name, cpuCount, memorySizeMB, diskSizeGB, osType, bootDiskImagePath, installMediaPath, networkType, storageDevices
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    // MARK: - Equatable
    static func == (lhs: VMConfig, rhs: VMConfig) -> Bool {
        lhs.id == rhs.id
    }
}
