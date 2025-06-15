//
//  VMRowView.swift
//  MacBox
//
//  Created by Tom on 2025/06/09.
//

import SwiftUI

struct VMRowView: View {
    let vmConfig: VMConfig
    var isRunning: Bool {
        VMRuntimeManager.shared.isRunning(id: vmConfig.id)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(vmConfig.name)
                    .font(.headline)
                Text(vmConfig.osType)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            /*
            if isRunning {
                Button(action: {
                    VMRuntimeManager.shared.stopVM(id: vmConfig.id)
                }) {
                    Image(systemName: "play.circle.fill")
                        .foregroundColor(.green)
                        .help("Running (Click to pause)")
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    VMRuntimeManager.shared.launchVM(from: vmConfig)
                }) {
                    Image(systemName: "stop.circle")
                        .foregroundColor(.gray)
                        .help("Stopped (Click to start)")
                }
                .buttonStyle(.plain)
            }*/
        }
    .padding(.vertical, 4)
    }
}
