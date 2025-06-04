import SwiftData
import Testing
import Foundation
@testable import MacBox

// Actor to safely share a SwiftData model container between tests
actor TestModelContainer {
    static let shared = TestModelContainer()

    private let container: ModelContainer

    init() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("ItemTest.sqlite")
        try? FileManager.default.removeItem(at: tempURL)

        let schema = Schema([Item.self])
        let config = ModelConfiguration(schema: schema, url: tempURL)
        self.container = try! ModelContainer(for: schema, configurations: [config])
    }
    
    @MainActor
    func getContext() -> ModelContext {
        container.mainContext
    }
}

// Tests for the Item model using SwiftData and the Testing library
struct ItemTests {

    @Test @MainActor
    func testInsertItem() async throws {
        let context = await TestModelContainer.shared.getContext()
        _ = try? context.fetch(FetchDescriptor<Item>(predicate: #Predicate { _ in false }))

        let item = Item(timestamp: Date())
        context.insert(item)

        let fetched = try context.fetch(FetchDescriptor<Item>())
        #expect(fetched.contains { $0.id == item.id }, "Inserted item should be retrievable")
    }

    @Test @MainActor
    func testDeleteItem() async throws {
        let context = await TestModelContainer.shared.getContext()

        let item = Item(timestamp: Date())
        context.insert(item)
        context.delete(item)

        let fetched = try context.fetch(FetchDescriptor<Item>())
        #expect(!fetched.contains { $0.id == item.id }, "Deleted item should not be retrievable")
    }

    @Test @MainActor
    func testFetchMultipleItems() async throws {
        let context = await TestModelContainer.shared.getContext()

        let item1 = Item(timestamp: Date())
        let item2 = Item(timestamp: Date().addingTimeInterval(60))
        context.insert(item1)
        context.insert(item2)

        let fetched = try context.fetch(FetchDescriptor<Item>())
        #expect(fetched.count >= 2, "Should fetch at least two items")
        #expect(fetched.contains { $0.id == item1.id })
        #expect(fetched.contains { $0.id == item2.id })
    }
}
