import Foundation
import SwiftUI

// MARK: - ========== AppStorageJSON.swift ==========

/// Load a Codable value from UserDefaults (AppStorage-compatible key).
/// Returns `defaultValue` if key is empty or decoding fails.
func loadJSON<T: Decodable>(_ key: String, default defaultValue: T) -> T {
    guard let raw = UserDefaults.standard.string(forKey: key),
          let data = raw.data(using: .utf8),
          let decoded = try? JSONDecoder().decode(T.self, from: data) else {
        return defaultValue
    }
    return decoded
}

/// Persist a Codable value to UserDefaults as a JSON string (AppStorage-compatible).
func saveJSON<T: Encodable>(_ key: String, value: T) {
    if let data = try? JSONEncoder().encode(value) {
        UserDefaults.standard.set(String(data: data, encoding: .utf8) ?? "", forKey: key)
    }
}
