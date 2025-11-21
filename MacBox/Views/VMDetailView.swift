//
//  VMDetailView.swift
//  MacBox
//
//  Created by Tom on 2025/06/09.
//

import SwiftUI
import Virtualization

struct VMDetailView: View {
    let vm: VMConfig
    let onLaunch: () -> Void
    @ObservedObject private var runtimeManager = VMRuntimeManager.shared
    
    @State private var launchStatus: String?
    @State private var isStopping = false
    @State private var isLaunching = false
    @State private var showVMWindow = false
    @State private var vmWindow: NSWindow?

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
                    HStack {
                        Text("Virtual Machine Display")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Open in Window") {
                            openVMInWindow(virtualMachine: virtualMachine)
                        }
                        .keyboardShortcut("f", modifiers: [.command, .control])
                        
                        if let vm = runtimeManager.virtualMachine(for: vm.id) {
                            Text("State: \(stateDescription(vm.state))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 10)
                        }
                    }
                    
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
    
    private func openVMInWindow(virtualMachine: VZVirtualMachine) {
        // Close existing window if any
        vmWindow?.close()
        
        // VM display resolution (matches VZConfigurationBuilder settings: 1920x1200)
        let displayWidth: CGFloat = 1920
        let displayHeight: CGFloat = 1200
        
        // Add space for the control bar at the bottom (approximately 50 points)
        let controlBarHeight: CGFloat = 50
        let windowHeight = displayHeight + controlBarHeight
        
        // Create the window content
        let windowContent = NSHostingController(rootView:
            VStack(spacing: 0) {
                VirtualMachineDisplayView(virtualMachine: virtualMachine)
                    .frame(width: displayWidth, height: displayHeight)
                
                HStack {
                    Text(vm.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("State: \(stateDescription(virtualMachine.state))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("Close Window") {
                        vmWindow?.close()
                    }
                    .padding(.leading, 10)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
            }
        )
        
        // Create the window with the VM's display resolution
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: displayWidth, height: windowHeight),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        window.title = "\(vm.name) - Virtual Machine"
        window.contentViewController = windowContent
        window.center()
        window.makeKeyAndOrderFront(nil)
        
        // Enable fullscreen
        window.collectionBehavior = [.fullScreenPrimary]
        
        // Store reference to window
        vmWindow = window
        
        // Make the window stay open and handle close
        window.isReleasedWhenClosed = false
    }
    
    private func stateDescription(_ state: VZVirtualMachine.State) -> String {
        switch state {
        case .stopped: return "Stopped"
        case .running: return "Running"
        case .paused: return "Paused"
        case .error: return "Error"
        case .starting: return "Starting"
        case .pausing: return "Pausing"
        case .resuming: return "Resuming"
        case .stopping: return "Stopping"
        case .saving: return "Saving State"
        case .restoring: return "Restoring State"
        @unknown default: return "Unknown"
        }
    }
}
