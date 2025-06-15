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
    
    @State private var launchStatus: String?
    @State private var isStopping = false
    @State private var isLaunching = false

    var isRunning: Bool {
        runtimeManager.runningVMs[vmConfig.id] != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            if let message = launchStatus {
                Text(message)
                    .foregroundColor(message.contains("Failed") ? .red : .green)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
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
                Button(isLaunching ? "Launching..." : "Start VM") {
                    isLaunching = true
                    launchStatus = nil
                    Task {
                        do {
                            try await VMRuntimeManager.shared.launchVM(from: vmConfig)
                            isLaunching = false
                            launchStatus = "VM started successfully!"
                        } catch {
                            isLaunching = false
                            launchStatus = "Failed to start VM: \(error.localizedDescription)"
                        }
                    }
                }
                .disabled(isLaunching)
                .disabled(isRunning)

                
                Button(isStopping ? "Stopping..." : "Stop VM") {
                    isLaunching = false
                    isStopping = true
                    VMRuntimeManager.shared.stopVM(id: vmConfig.id) { result in
                        isLaunching = false
                        switch result {
                        case .success:
                            launchStatus = "🛑 VM '\(vmConfig.name)' stopped successfully."
                        case .failure(let error):
                            launchStatus = "❌ Failed to stop VM: \(error.localizedDescription)"
                        }
                    }
                }
                .disabled(isLaunching || !VMRuntimeManager.shared.isRunning(id: vmConfig.id))
            }
            .padding(.top, 20)
        }
        .padding()
    }
}

