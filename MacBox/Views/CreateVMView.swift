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
    
    // Restore image selection
    @State private var availableRestoreImages: [RestoreImageInfo] = []
    @State private var selectedRestoreImage: RestoreImageInfo?
    @State private var isFetchingRestoreImages = false
    @State private var restoreImageError: String?
    
    // Display resolution (defaults to host screen resolution)
    @State private var displayWidth: Int
    @State private var displayHeight: Int
    
    private var maxDiskSizeBytes = SystemUtilities.getFreeDiskSpace()
    private var maxDiskSizeGB: Int? {
        maxDiskSizeBytes.map { Int($0 / 1024 / 1024 / 1024) }
    }
    
    init() {
        let hostResolution = SystemUtilities.getMainScreenResolution()
        _displayWidth = State(initialValue: hostResolution.width)
        _displayHeight = State(initialValue: hostResolution.height)
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
            
            // Display Resolution Configuration
            VStack(alignment: .leading, spacing: 8) {
                Text("Display Resolution")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Width", value: $displayWidth, format: .number)
                        .frame(width: 80)
                    Text("×")
                    TextField("Height", value: $displayHeight, format: .number)
                        .frame(width: 80)
                    
                    Button("Reset to Host") {
                        let hostResolution = SystemUtilities.getMainScreenResolution()
                        displayWidth = hostResolution.width
                        displayHeight = hostResolution.height
                    }
                    .buttonStyle(.borderless)
                }
                
                Text("Current: \(displayWidth) × \(displayHeight) pixels")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // macOS Restore Image Selection
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("macOS Version")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if isFetchingRestoreImages {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Loading versions...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if availableRestoreImages.isEmpty {
                        Button("Load Available Versions") {
                            fetchRestoreImages()
                        }
                        .buttonStyle(.borderless)
                    }
                }
                
                if let error = restoreImageError {
                    Text("Error: \(error)")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                if !availableRestoreImages.isEmpty {
                    Picker("Select macOS Version", selection: $selectedRestoreImage) {
                        ForEach(availableRestoreImages) { imageInfo in
                            Text(imageInfo.displayName).tag(imageInfo as RestoreImageInfo?)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    if selectedRestoreImage == nil {
                        Text("Please select a macOS version to install")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            // Only support macOS for now - perhaps a pro version could support Linux / Windows on Arm etc.
            let osType = "macOS"

            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Create") {
                    let config = VMConfig(
                        name: name,
                        cpuCount: cpu,
                        memorySizeMB: memory,
                        diskSizeGB: disk,
                        osType: osType,
                        restoreImageURL: selectedRestoreImage?.url.absoluteString,
                        displayWidth: displayWidth,
                        displayHeight: displayHeight
                    )
                    vmManager.addVM(config)
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedRestoreImage == nil)
            }
        }
        .padding()
        .frame(width: 450)
        .onAppear {
            // Automatically fetch restore images when the view appears
            if availableRestoreImages.isEmpty {
                fetchRestoreImages()
            }
        }
    }
    
    private func fetchRestoreImages() {
        isFetchingRestoreImages = true
        restoreImageError = nil
        
        Task {
            do {
                let images = try await VMInstaller.fetchAvailableRestoreImages()
                await MainActor.run {
                    availableRestoreImages = images
                    // Auto-select the latest (first) image
                    selectedRestoreImage = images.first
                    isFetchingRestoreImages = false
                }
            } catch {
                await MainActor.run {
                    restoreImageError = error.localizedDescription
                    isFetchingRestoreImages = false
                }
            }
        }
    }
}
