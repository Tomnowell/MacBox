//
//  VZConfigurationBuilder.swift
//  MacBox
//
//  Created by Tom on 2025/06/09.
//


import Virtualization

struct VZConfigurationBuilder {
    static func build(from config: VMConfig) throws -> VZVirtualMachineConfiguration {
        let vmConfig = VZVirtualMachineConfiguration()
        
        // MARK: CPU & Memory
        vmConfig.cpuCount = config.cpuCount
        vmConfig.memorySize = config.memorySizeMB

        // MARK: Boot Loader
        let bootLoader = VZEFIBootLoader()
        
        // MARK: Install Media
        if let installMediaPath = config.installMediaPath {
            let installMediaURL = URL(fileURLWithPath: installMediaPath)
            bootLoader.variableStore = VZEFIVariableStore(url: installMediaURL)
        }
        vmConfig.bootLoader = bootLoader

        // MARK: Storage (optional)
        
        // MARK: Storage Devices
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
    }
}

