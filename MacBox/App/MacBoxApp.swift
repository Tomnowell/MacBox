//
//  MacBoxApp.swift
//  MacBox
//
//  Created by Tom on 2025/06/02.
//

import SwiftUI
import SwiftData

@main
struct MacBoxApp: App {
    @StateObject private var vmManager = VMManager()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .environmentObject(vmManager)
                .frame(minWidth: 1450, minHeight: 800)
        }
        .windowStyle(DefaultWindowStyle())
        .defaultSize(width: 1600, height: 900)
        .commands {
            CommandGroup(replacing: .windowSize) {}
        }
    }
}
