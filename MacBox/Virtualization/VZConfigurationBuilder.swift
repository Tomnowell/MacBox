//
//  VZConfigurationBuilder.swift
//  MacBox
//
//  Created by Tom on 2025/06/09.
//

import Foundation
import Virtualization

struct VZConfigurationBuilder {
    
    static func build(from config: VMConfig, restoreImage: VZMacOSRestoreImage, freshInstall: Bool) async throws -> VZVirtualMachineConfiguration {
        
        let configuration = VZVirtualMachineConfiguration()
        
        // Get the most featureful supported configuration from the restore image
        guard let macOSConfiguration = restoreImage.mostFeaturefulSupportedConfiguration else {
            throw NSError(domain: "VZConfigurationBuilder", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "No supported macOS configuration available"])
        }
        
        // Set up the platform (hardware model, machine identifier, auxiliary storage)
        configuration.platform = try createPlatform(config: config, macOSConfig: macOSConfiguration, freshInstall: freshInstall)
        
        // Set CPU count
        let cpuCount = max(1, min(config.cpuCount, VZVirtualMachineConfiguration.maximumAllowedCPUCount))
        configuration.cpuCount = cpuCount
        print("✓ CPU count: \(cpuCount)")
        
        // Set memory size
        let memorySize = max(macOSConfiguration.minimumSupportedMemorySize, config.memorySizeMB * 1024 * 1024)
        configuration.memorySize = memorySize
        print("✓ Memory: \(memorySize / 1024 / 1024) MB")
        
        // Set up boot loader
        configuration.bootLoader = VZMacOSBootLoader()
        
        // Set up graphics device
        configuration.graphicsDevices = [createGraphicsDevice(config: config)]
        
        // Set up storage
        configuration.storageDevices = try createStorageDevices(config: config)
        
        // Set up network
        configuration.networkDevices = createNetworkDevices()
        
        // Set up input devices
        configuration.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]
        configuration.keyboards = [VZUSBKeyboardConfiguration()]
        
        // Set up audio
        let audioInput = VZVirtioSoundDeviceConfiguration()
        let inputStream = VZVirtioSoundDeviceInputStreamConfiguration()
        inputStream.source = VZHostAudioInputStreamSource()
        audioInput.streams = [inputStream]
        
        let audioOutput = VZVirtioSoundDeviceConfiguration()
        let outputStream = VZVirtioSoundDeviceOutputStreamConfiguration()
        outputStream.sink = VZHostAudioOutputStreamSink()
        audioOutput.streams = [outputStream]
        
        configuration.audioDevices = [audioInput, audioOutput]
        
        // Validate configuration
        try configuration.validate()
        print("✅ Configuration validated successfully")
        
        return configuration
    }
    
    // MARK: - Platform Configuration
    
    private static func createPlatform(config: VMConfig, macOSConfig: VZMacOSConfigurationRequirements, freshInstall: Bool) throws -> VZMacPlatformConfiguration {
        
        let platform = VZMacPlatformConfiguration()
        
        // Set hardware model
        platform.hardwareModel = macOSConfig.hardwareModel
        print("✓ Hardware model set")
        
        // Set or create machine identifier
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let vmDir = appSupport.appendingPathComponent("MacBox/VMs/\(config.id.uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: vmDir, withIntermediateDirectories: true)
        
        let machineIdentifierURL = vmDir.appendingPathComponent("MachineIdentifier")
        
        if freshInstall || !FileManager.default.fileExists(atPath: machineIdentifierURL.path) {
            // Create new machine identifier for fresh install
            let newIdentifier = VZMacMachineIdentifier()
            platform.machineIdentifier = newIdentifier
            try newIdentifier.dataRepresentation.write(to: machineIdentifierURL)
            print("✓ Created new machine identifier")
        } else {
            // Load existing machine identifier
            let data = try Data(contentsOf: machineIdentifierURL)
            guard let loadedIdentifier = VZMacMachineIdentifier(dataRepresentation: data) else {
                throw NSError(domain: "VZConfigurationBuilder", code: 4,
                             userInfo: [NSLocalizedDescriptionKey: "Failed to load machine identifier from data"])
            }
            platform.machineIdentifier = loadedIdentifier
            print("✓ Loaded existing machine identifier")
        }
        
        // Set up auxiliary storage
        let auxStorageURL = vmDir.appendingPathComponent("AuxiliaryStorage")
        
        if freshInstall || !FileManager.default.fileExists(atPath: auxStorageURL.path) {
            // Create new auxiliary storage using the proper initializer
            let auxStorage = try VZMacAuxiliaryStorage(creatingStorageAt: auxStorageURL, hardwareModel: macOSConfig.hardwareModel)
            platform.auxiliaryStorage = auxStorage
            print("✓ Created new auxiliary storage")
        } else {
            // Load existing auxiliary storage
            platform.auxiliaryStorage = VZMacAuxiliaryStorage(contentsOf: auxStorageURL)
            print("✓ Loaded existing auxiliary storage")
        }
        
        return platform
    }
    
    // MARK: - Graphics Device
    
    private static func createGraphicsDevice(config: VMConfig) -> VZMacGraphicsDeviceConfiguration {
        let graphicsDevice = VZMacGraphicsDeviceConfiguration()
        graphicsDevice.displays = [
            VZMacGraphicsDisplayConfiguration(
                widthInPixels: config.displayWidth,
                heightInPixels: config.displayHeight,
                pixelsPerInch: 80
            )
        ]
        print("✓ Graphics device configured (\(config.displayWidth)x\(config.displayHeight))")
        return graphicsDevice
    }
    
    // MARK: - Storage Devices
    
    private static func createStorageDevices(config: VMConfig) throws -> [VZStorageDeviceConfiguration] {
        var storageDevices: [VZStorageDeviceConfiguration] = []
        
        // Determine boot disk path
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let vmDir = appSupport.appendingPathComponent("MacBox/VMs/\(config.id.uuidString)", isDirectory: true)
        let bootDiskURL: URL
        
        if let bootPath = config.bootDiskImagePath {
            bootDiskURL = URL(fileURLWithPath: bootPath)
        } else {
            bootDiskURL = vmDir.appendingPathComponent("Disk.img")
        }
        
        // Create boot disk if it doesn't exist
        if !FileManager.default.fileExists(atPath: bootDiskURL.path) {
            let diskSize = UInt64(config.diskSizeGB) * 1024 * 1024 * 1024
            try createDiskImage(at: bootDiskURL, size: diskSize)
            print("✓ Created boot disk: \(bootDiskURL.path) (\(config.diskSizeGB) GB)")
        } else {
            print("✓ Using existing boot disk: \(bootDiskURL.path)")
        }
        
        // Create disk attachment
        let diskAttachment = try VZDiskImageStorageDeviceAttachment(url: bootDiskURL, readOnly: false)
        let blockDevice = VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)
        storageDevices.append(blockDevice)
        
        return storageDevices
    }
    
    private static func createDiskImage(at url: URL, size: UInt64) throws {
        let fileDescriptor = open(url.path, O_RDWR | O_CREAT, S_IRUSR | S_IWUSR)
        guard fileDescriptor >= 0 else {
            throw NSError(domain: "VZConfigurationBuilder", code: 2,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to create disk image file"])
        }
        
        defer { close(fileDescriptor) }
        
        guard ftruncate(fileDescriptor, off_t(size)) == 0 else {
            throw NSError(domain: "VZConfigurationBuilder", code: 3,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to resize disk image"])
        }
    }
    
    // MARK: - Network Devices
    
    private static func createNetworkDevices() -> [VZNetworkDeviceConfiguration] {
        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.attachment = VZNATNetworkDeviceAttachment()
        print("✓ Network device configured (NAT)")
        return [networkDevice]
    }
}
