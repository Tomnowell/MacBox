//
//  VZConfigurationBuilder.swift
//  MacBox
//
//  Created by Tom on 2025/06/09.
//

import Virtualization
import Foundation

struct VZConfigurationBuilder {
    // Helper function to download a file with retry logic and exponential backoff.
    static func downloadWithRetry(from url: URL, maxAttempts: Int = 3) async throws -> URL {
        var lastError: Error?
        for attempt in 1...maxAttempts {
            do {
                let (downloadedLocation, _) = try await URLSession.shared.download(from: url)
                return downloadedLocation
            } catch {
                lastError = error
                print("Attempt \(attempt) to download \(url) failed: \(error)")
                if attempt < maxAttempts {
                    let delay = UInt64(pow(2.0, Double(attempt - 1))) * 1_000_000_000 // 1s, 2s, 4s
                    print("Retrying in \(delay / 1_000_000_000) seconds...")
                    try await Task.sleep(nanoseconds: delay)
                }
            }
        }
        throw lastError ?? URLError(.unknown)
    }
    
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
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let localRestoreImageDirectoryURL = appSupportDir.appendingPathComponent("MacBoxRestoreImages", isDirectory: true)
        let localRestoreImageURL = localRestoreImageDirectoryURL
            .appendingPathComponent(restoreImage.url.lastPathComponent)

        // Ensure the destination directory exists
        try FileManager.default.createDirectory(at: localRestoreImageDirectoryURL, withIntermediateDirectories: true)

        // If restore image does not exist, download it and move to local cache
        if !FileManager.default.fileExists(atPath: localRestoreImageURL.path) {
            print("Restore image not found on disk; downloading...")
            let downloadedLocation = try await downloadWithRetry(from: restoreImage.url)
            // Remove any partially downloaded old file
            if FileManager.default.fileExists(atPath: localRestoreImageURL.path) {
                try FileManager.default.removeItem(at: localRestoreImageURL)
            }
            do {
                try FileManager.default.moveItem(at: downloadedLocation, to: localRestoreImageURL)
                print("Restore image moved to cache at \(localRestoreImageURL.path)")
            } catch {
                print("Move failed: \(error)")
                fatalError("Failed to move the macOS image to its destination.")
            }
        } else {
            print("Restore image already exists at \(localRestoreImageURL.path). Skipping download.")
        }
        
        
        // This image came from VZMacOSRestoreImage.latestSupported,
        // mostFeaturefulSupportedConfiguration should not be nil.
        let configurationRequirements =
        restoreImage.mostFeaturefulSupportedConfiguration!
        
        
        // Use vmConfig for all configuration
        
        // The following are minimum values; you can use larger values.
        vmConfig.cpuCount = config.cpuCount
        vmConfig.memorySize = config.memorySizeMB * 1024 * 1024 
        
        
        vmConfig.bootLoader = VZMacOSBootLoader()
        
        
        // Set up a valid Mac platform configuration for the restore image.
        let hardwareModel = configurationRequirements.hardwareModel
        let macPlatformConfiguration = VZMacPlatformConfiguration()
        
        let auxiliaryStorageDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("MacBoxAuxiliaryStorage", isDirectory: true)
        try FileManager.default.createDirectory(at: auxiliaryStorageDir, withIntermediateDirectories: true)
        let auxiliaryStorageURL = auxiliaryStorageDir.appendingPathComponent("AuxiliaryStorage.vzac")
        
        if FileManager.default.fileExists(atPath: auxiliaryStorageURL.path) {
                 try? FileManager.default.removeItem(at: auxiliaryStorageURL)
             }
        
        guard let auxiliaryStorage = try? VZMacAuxiliaryStorage(creatingStorageAt:
                                                                    auxiliaryStorageURL,
                                                                hardwareModel: hardwareModel,
                                                                options: []) else {
            fatalError("Failed to create auxiliary storage.")
        }
        macPlatformConfiguration.auxiliaryStorage = auxiliaryStorage
        macPlatformConfiguration.hardwareModel = hardwareModel
        vmConfig.platform = macPlatformConfiguration
        
        // MARK: Minimum required devices
        // Graphics device with a single display
        let graphicsDevice = VZMacGraphicsDeviceConfiguration()
        let display = VZMacGraphicsDisplayConfiguration(widthInPixels: 1920, heightInPixels: 1200, pixelsPerInch: 220)
        graphicsDevice.displays = [display]
        vmConfig.graphicsDevices = [graphicsDevice]

        // Keyboard
        vmConfig.keyboards = [VZUSBKeyboardConfiguration()]

        // Pointing device
        vmConfig.pointingDevices = [VZUSBScreenCoordinatePointingDeviceConfiguration()]
        
        
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

