//
//  VMDetailView.swift
//  MacBox
//
//  Created by Tom on 2025/06/09.
//

import SwiftUI

struct VMDetailView: View {
    let vm: VMConfig
    let onLaunch: () -> Void
    @ObservedObject private var runtimeManager = VMRuntimeManager.shared
    
    @State private var launchStatus: String?
    @State private var isStopping = false
    @State private var isLaunching = false
    @State private var showVMWindow = false

    var isRunning: Bool {
        runtimeManager.runningVMs[vm.id] != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            if let message = launchStatus {
                Text(message)
                    .foregroundColor(message.contains("Failed") ? .red : .green)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            Text(vm.name)
                .font(.largeTitle)
            Text("OS: \(vm.osType)")
            Text("CPU: \(vm.cpuCount) cores")
            Text("Memory: \(vm.memorySizeMB) MB")
            Text("Disk: \(vm.diskSizeGB) GB")
            if let bootDisk = vm.bootDiskImagePath {
                Text("Boot Disk: \(bootDisk)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            if let network = vm.networkType {
                Text("Network: \(network)")
            }
            if !vm.storageDevices.isEmpty {
                Text("Storage Devices: \(vm.storageDevices.joined(separator: ", "))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Show VM window when running
            if let virtualMachine = VMRuntimeManager.shared.virtualMachine(for: vm.id) {
                Divider()
                
                VStack(spacing: 10) {
                    Text("Virtual Machine Display")
                        .font(.headline)
                    
                    VirtualMachineDisplayView(virtualMachine: virtualMachine)
                        .frame(minWidth: 1280, minHeight: 800)
                        .border(Color.gray.opacity(0.3))
                }
            }
                        

            HStack(spacing: 20) {
                Button(isLaunching ? "Launching..." : "Start VM") {
                    isLaunching = true
                    launchStatus = nil
                    onLaunch()
                    Task {
                        // Wait a moment for launch to complete
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        isLaunching = false
                        if runtimeManager.isRunning(id: vm.id) {
                            launchStatus = "VM started successfully!"
                            showVMWindow = true
                        }
                    }
                }
                .disabled(isLaunching || isRunning)

                
                Button(isStopping ? "Stopping..." : "Stop VM") {
                    isStopping = true
                    showVMWindow = false
                    VMRuntimeManager.shared.stopVM(id: vm.id) { result in
                        isStopping = false
                        switch result {
                        case .success:
                            launchStatus = "VM '\(vm.name)' stopped successfully."
                        case .failure(let error):
                            launchStatus = "Failed to stop VM: \(error.localizedDescription)"
                        }
                    }
                }
                .disabled(isStopping || !runtimeManager.isRunning(id: vm.id))
            }
            .padding(.top, 20)
        }
        .padding()
    }
}
