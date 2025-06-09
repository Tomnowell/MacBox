//
//  VMRowView.swift
//  MacBox
//
//  Created by Tom on 2025/06/09.
//

import SwiftUI

struct VMRowView: View {
    let vm: VMConfig
    var isRunning: Bool {
        VMRuntimeManager.shared.isRunning(id: vm.id)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.name)
                    .font(.headline)
                Text(vm.osType)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isRunning {
                Image(systemName: "play.circle.fill")
                    .foregroundColor(.green)
                    .help("Running")
            } else {
                Image(systemName: "pause.circle")
                    .foregroundColor(.gray)
                    .help("Stopped")
            }
        }
        .padding(.vertical, 4)
    }
}