import SwiftUI

// MARK: - ========== ToastManager.swift ==========

@Observable
@MainActor
final class ToastManager {
    static let shared = ToastManager()

    private(set) var message: String?

    private init() {}

    func show(_ text: String, duration: TimeInterval = 3) {
        message = text
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            if message == text { message = nil }
        }
    }

    func dismiss() {
        message = nil
    }
}

struct ToastOverlay: View {
    let message: String?

    var body: some View {
        if let message {
            VStack {
                Spacer()
                Text(message)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Theme.surface.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
                    .padding(.bottom, 80)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: message)
        }
    }
}
