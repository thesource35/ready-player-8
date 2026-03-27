import SwiftUI

// MARK: - ========== ViewUtilities.swift ==========

// MARK: - Feedback Insight Row

struct FeedbackInsightRow: View {
    let insight: FeedbackInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(insight.title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Theme.gold)
            Text("Pain: \(insight.painPoint)")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Theme.muted)
            Text("Fix: \(insight.solution)")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Theme.text)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface.opacity(0.75))
        .cornerRadius(8)
    }
}

// MARK: - Risk Action Button

struct RiskActionButton: View {
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(color)
                .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edge Border Shape

struct EdgeBorderShape: Shape {
    let width: CGFloat
    let edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            switch edge {
            case .top:
                path.addRect(CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: width))
            case .bottom:
                path.addRect(CGRect(x: rect.minX, y: rect.maxY - width, width: rect.width, height: width))
            case .leading:
                path.addRect(CGRect(x: rect.minX, y: rect.minY, width: width, height: rect.height))
            case .trailing:
                path.addRect(CGRect(x: rect.maxX - width, y: rect.minY, width: width, height: rect.height))
            }
        }
        return path
    }
}

// MARK: - View Extensions

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorderShape(width: width, edges: edges).foregroundColor(color))
    }

    func premiumGlow(cornerRadius: CGFloat, color: Color) -> some View {
        shadow(color: color.opacity(0.18), radius: cornerRadius * 0.65, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.22), lineWidth: 0.8)
            )
    }
}
