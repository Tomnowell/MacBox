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

    func launchVM(from config: VMConfig) {
        do {
            let configuration = try VZConfigurationBuilder.build(from: config)
            let vm = VZVirtualMachine(configuration: configuration)

            runningVMs[config.id] = vm

            vm.start { result in
                switch result {
                case .success:
                    print("VM '\(config.name)' started.")
                case .failure(let error):
                    print("Failed to start VM '\(config.name)': \(error)")
                    self.runningVMs.removeValue(forKey: config.id)
                }
            }
        } catch {
            print("Failed to build VM configuration: \(error)")
        }
    }

    func stopVM(id: UUID) {
        guard let vm = runningVMs[id] else { return }

        vm.stop { error in
            if let error = error {
                print("Failed to stop VM: \(error)")
            } else {
                print("VM stopped successfully.")
                self.runningVMs.removeValue(forKey: id)
            }
        }
    }

    func isRunning(id: UUID) -> Bool {
        runningVMs[id] != nil
    }
}
