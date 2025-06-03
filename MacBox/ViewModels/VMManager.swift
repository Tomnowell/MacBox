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

    func removeVM(_ vm: VMConfig) {
        vmList.removeAll { $0.id == vm.id }
    }
}

