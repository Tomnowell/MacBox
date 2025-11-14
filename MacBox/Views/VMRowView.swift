//
//  VMRowView.swift
//  MacBox
//
//  Created by Tom on 2025/06/09.
//

import SwiftUI

struct VMRowView: View {
    let vm: VMConfig
    let isRunning: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(vm.name)
                    .font(.headline)
                Text("\(vm.cpuCount) cores, \(vm.memorySizeMB) MB RAM, \(vm.diskSizeGB) GB")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isRunning {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
    }
}
