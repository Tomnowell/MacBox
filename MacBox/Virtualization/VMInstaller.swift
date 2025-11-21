//
//  VMInstaller.swift
//  MacBox
//
//  Created by Tom on 2025/06/28.
//

@preconcurrency import Virtualization // Relax concurrency checking; Apple Virtualization types aren't fully Sendable yet
import Foundation

struct RestoreImageInfo: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let buildVersion: String
    let isLatest: Bool
    
    var displayName: String {
        let filename = url.lastPathComponent
        // Extract version from filename if possible (e.g., "UniversalMac_14.0_23A344_Restore.ipsw")
        if let versionMatch = filename.range(of: #"_(\d+\.\d+(?:\.\d+)?)_"#, options: .regularExpression) {
            let version = String(filename[versionMatch]).trimmingCharacters(in: CharacterSet(charactersIn: "_"))
            return "macOS \(version) (Build \(buildVersion))\(isLatest ? " - Latest" : "")"
        }
        return "macOS Build \(buildVersion)\(isLatest ? " - Latest" : "")"
    }
}

struct VMInstaller {
    
    private var vm: VZVirtualMachine!
    private var localRestoreImageURL: URL? = nil
    
    /// Fetch all available macOS restore images
    static func fetchAvailableRestoreImages() async throws -> [RestoreImageInfo] {
        // Fetch the latest supported restore image
        let latestImage: VZMacOSRestoreImage = try await withCheckedThrowingContinuation { continuation in
            VZMacOSRestoreImage.fetchLatestSupported { result in
                switch result {
                case .success(let image):
                    continuation.resume(returning: image)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
        
        let restoreInfo = RestoreImageInfo(
            url: latestImage.url,
            buildVersion: latestImage.buildVersion,
            isLatest: true)
        return [restoreInfo]
    }
    
    /// Download and cache a specific restore image
    static func downloadRestoreImage(from restoreInfo: RestoreImageInfo) async throws -> (VZMacOSRestoreImage, URL) {
        return try await downloadRestoreImage(from: restoreInfo.url)
    }
    
    /// Download and cache a restore image from a specific URL
    static func downloadRestoreImage(from remoteURL: URL) async throws -> (VZMacOSRestoreImage, URL) {
        let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let cacheDir = appSupportDir.appendingPathComponent("MacBoxRestoreImages", isDirectory: true)
        try FileManager.default.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        let localRestoreImageURL = cacheDir.appendingPathComponent(remoteURL.lastPathComponent)

        if !FileManager.default.fileExists(atPath: localRestoreImageURL.path) {
            print("[VMInstaller] Local restore image missing; downloading to cache ...")
            let tempDownload = try await downloadWithRetry(from: remoteURL)
            if FileManager.default.fileExists(atPath: localRestoreImageURL.path) { try? FileManager.default.removeItem(at: localRestoreImageURL) }
            do {
                try FileManager.default.moveItem(at: tempDownload, to: localRestoreImageURL)
                print("[VMInstaller] Cached restore image at \(localRestoreImageURL.path)")
            } catch {
                throw NSError(domain: "VMInstaller", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to move downloaded IPSW into cache: \(error)"]) }
        } else {
            print("[VMInstaller] Using cached restore image: \(localRestoreImageURL.lastPathComponent)")
        }

        // IMPORTANT: Reload the restore image *from disk* so configuration derives from the cached IPSW (avoids mismatch)
        // Some SDK versions only expose the completion-handler API (no async variant). Bridge it to async.
        let localRestoreImage: VZMacOSRestoreImage = try await withCheckedThrowingContinuation { cont in
            VZMacOSRestoreImage.load(from: localRestoreImageURL) { result in
                switch result {
                case .success(let image):
                    cont.resume(returning: image)
                case .failure(let error):
                    cont.resume(throwing: error)
                }
            }
        }
        // Basic metadata for diagnostics
        if let attrs = try? FileManager.default.attributesOfItem(atPath: localRestoreImageURL.path),
           let fsize = attrs[.size] as? NSNumber {
            let mb = Double(truncating: fsize) / 1024.0 / 1024.0
            print("[VMInstaller] Restore image size: \(String(format: "%.2f MB", mb))")
        }
        if let variant = localRestoreImage.mostFeaturefulSupportedConfiguration {
            let hwDataCount = variant.hardwareModel.dataRepresentation.count
            print("[VMInstaller] Loaded local restore image; mostFeaturefulSupportedConfiguration available = true hwBytes=\(hwDataCount)")
        } else {
            print("[VMInstaller] Loaded local restore image; mostFeaturefulSupportedConfiguration = nil (unexpected)")
        }
        return (localRestoreImage, localRestoreImageURL)
    }
    
    /// Download the latest supported restore image (convenience method)
    static func downloadLatest() async throws -> (VZMacOSRestoreImage, URL) {
        guard let latest = try? await VZMacOSRestoreImage.latestSupported else {
            fatalError("No restore image is supported for this host.")
        }
        return try await downloadRestoreImage(from: latest.url)
    }
    
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
}
