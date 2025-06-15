//
//  VMRuntimeManager.swift
//  MacBox
//
//  Created by Tom on 2025/06/09.
//

import Virtualization
import Foundation

@MainActor
final class VMRuntimeManager: ObservableObject {
    static let shared = VMRuntimeManager()

    @Published private(set) var runningVMs: [UUID: VZVirtualMachine] = [:]

    private init() {}

    func launchVM(from config: VMConfig) async throws {
        let configuration = try await VZConfigurationBuilder.build(from: config)
        let vm = VZVirtualMachine(configuration: configuration)
        runningVMs[config.id] = vm

        try await withCheckedThrowingContinuation { continuation in
            vm.start { result in
                switch result {
                case .success:
                    print("VM '\(config.name)' started.")
                    continuation.resume()
                case .failure(let error):
                    print("Failed to start VM '\(config.name)': \(error)")
                    self.runningVMs.removeValue(forKey: config.id)
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func stopVM(id: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let vm = runningVMs[id] else {
            completion(.failure(NSError(domain: "VMRuntimeManager", code: 404, userInfo: [NSLocalizedDescriptionKey: "VM not found."])))
            return
        }

        vm.stop { error in
            if let error = error {
                print("Failed to stop VM: \(error)")
                completion(.failure(error))
            } else {
                print("VM stopped successfully.")
                self.runningVMs.removeValue(forKey: id)
                completion(.success(()))
            }
        }
    }

    func isRunning(id: UUID) -> Bool {
        runningVMs[id] != nil
    }
}

