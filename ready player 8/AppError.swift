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
    case uploadFailed(String)
    case fileTooLarge(maxMB: Int)
    case unsupportedFileType(String)
    // MARK: - Phase 22 Video cases (D-40)
    case unsupportedVideoFormat(details: String)      // server reject codec (D-31 server-side) OR client reject container
    case clipTooLong(maxMinutes: Int)                 // > 60 min (D-31)
    case clipTooLarge(maxGB: Int)                     // > 2 GB (D-31)
    case audioConsentRequired                         // D-35 jurisdiction warning
    case transcodeTimeout                             // > 10 min poll timeout, D-33 final failure
    case muxIngestFailed(reason: String)              // Mux API POST /live-streams failed (D-23 wizard)
    case muxDeleteFailed(reason: String)              // Mux API DELETE /live-streams/:id failed (D-29)
    case cameraLimitReached(cap: Int)                 // D-28 soft cap hit
    case webhookSignatureInvalid                      // D-32 HMAC reject path
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
        case .uploadFailed(let msg):
            return "Upload failed: \(msg)"
        case .fileTooLarge(let max):
            return "File exceeds \(max) MB limit"
        case .unsupportedFileType(let type):
            return "Unsupported file type: \(type)"
        case .unsupportedVideoFormat(let details):
            return "Unsupported file type or codec: \(details). Use MP4 or MOV with H.264, HEVC, or ProRes encoding."
        case .clipTooLong(let m):
            return "Clip is too long. Maximum length is \(m) minutes — please split the recording into shorter segments."
        case .clipTooLarge(let gb):
            return "File is too large. Clips must be \(gb) GB or smaller — try trimming the video or exporting at a lower bitrate."
        case .audioConsentRequired:
            return "Recording audio may require consent from everyone on site. Confirm you have consent before enabling, or leave audio off."
        case .transcodeTimeout:
            return "Transcode failed. Tap Retry, or re-upload the source file if the problem persists."
        case .muxIngestFailed(let reason):
            return "Couldn't reach Mux to create the camera. \(reason). Try again — nothing has been saved."
        case .muxDeleteFailed(let reason):
            return "Couldn't delete the Mux live input. \(reason). The camera wasn't removed — try again in a moment."
        case .cameraLimitReached(let cap):
            return "Camera limit reached (\(cap)). Archive an unused camera or contact support to raise the cap."
        case .webhookSignatureInvalid:
            return "Webhook signature verification failed."
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
        case .uploadFailed:
            return true
        case .muxIngestFailed, .muxDeleteFailed, .transcodeTimeout:
            return true
        case .unsupportedVideoFormat, .clipTooLong, .clipTooLarge,
             .audioConsentRequired, .cameraLimitReached, .webhookSignatureInvalid:
            return false
        default:
            return false
        }
    }

    var severity: AlertSeverity {
        switch self {
        case .offlineQueued: return .info
        case .validationFailed: return .warning
        case .unsupportedVideoFormat, .clipTooLong, .clipTooLarge,
             .audioConsentRequired, .cameraLimitReached:
            return .warning
        case .muxIngestFailed, .muxDeleteFailed, .transcodeTimeout, .webhookSignatureInvalid:
            return .error
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
