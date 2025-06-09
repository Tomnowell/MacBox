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

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedVM) {
                ForEach(vmManager.vmList) { vm in
                VMRowView(vm: vm)
                    .tag(vm)
                }
            }
            .frame(minWidth: 200)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button("+") {
                        showingCreateSheet = true
                    }
                }
            }
        } detail: {
            if let vm = selectedVM {
                VMDetailView(vmConfig: vm)
            } else {
                Text("Select a VM")
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            CreateVMView()
        }
    }
}
