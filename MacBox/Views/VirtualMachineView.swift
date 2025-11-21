//
//  VirtualMachineView.swift
//  MacBox
//
//  Created by Tom on 2025/06/09.
//

import SwiftUI
import Virtualization

struct VirtualMachineView: View {
    let vmConfig: VMConfig
    @StateObject private var runtimeManager = VMRuntimeManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isFullscreen = false
    
    var body: some View {
        VStack(spacing: 0) {
            // VM Display Area
            if let vm = runtimeManager.virtualMachine(for: vmConfig.id) {
                VirtualMachineDisplayView(virtualMachine: vm)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Initializing Virtual Machine...")
                        .font(.headline)
                    Text(vmConfig.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
            }
            
            // Control Bar
            HStack {
                Button("Stop VM") {
                    stopVM()
                }
                .disabled(!runtimeManager.isRunning(id: vmConfig.id))
                
                Button(isFullscreen ? "Exit Fullscreen" : "Fullscreen") {
                    toggleFullscreen()
                }
                .disabled(!runtimeManager.isRunning(id: vmConfig.id))
                .keyboardShortcut("f", modifiers: [.command, .control])
                
                Spacer()
                
                if let vm = runtimeManager.virtualMachine(for: vmConfig.id) {
                    Text("State: \(stateDescription(vm.state))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .navigationTitle(vmConfig.name)
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(errorMessage ?? "Unknown error occurred")
        }
    }
    
    private func stopVM() {
        runtimeManager.stopVM(id: vmConfig.id) { result in
            switch result {
            case .success:
                dismiss()
            case .failure(let error):
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func toggleFullscreen() {
        guard let window = NSApp.keyWindow else { return }
        window.toggleFullScreen(nil)
        isFullscreen.toggle()
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

struct VirtualMachineDisplayView: NSViewRepresentable {
    let virtualMachine: VZVirtualMachine
    
    func makeNSView(context: Context) -> VZVirtualMachineView {
        let view = VZVirtualMachineView()
        view.virtualMachine = virtualMachine
        view.capturesSystemKeys = true
        return view
    }
    
    func updateNSView(_ nsView: VZVirtualMachineView, context: Context) {
        // Update if needed
        if nsView.virtualMachine !== virtualMachine {
            nsView.virtualMachine = virtualMachine
        }
    }
}
