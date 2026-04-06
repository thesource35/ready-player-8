// AppError.swift — Centralized error types and alert state
// ConstructionOS

import Foundation
import SwiftUI
import Combine

// MARK: - Unified Error Type

enum AppError: LocalizedError, Identifiable {
    case network(underlying: Error)
    case supabaseNotConfigured
    case supabaseHTTP(statusCode: Int, body: String)
    case decoding(underlying: Error)
    case encoding(underlying: Error)
    case authFailed(reason: String)
    case validationFailed(field: String, reason: String)
    case offlineQueued
    case biometricFailed
    case permissionDenied(feature: String)
    case unknown(String)

    var id: String { localizedDescription }

    var errorDescription: String? {
        switch self {
        case .network(let error):
            return "Network error: \(error.localizedDescription)"
        case .supabaseNotConfigured:
            return "Supabase not configured. Enter your Base URL and API key in COMMAND → Integration Hub."
        case .supabaseHTTP(let code, let body):
            return "Server error (\(code)): \(body)"
        case .decoding(let error):
            return "Data parsing error: \(error.localizedDescription)"
        case .encoding(let error):
            return "Data encoding error: \(error.localizedDescription)"
        case .authFailed(let reason):
            return "Authentication failed: \(reason)"
        case .validationFailed(let field, let reason):
            return "\(field): \(reason)"
        case .offlineQueued:
            return "Saved offline — will sync when connected."
        case .biometricFailed:
            return "Biometric authentication failed."
        case .permissionDenied(let feature):
            return "\(feature) requires permission."
        case .unknown(let msg):
            return msg
        }
    }

    var isRetryable: Bool {
        switch self {
        case .network:
            return true
        case .supabaseHTTP(let code, _):
            return code >= 500
        default:
            return false
        }
    }

    var severity: AlertSeverity {
        switch self {
        case .offlineQueued: return .info
        case .validationFailed: return .warning
        default: return .error
        }
    }
}

// MARK: - Alert Severity

enum AlertSeverity {
    case info, warning, error

    var iconName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }

    var color: Color {
        switch self {
        case .info: return Theme.cyan
        case .warning: return Theme.gold
        case .error: return Theme.red
        }
    }
}

// MARK: - Alert State Manager

@MainActor
final class AlertState: ObservableObject {
    @Published var currentError: AppError?
    @Published var showAlert = false
    @Published var successMessage: String?

    func show(_ error: AppError) {
        currentError = error
        showAlert = true
    }

    func showError(_ message: String) {
        show(.unknown(message))
    }

    func showSuccess(_ message: String) {
        successMessage = message
        Task {
            try? await Task.sleep(for: .seconds(3))
            await MainActor.run { successMessage = nil }
        }
    }

    func dismiss() {
        showAlert = false
        currentError = nil
    }
}

// MARK: - Error Alert View Modifier

struct ErrorAlertModifier: ViewModifier {
    @ObservedObject var alertState: AlertState

    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $alertState.showAlert, presenting: alertState.currentError) { error in
                Button("OK") { alertState.dismiss() }
                if error.isRetryable {
                    Button("Retry") { alertState.dismiss() }
                }
            } message: { error in
                Text(error.localizedDescription)
            }
            .overlay(alignment: .top) {
                if let success = alertState.successMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Theme.green)
                        Text(success)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.green)
                    }
                    .padding(10)
                    .background(Theme.green.opacity(0.08))
                    .cornerRadius(8)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .animation(.easeInOut, value: alertState.successMessage)
                }
            }
    }
}

extension View {
    func withErrorAlert(_ alertState: AlertState) -> some View {
        modifier(ErrorAlertModifier(alertState: alertState))
    }
}
