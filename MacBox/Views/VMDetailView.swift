//
//  VMDetailView.swift
//  MacBox
//
//  Created by Tom on 2025/06/09.
//

import SwiftUI

struct VMDetailView: View {
    let vmConfig: VMConfig
    @ObservedObject private var runtimeManager = VMRuntimeManager.shared

    var isRunning: Bool {
        runtimeManager.runningVMs[vmConfig.id] != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(vmConfig.name)
                .font(.largeTitle)
            Text("OS: \(vmConfig.osType)")
            Text("CPU: \(vmConfig.cpuCount) cores")
            Text("Memory: \(vmConfig.memorySizeMB) MB")
            Text("Disk: \(vmConfig.diskSizeGB) GB")
            if let bootDisk = vmConfig.bootDiskImagePath {
                Text("Boot Disk: \(bootDisk)")
            }
            if let installMedia = vmConfig.installMediaPath {
                Text("Install Media: \(installMedia)")
            }
            if let network = vmConfig.networkType {
                Text("Network: \(network)")
            }
            if !vmConfig.storageDevices.isEmpty {
                Text("Storage Devices: \(vmConfig.storageDevices.joined(separator: ", "))")
            }

            HStack(spacing: 20) {
                Button("Start VM") {
                    VMRuntimeManager.shared.launchVM(from: vmConfig)
                }
                .disabled(isRunning)

                Button("Stop VM") {
                    VMRuntimeManager.shared.stopVM(id: vmConfig.id)
                }
                .disabled(!isRunning)
            }
            .padding(.top, 20)
        }
        .padding()
    }
}
