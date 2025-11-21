//
//  Models/VMConfig.swift
//  MacBox
//
//  Created by Tom on 2025/06/8.
//
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
    var installMediaPath: URL? // Optional boot/install ISO image
    var networkType: String? // e.g., "NAT", "Bridged", "HostOnly"
    var restoreImageURL: String? // URL of the selected macOS restore image
    
    var storageDevices: [String]
    var displayWidth: Int
    var displayHeight: Int

    init(
        id: UUID = UUID(),
        name: String = "MacBox VM",
        cpuCount: Int = 1,
        memorySizeMB: UInt64 = 8196,
        diskSizeGB: Int = 128,
        osType: String = "MacOs15",
        efiVariableStorePath: String? = nil,
        bootDiskImagePath: String? = nil,
        networkType: String? = nil,
        restoreImageURL: String? = nil,
        storageDevices: [String] = [],
        displayWidth: Int = 1920,
        displayHeight: Int = 1200
    ) {
        self.id = id
        self.name = name
        self.cpuCount = cpuCount
        self.memorySizeMB = memorySizeMB
        self.diskSizeGB = diskSizeGB
        self.osType = osType
        self.efiVariableStorePath = efiVariableStorePath
        self.bootDiskImagePath = bootDiskImagePath
        self.networkType = networkType
        self.restoreImageURL = restoreImageURL
        self.storageDevices = storageDevices
        self.displayWidth = displayWidth
        self.displayHeight = displayHeight
    }

    // MARK: - Codable conformance
    enum CodingKeys: String, CodingKey {
        case id, name, cpuCount, memorySizeMB, diskSizeGB, osType, bootDiskImagePath, installMediaPath, networkType, restoreImageURL, storageDevices, displayWidth, displayHeight
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
