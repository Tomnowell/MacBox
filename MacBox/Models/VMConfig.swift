//
// Models/VMConfig.swift
//  MacBox
//
//  Created by Tom on 2025/06/02.
//

import Foundation

struct VMConfig: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var cpuCount: Int
    var memorySizeMB: Int
    var diskSizeGB: Int
    var osType: String // "macOS" or "Linux"

    init(name: String, cpuCount: Int, memorySizeMB: Int, diskSizeGB: Int, osType: String) {
        self.id = UUID()
        self.name = name
        self.cpuCount = cpuCount
        self.memorySizeMB = memorySizeMB
        self.diskSizeGB = diskSizeGB
        self.osType = osType
    }
}
