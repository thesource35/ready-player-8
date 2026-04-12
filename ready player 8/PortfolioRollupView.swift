import SwiftUI

// MARK: - ========== PortfolioRollupView.swift ==========
// Phase 19: Portfolio rollup view -- stub for Task 1 build.
// Task 2 will replace with full implementation including charts, filters, API fetch.

struct PortfolioRollupView: View {
    var body: some View {
        // Placeholder -- full implementation in Task 2
        VStack(spacing: 12) {
            Text("PORTFOLIO ROLLUP")
                .font(.system(size: 12, weight: .heavy))
                .tracking(2)
                .foregroundColor(Theme.green)
            Text("Loading portfolio data...")
                .font(.system(size: 12))
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}
