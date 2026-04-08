import SwiftUI

// MARK: - ========== SharedComponents.swift ==========

// MARK: - StatChip (unifies DashboardStatPill, projectStatChip, contractStatChip, marketStatBadge)

struct StatChip: View {
    enum Style {
        case card       // Centered VStack, premiumGlow (Projects/Contracts stat chips)
        case dashboard  // Left-aligned VStack, outlined (DashboardStatPill)
        case badge      // Compact HStack, tinted background (MarketView stat badge)
    }

    let value: String
    let label: String
    let color: Color
    var style: Style = .card

    var body: some View {
        Group {
            switch style {
            case .card:
                VStack(spacing: 3) {
                    Text(value)
                        .font(.system(size: 20, weight: .heavy))
                        .foregroundColor(color)
                    Text(label)
                        .font(.system(size: 9, weight: .bold))
                        .tracking(2)
                        .foregroundColor(Theme.muted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Theme.surface)
                .cornerRadius(10)
                .premiumGlow(cornerRadius: 10, color: color)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(label): \(value)")

            case .dashboard:
                VStack(alignment: .leading, spacing: 4) {
                    Text(value)
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(color)
                    Text(label)
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(Theme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .background(Theme.surface.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.16), lineWidth: 1)
                )
                .cornerRadius(10)

            case .badge:
                HStack(spacing: 4) {
                    Text(value)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(color)
                    Text(label)
                        .font(.system(size: 10))
                        .foregroundColor(Theme.muted)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(color.opacity(0.10))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - TabHeader (unifies the header pattern across 9+ tab files)

struct TabHeader<TrailingContent: View>: View {
    let eyebrow: String
    let title: String
    let eyebrowColor: Color
    var subtitle: String? = nil
    var showDemoWarning: Bool = false
    var background: Color = Theme.surface
    var glowColor: Color? = nil
    @ViewBuilder var trailing: () -> TrailingContent

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(4)
                    .foregroundColor(eyebrowColor)
                Text(title)
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundColor(Theme.text)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Theme.muted)
                }
                if showDemoWarning {
                    Label("Demo data — configure Supabase in Integration Hub", systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.gold)
                }
            }
            Spacer()
            trailing()
        }
        .padding(16)
        .background(background)
        .cornerRadius(14)
        .premiumGlow(cornerRadius: 14, color: glowColor ?? eyebrowColor)
    }
}

extension TabHeader where TrailingContent == EmptyView {
    init(
        eyebrow: String,
        title: String,
        eyebrowColor: Color,
        subtitle: String? = nil,
        showDemoWarning: Bool = false,
        background: Color = Theme.surface,
        glowColor: Color? = nil
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.eyebrowColor = eyebrowColor
        self.subtitle = subtitle
        self.showDemoWarning = showDemoWarning
        self.background = background
        self.glowColor = glowColor
        self.trailing = { EmptyView() }
    }
}
