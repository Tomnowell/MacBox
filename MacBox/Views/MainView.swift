//
//  MainView.swift
//  MacBox
//
//  Created by Tom on 2025/06/02.
//

// Views/MainView.swift
import SwiftUI

struct MainView: View {
    @EnvironmentObject var vmManager: VMManager
    @State private var selectedVM: VMConfig?
    @State private var showingCreateSheet = false
    @State private var vmToDelete: VMConfig?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedVM) {
                ForEach(vmManager.vmList) { vmConfig in
                    VMRowView(vm: vmConfig, isRunning: VMRuntimeManager.shared.isRunning(id: vmConfig.id))
                        .tag(vmConfig)
                        .contextMenu {
                            Button("Delete VM", role: .destructive) {
                                vmToDelete = vmConfig
                            }
                        }
                }
                .onDelete(perform: deleteVMs)
            }
            .frame(minWidth: 200)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button("+") {
                        showingCreateSheet = true
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Clear All") {
                        vmManager.clearAllVMs()
                    }
                }
            }
        } detail: {
            if let vmConfig = selectedVM {
                VMDetailView(vm: vmConfig) {
                    Task {
                        do {
                            try await VMRuntimeManager.shared.launchVM(from: vmConfig)
                        } catch {
                            print("Failed to launch VM: \(error)")
                        }
                    }
                }
            } else {
                Text("Select a VM")
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateVMView()
        }
        .alert("Delete VM", isPresented: Binding(
            get: { vmToDelete != nil },
            set: { if !$0 { vmToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let vm = vmToDelete {
                    vmManager.removeVM(vm)
                    if selectedVM?.id == vm.id {
                        selectedVM = nil
                    }
                    vmToDelete = nil
                }
            }
        } message: {
            if let vm = vmToDelete {
                Text("Are you sure you want to delete '\(vm.name)'? This will remove all associated files and cannot be undone.")
            }
        }
    }
    
    private func deleteVMs(offsets: IndexSet) {
        for index in offsets {
            let vm = vmManager.vmList[index]
            vmManager.removeVM(vm)
            if selectedVM?.id == vm.id {
                selectedVM = nil
            }
        }
    }
}
