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
    @State private var vmState: VZVirtualMachine.State = .stopped

    var isRunning: Bool {
        runtimeManager.runningVMs[vm.id] != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                
                if let message = launchStatus {
                    Text(message)
                        .foregroundColor(message.contains("Failed") ? .red : .green)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Text(vm.name)
                    .font(.largeTitle)
                
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CPU: \(vm.cpuCount) cores")
                    }
                    
                        .frame(height: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Memory: \(vm.memorySizeMB) MB")
                    }
                    
                        .frame(height: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Disk: \(vm.diskSizeGB) GB")
                    }
                    
                        .frame(height: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Display: \(vm.displayWidth) × \(vm.displayHeight)")
                        }
                    
                        .frame(height: 60)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        if let network = vm.networkType {
                            Text("Network: \(network)")
                        }
                    }
                    
                    Spacer()
                }
                .fixedSize(horizontal: false, vertical: true)
                
                // Show VM window when running
                if let virtualMachine = VMRuntimeManager.shared.virtualMachine(for: vm.id) {
                    
                    VStack(spacing: 4) {
                        HStack {
                            Text("Virtual Machine Display")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button("Open in Window") {
                                openVMInWindow(virtualMachine: virtualMachine)
                            }
                            .keyboardShortcut("f", modifiers: [.command, .control])
                            
                            Text("State: \(stateDescription(vmState))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 10)
                        }
                        
                        VirtualMachineDisplayView(virtualMachine: virtualMachine)
                            .frame(minWidth: 1200, minHeight: 600)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .aspectRatio(contentMode: .fit)
                            .border(Color.gray.opacity(0.3))
                    }
                }
 else {
                    // Placeholder space for VM display to prevent layout shift
                    
                    VStack(spacing: 4) {
                        HStack {
                            Text("Virtual Machine Display")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        
                        ZStack {
                            Rectangle()
                                .fill(Color(NSColor.windowBackgroundColor))
                                .frame(minWidth: 1200, minHeight: 600)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .aspectRatio(contentMode: .fit)
                                .border(Color.gray.opacity(0.3))
                            
                            VStack(spacing: 12) {
                                Image(systemName: "display")
                                    .font(.system(size: 64))
                                    .foregroundColor(.secondary.opacity(0.5))
                                Text("Start the VM to see the display")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                            

                HStack(spacing: 20) {
                    Button(isLaunching ? "Launching..." : "Start VM") {
                        isLaunching = true
                        launchStatus = nil
                        onLaunch()
                        Task {
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
                    
                    Spacer()
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
            }
            .padding(.horizontal).padding(.vertical, 8)
        }
        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
            // Update VM state periodically
            if let virtualMachine = runtimeManager.virtualMachine(for: vm.id) {
                vmState = virtualMachine.state
            } else {
                vmState = .stopped
            }
        }
    }
    
    private func openVMInWindow(virtualMachine: VZVirtualMachine) {
        // Close existing window if any
        vmWindow?.close()
        
        // VM display resolution (from VMConfig)
        let displayWidth: CGFloat = CGFloat(vm.displayWidth)
        let displayHeight: CGFloat = CGFloat(vm.displayHeight)
        
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
        window.setFrameTopLeftPoint(NSPoint(x: 0, y: NSScreen.main?.frame.height ?? 1080))
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
