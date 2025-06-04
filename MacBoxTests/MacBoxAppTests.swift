import Testing
import SwiftUI

@testable import MacBox

struct MacBoxAppTests {
    
    @MainActor
    @Test
    func testVMManagerIsInitialized() async throws {
        let app = await MacBoxApp()
        // Access the private StateObject via Mirror for testing
        let mirror = Mirror(reflecting: app)
        let vmManagerChild = mirror.children.first { $0.label == "_vmManager" }
        #expect(vmManagerChild != nil, "MacBoxApp should have a _vmManager property")
    }

}
