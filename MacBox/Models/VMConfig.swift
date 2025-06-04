import Foundation

final class VMConfig: Identifiable, ObservableObject, Codable, Equatable, Hashable {
    var id: UUID
    var name: String
    var cpuCount: Int
    var memorySizeMB: Int
    var diskSizeGB: Int
    var osType: String // "macOS" or "Linux"
    
    var diskImagePaths: [String] // Absolute paths to attached disk images
    var installMediaPath: String? // Optional boot/install ISO image
    var networkType: String // e.g., "NAT", "Bridged", "HostOnly"

    init(
        id: UUID = UUID(),
        name: String = "MacBox VM",
        cpuCount: Int = 2,
        memorySizeMB: Int = 4096,
        diskSizeGB: Int = 20,
        osType: String = "Linux",
        diskImagePaths: [String] = [],
        installMediaPath: String? = nil,
        networkType: String = "None"
    ) {
        self.id = id
        self.name = name
        self.cpuCount = cpuCount
        self.memorySizeMB = memorySizeMB
        self.diskSizeGB = diskSizeGB
        self.osType = osType
        self.diskImagePaths = diskImagePaths
        self.installMediaPath = installMediaPath
        self.networkType = networkType
    }

    // MARK: - Codable conformance
    enum CodingKeys: String, CodingKey {
        case id, name, cpuCount, memorySizeMB, diskSizeGB, osType
        case diskImagePaths, installMediaPath, networkType
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
