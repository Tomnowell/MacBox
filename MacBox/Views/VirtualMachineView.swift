//
//  VirtualMachineView.swift
//  MacBox
//
//  Created by Tom on 2025/06/27.
//


import SwiftUI
import Virtualization

struct VirtualMachineView: NSViewRepresentable {
    let virtualMachine: VZVirtualMachine

    func makeNSView(context: Context) -> VZVirtualMachineView {
        print("makeNSView called, assigning VM: \(virtualMachine)")
        let vmView = VZVirtualMachineView()
        vmView.virtualMachine = virtualMachine
        return vmView
    }

    func updateNSView(_ nsView: VZVirtualMachineView, context: Context) {
        print("updateNSView called, re-assigning VM: \(virtualMachine)")
        nsView.virtualMachine = virtualMachine
    }
}
