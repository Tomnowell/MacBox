//
//  Untitled.swift
//  MacBox
//
//  Created by Tom on 2025/06/02.
//

// Views/CreateVMView.swift
import SwiftUI

struct CreateVMView: View {
    @EnvironmentObject var vmManager: VMManager
    @Environment(\.dismiss) var dismiss
    @State private var name = "New VM"
    @State private var cpu = 2
    @State private var memory = 2048
    @State private var disk = 40
    @State private var osType = "macOS"

    let osTypes = ["macOS", "Linux"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Create New VM")
                .font(.headline)

            TextField("Name", text: $name)
            Stepper("CPU Cores: \(cpu)", value: $cpu, in: 1...8)
            Stepper("Memory: \(memory) MB", value: $memory, in: 512...16384, step: 512)
            Stepper("Disk: \(disk) GB", value: $disk, in: 10...500, step: 10)
            Picker("OS Type", selection: $osType) {
                ForEach(osTypes, id: \ .self) { Text($0) }
            }

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
