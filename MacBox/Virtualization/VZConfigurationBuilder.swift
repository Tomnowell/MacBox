//
//  VZConfigurationBuilder.swift
//  MacBox
//
//  Created by Tom on 2025/06/09.
//


import Virtualization

struct VZConfigurationBuilder {
    static func build(from config: VMConfig) async throws -> VZVirtualMachineConfiguration {
        let vmConfig = VZVirtualMachineConfiguration()
        // Load the latest image.
        guard let restoreImage = try? await VZMacOSRestoreImage.latestSupported
        else {
            fatalError("No restore image is supported.")
        }
        
        
        // restoreImage came from latestSupported, its URL property refers
        // to an image on the network.
        // Download the image to the local filesystem.
        guard let (location, _) = try? await
                URLSession.shared.download(from: restoreImage.url) else {
            fatalError("""
                               Failed to download the macOS image from the network.
                               """)
        }
        
        
        // VZMacOSInstaller must be called with a URL corresponding to a local file.
        let localRestoreImageDirectoryURL = URL(fileURLWithPath:
            "*set to the directory where the restore image should be stored*")
        
        let localRestoreImageURL = localRestoreImageDirectoryURL
            .appendingPathComponent(restoreImage.url.lastPathComponent)
        
        
        guard ((try? FileManager.default.moveItem(at: location, to:
                                                    localRestoreImageURL)) != nil)
        else {
            fatalError("Failed to move the macOS image to its destination.")
        }
        
        
        // This image came from VZMacOSRestoreImage.latestSupported,
        // mostFeaturefulSupportedConfiguration should not be nil.
        let configurationRequirements =
        restoreImage.mostFeaturefulSupportedConfiguration!
        
        
        // Construct a VZVirtualMachineConfiguration that satisfies the
        // configuration requirements.
        let configuration = VZVirtualMachineConfiguration()
        
        
        // The following are minimum values; you can use larger values.
        configuration.cpuCount = config.cpuCount
        configuration.memorySize = config.memorySizeMB
        
        
        configuration.bootLoader = VZMacOSBootLoader()
        
        
        // Set up a valid Mac platform configuration for the restore image.
        let hardwareModel = configurationRequirements.hardwareModel
        let macPlatformConfiguration = VZMacPlatformConfiguration()
        let auxiliaryStorageURL = URL(fileURLWithPath:
                                        "*set to the path where the auxiliary storage should be stored*")
        guard let auxiliaryStorage = try? VZMacAuxiliaryStorage(creatingStorageAt:
                                                                    auxiliaryStorageURL,
                                                                hardwareModel: hardwareModel,
                                                                options: []) else {
            fatalError("Failed to create auxiliary storage.")
        }
        macPlatformConfiguration.auxiliaryStorage = auxiliaryStorage
        macPlatformConfiguration.hardwareModel = hardwareModel
        configuration.platform = macPlatformConfiguration
        
        
        fatalError(
            """
            *set up storageDevices, graphicsDevices, pointingDevices,
            keyboards, etc. here*
            """)
        
        
        guard ((try? configuration.validate()) != nil) else {
            fatalError("Virtual machine configuration is invalid.")
        }
        
        
        let virtualMachine = VZVirtualMachine(configuration: configuration)
        let installer = VZMacOSInstaller(virtualMachine: virtualMachine,
                                         restoringFromImageAt: localRestoreImageURL)
        installer.install(completionHandler: { (result: Result) in
            if case let .failure(error) = result {
                fatalError("Installation failure: \(error)")
            } else {
                // Installation was successful.
            }
        })
        
        
        // Observe progress using installer.progress object.
        installer.progress.observe(\.fractionCompleted, options: [.initial, .new]) {
            (progress, change) in
            print("Installation progress: \(change.newValue! * 100).")
        }
        
        var storageDevices: [VZStorageDeviceConfiguration] = []
        
        if let bootDisk = config.bootDiskImagePath {
            let attachment = try VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: bootDisk), readOnly: false)
            storageDevices.append(VZVirtioBlockDeviceConfiguration(attachment: attachment))
        }
        
        for path in config.storageDevices {
            let attachment = try VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: path), readOnly: false)
            storageDevices.append(VZVirtioBlockDeviceConfiguration(attachment: attachment))
        }
        
        vmConfig.storageDevices = storageDevices
        
        // MARK: Network (optional)
        if let networkType = config.networkType?.lowercased() {
            let networkDevice = VZVirtioNetworkDeviceConfiguration()
            
            switch networkType {
            case "nat":
                networkDevice.attachment = VZNATNetworkDeviceAttachment()
            case "bridged":
                guard let interface = VZBridgedNetworkInterface.networkInterfaces.first else {
                    throw ConfigurationError.noBridgedInterface
                }
                networkDevice.attachment = VZBridgedNetworkDeviceAttachment(interface: interface)
            default:
                break // No network device if type is unrecognised or nil
            }
            
            if networkDevice.attachment != nil {
                vmConfig.networkDevices = [networkDevice]
            }
        }
        
        // MARK: Validation
        try vmConfig.validate()
        
        return vmConfig
    }
    
    enum ConfigurationError: Error {
        case noBridgedInterface
        case missingEFIVariableStore
    }
}


