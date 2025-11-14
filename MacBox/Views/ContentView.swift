//
//  ContentView.swift
//  MacBox
//
//  Created by Tom on 2025/06/09.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vmManager = VMManager()
    @StateObject private var runtimeManager = VMRuntimeManager.shared
    @State private var selectedVM: VMConfig?
    @State private var showCreateVM = false
    @State private var isLaunching = false
    @State private var launchError: String?
    @State private var showLaunchError = false
    
    var body: some View {
        NavigationSplitView {
            // VM List Sidebar
            List(selection: $selectedVM) {
                ForEach(vmManager.vmList) { vm in
                    VMRowView(vm: vm, isRunning: runtimeManager.isRunning(id: vm.id))
                        .tag(vm)
                }
                .onDelete { indexSet in
                    indexSet.forEach { index in
                        vmManager.removeVM(vmManager.vmList[index])
                    }
                }
            }
            .navigationTitle("Virtual Machines")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCreateVM = true
                    } label: {
                        Label("Add VM", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateVM) {
                CreateVMView()
                    .environmentObject(vmManager)
            }
        } detail: {
            if let vm = selectedVM {
                VMDetailView(vm: vm) {
                    launchVM(vm)
                }
            } else {
                Text("Select a virtual machine")
                    .foregroundColor(.secondary)
            }
        }
        .alert("Launch Error", isPresented: $showLaunchError) {
            Button("OK") {}
        } message: {
            Text(launchError ?? "Failed to launch VM")
        }
    }
    
    private func launchVM(_ vm: VMConfig) {
        guard !isLaunching else { return }
        
        isLaunching = true
        Task {
            do {
                try await runtimeManager.launchVM(from: vm)
                await MainActor.run {
                    isLaunching = false
                }
            } catch {
                await MainActor.run {
                    launchError = error.localizedDescription
                    showLaunchError = true
                    isLaunching = false
                }
            }
        }
    }
}
