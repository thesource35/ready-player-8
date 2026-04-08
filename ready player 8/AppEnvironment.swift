// AppEnvironment.swift — Dependency injection container
// ConstructionOS

import SwiftUI
import Combine

@MainActor
final class AppEnvironment: ObservableObject {
    // Services
    let apiClient: APIClientProtocol
    @Published var supabase: SupabaseService
    @Published var analytics: AnalyticsEngine
    @Published var crashReporter: CrashReporter

    /// Convenience singleton for backward compat during migration
    /// Views should prefer @EnvironmentObject injection
    static let shared = AppEnvironment()

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
        self.supabase = SupabaseService.shared
        self.analytics = AnalyticsEngine.shared
        self.crashReporter = CrashReporter.shared
    }

    /// Testing initializer with mock services
    init(
        apiClient: APIClientProtocol,
        supabase: SupabaseService,
        analytics: AnalyticsEngine,
        crashReporter: CrashReporter
    ) {
        self.apiClient = apiClient
        self.supabase = supabase
        self.analytics = analytics
        self.crashReporter = crashReporter
    }
}

// MARK: - View Extension for easy injection

extension View {
    func withAppEnvironment(_ env: AppEnvironment = .shared) -> some View {
        self
            .environmentObject(env)
            .environmentObject(env.supabase)
            .environmentObject(env.analytics)
            .environmentObject(env.crashReporter)
    }
}
