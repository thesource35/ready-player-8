import Foundation
import SwiftUI

// MARK: - ========== AppStorageJSON.swift ==========

/// Load a Codable value from UserDefaults (AppStorage-compatible key).
/// Returns `defaultValue` if key is empty or decoding fails.
/// Logs decode failures via CrashReporter instead of silently returning default.
func loadJSON<T: Decodable>(_ key: String, default defaultValue: T) -> T {
    guard let raw = UserDefaults.standard.string(forKey: key),
          let data = raw.data(using: .utf8) else {
        return defaultValue
    }
    do {
        return try JSONDecoder().decode(T.self, from: data)
    } catch {
        CrashReporter.shared.reportError("AppStorageJSON decode failed for key '\(key)': \(error.localizedDescription)")
        return defaultValue
    }
}

/// Persist a Codable value to UserDefaults as a JSON string (AppStorage-compatible).
/// Logs a warning via CrashReporter if data exceeds 1MB (UserDefaults practical limit).
func saveJSON<T: Encodable>(_ key: String, value: T) {
    do {
        let data = try JSONEncoder().encode(value)
        let sizeBytes = data.count
        let oneMB = 1_000_000
        if sizeBytes > oneMB {
            CrashReporter.shared.reportError(
                "AppStorage key '\(key)' exceeds 1MB (\(sizeBytes / 1024)KB). Data may be truncated or lost by UserDefaults."
            )
        } else if sizeBytes > oneMB * 3 / 4 {
            // Warn at 75% threshold so developers can act before hitting the limit
            #if DEBUG
            print("[AppStorageJSON] Warning: key '\(key)' at \(sizeBytes / 1024)KB — approaching 1MB limit")
            #endif
        }
        UserDefaults.standard.set(String(data: data, encoding: .utf8) ?? "", forKey: key)
    } catch {
        CrashReporter.shared.reportError("AppStorageJSON encode failed for key '\(key)': \(error.localizedDescription)")
    }
}
