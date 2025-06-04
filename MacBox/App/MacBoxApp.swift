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
        }
        .windowStyle(DefaultWindowStyle())
    }
}





