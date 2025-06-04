//
//  WarmUpSwiftDataSchema.swift
//  MacBox
//
//  Created by Tom on 2025/06/03.
//

// SchemaWarmUp.swift
import SwiftData

@MainActor
func warmUpSwiftDataSchema() {
    do {
        let container = try ModelContainer(
            for: Item.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        _ = try container.mainContext.fetch(FetchDescriptor<Item>())
    } catch {
        print("⚠️ SwiftData schema warm-up failed: \(error)")
    }
}
