//
//  Item.swift
//  MacBox
//
//  Created by Tom on 2025/06/02.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
