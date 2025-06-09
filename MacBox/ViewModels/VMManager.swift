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
    
    func addVM(_ config: VMConfig) {
        vmList.append(config)
    }
    
    // Overload method for calling from UI
    func addVM(name: String, osType: String, cpu: Int, memory: UInt64, disk: Int) {
        let config = VMConfig(name: name, cpuCount: cpu, memorySizeMB: memory, diskSizeGB: disk, osType: osType)
        addVM(config) // calls the first one
    }
    
    func updateVM(_ config: VMConfig) {
        if let index = vmList.firstIndex(where: { $0.id == config.id }) {
            vmList[index] = config
        }
    }
    
    func removeVM(_ vm: VMConfig) {
        vmList.removeAll { $0.id == vm.id }
    }
    
    func loadVMs() {
        let manager = FileManager.default
        guard manager.fileExists(atPath: saveURL.path) else {
            print("ℹ️ No saved VM list found.")
            return
        }
        
        do {
            let data = try Data(contentsOf: saveURL)
            vmList = try JSONDecoder().decode([VMConfig].self, from: data)
            print("✅ Loaded VMs from: \(saveURL.path)")
        } catch {
            print("❌ Failed to load VMs: \(error)")
        }
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

