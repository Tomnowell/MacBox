//
// ViewModels/VMManager.swift
//  MacBox
//
//  Created by Tom on 2025/06/02.
//


import Foundation
import Combine

class VMManager: ObservableObject {
    @Published var vmList: [VMConfig] = []
    
    init() {
        loadVMs()
    }
    
    func addVM(_ config: VMConfig) {
        vmList.append(config)
        saveVMs()
    }
    
    // Overload method for calling from UI
    func addVM(name: String, osType: String, cpu: Int, memory: UInt64, disk: Int) {
        // Create boot disk path for the VM
        let bootDiskPath = createBootDiskPath(for: name)
        let config = VMConfig(
            name: name, 
            cpuCount: cpu, 
            memorySizeMB: memory, 
            diskSizeGB: disk, 
            osType: osType,
            bootDiskImagePath: bootDiskPath
        )
        addVM(config) // calls the first one
    }
    
    func updateVM(_ config: VMConfig) {
        if let index = vmList.firstIndex(where: { $0.id == config.id }) {
            vmList[index] = config
            saveVMs()
        }
    }
    
    func removeVM(_ vm: VMConfig) {
        // Remove from list first
        vmList.removeAll { $0.id == vm.id }
        
        // Clean up associated files
        cleanupVMFiles(for: vm)
        
        // Save updated list
        saveVMs()
    }
    
    func loadVMs() {
        let manager = FileManager.default
        guard manager.fileExists(atPath: saveURL.path) else {
            print("No VM list found.")
            return
        }
        
        do {
            let data = try Data(contentsOf: saveURL)
            vmList = try JSONDecoder().decode([VMConfig].self, from: data)
            print("Loaded VMs from: \(saveURL.path)")
        } catch {
            print("Failed to load VMs: \(error)")
        }
    }
    
    private func saveVMs() {
        do {
            let data = try JSONEncoder().encode(vmList)
            try data.write(to: saveURL)
            print("Saved VMs to: \(saveURL.path)")
        } catch {
            print("Failed to save VMs: \(error)")
        }
    }
    
    private func createBootDiskPath(for vmName: String) -> String {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let vmFolder = appSupport.appendingPathComponent("MacBox", isDirectory: true)
            .appendingPathComponent("VMs", isDirectory: true)
        
        // Create VMs directory if it doesn't exist
        try? FileManager.default.createDirectory(at: vmFolder, withIntermediateDirectories: true)
        // Use raw .img extension (not .dmg) for a block device style sparse file
        return vmFolder.appendingPathComponent("\(vmName).img").path
    }
    
    private func cleanupVMFiles(for vm: VMConfig) {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        
        // Remove the entire VM directory which contains:
        // - Disk.img
        // - MachineIdentifier
        // - AuxiliaryStorage
        // - Any other VM-specific files
        let vmDir = appSupport.appendingPathComponent("MacBox/VMs/\(vm.id.uuidString)", isDirectory: true)
        
        if fileManager.fileExists(atPath: vmDir.path) {
            do {
                try fileManager.removeItem(at: vmDir)
                print("✓ Removed VM directory: \(vmDir.path)")
            } catch {
                print("✗ Failed to remove VM directory: \(error.localizedDescription)")
            }
        }
        
        // Also remove boot disk if it's stored outside the VM directory
        if let bootDiskPath = vm.bootDiskImagePath, !bootDiskPath.contains(vm.id.uuidString) {
            if fileManager.fileExists(atPath: bootDiskPath) {
                do {
                    try fileManager.removeItem(atPath: bootDiskPath)
                    print("✓ Removed boot disk: \(bootDiskPath)")
                } catch {
                    print("✗ Failed to remove boot disk: \(error.localizedDescription)")
                }
            }
        }
        
        // Remove additional storage devices
        for storagePath in vm.storageDevices {
            if fileManager.fileExists(atPath: storagePath) {
                do {
                    try fileManager.removeItem(atPath: storagePath)
                    print("✓ Removed storage device: \(storagePath)")
                } catch {
                    print("✗ Failed to remove storage device: \(error.localizedDescription)")
                }
            }
        }
        
        // Remove installation marker if it exists
        if let bootDiskPath = vm.bootDiskImagePath {
            let markerURL = URL(fileURLWithPath: bootDiskPath).appendingPathExtension("installed")
            if fileManager.fileExists(atPath: markerURL.path) {
                try? fileManager.removeItem(at: markerURL)
                print("✓ Removed installation marker")
            }
        }
    }
    
    func clearAllVMs() {
        // Clean up all VM files first
        for vm in vmList {
            cleanupVMFiles(for: vm)
        }
        
        // Clear the list
        vmList.removeAll()
        saveVMs()
        print("Cleared all VMs")
    }
    
    private var saveURL: URL {
        let manager = FileManager.default
        let appSupport = manager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = appSupport.appendingPathComponent("MacBox", isDirectory: true)
        
        if !manager.fileExists(atPath: folder.path) {
            try? manager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        
        return folder.appendingPathComponent("vmList.json")
    }
}

