//
//  Untitled.swift
//  MacBox
//
//  Created by Tom on 2025/06/02.
//

// Views/CreateVMView.swift
import SwiftUI
import System

struct CreateVMView: View {
    @EnvironmentObject var vmManager: VMManager
    @Environment(\.dismiss) var dismiss
    @State private var name = "New VM"
    @State private var cpu = 2
    @State private var memory: UInt64 = 2048
    @State private var disk = 50
    @State private var osType = "macOS"
    
    @State private var diskImagePaths: [String] = []
    @State private var installMediaPath: String = ""
    @State private var networkType = "None"
    
    private var maxDiskSizeBytes = SystemUtilities.getFreeDiskSpace()
    private var maxDiskSizeGB: Int? {
        maxDiskSizeBytes.map { Int($0 / 1024 / 1024 / 1024) }
    }
    
    

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create New VM")
                .font(.headline)

            TextField("Name", text: $name)
            Stepper(
                "CPU Cores: \(cpu)",
                value: $cpu,
                in: 1...(ProcessInfo.processInfo.processorCount)
            )
            Stepper(
                "Memory: \(memory) MB",
                value: $memory,
                in: 512...(ProcessInfo.processInfo.physicalMemory / 1024 / 1024),
                step: 512
            )
            Stepper("Disk: \(disk) GB", value: $disk, in: 0...(maxDiskSizeGB ?? 0), step: 10)
            
            // Only support macOS for now - perhaps a pro version could support Linux / Windows on Arm etc.
            let osType = "macOS"

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Create") {
                    let config = VMConfig(name: name, cpuCount: cpu, memorySizeMB: memory, diskSizeGB: disk, osType: osType)
                    vmManager.addVM(config)
                    dismiss()
                }
            }
        }
        .padding()
        .frame(width: 400)
    }
}
