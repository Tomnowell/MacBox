import Foundation
import SwiftUI

// MARK: - String Extensions

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isNotEmpty: Bool {
        !isEmpty
    }

    func truncated(to length: Int) -> String {
        count > length ? String(prefix(length)) + "…" : self
    }
}

// MARK: - URL Extensions

extension URL {
    var isDirectory: Bool {
        (try? resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true
    }

    func appendingPath(_ component: String) -> URL {
        appendingPathComponent(component, isDirectory: false)
    }
}

// MARK: - Date Extensions

extension Date {
    func formatted(_ style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: self)
    }

    var shortTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

// MARK: - Optional Helpers

extension Optional {
    var isNil: Bool { self == nil }
    var isNotNil: Bool { self != nil }
}

// MARK: - SwiftUI Binding Helpers

extension Binding where Value: Equatable {
    func isEqual(to value: Value) -> Bool {
        self.wrappedValue == value
    }
}

extension Binding where Value == Bool {
    mutating func toggle() {
        self.wrappedValue.toggle()
    }
}

// MARK: - Collection Helpers

extension Collection {
    var isNotEmpty: Bool { !isEmpty }
}

// MARK: - DispatchQueue Helpers

extension DispatchQueue {
    static func mainAsync(_ execute: @escaping () -> Void) {
        if Thread.isMainThread {
            execute()
        } else {
            main.async { execute() }
        }
    }
}