import SwiftUI

// MARK: - ========== PricingView.swift ==========

// MARK: - Pricing View

struct PricingView: View {
    private let projectManagementTools = [
        "Lead and client pipeline tracking",
        "Selections and approvals",
        "Project scheduling",
        "To-dos and daily logs",
        "Unlimited document and photo storage",
        "Photo and PDF annotation",
        "Electronic signatures",
        "Client and subcontractor portals",
        "Geo-aware time tracking",
        "RFI management",
        "Warranties"
    ]

    private let financialManagementTools = [
        "Takeoff",
        "Estimates",
        "Bids",
        "Proposals",
        "Bills and purchase orders",
        "Change orders",
        "Budgeting",
        "Client invoicing",
        "Online client and subcontractor payments",
        "Accounting integrations",
        "Financial reporting"
    ]

    private let outcomeHighlights = [
        "Put labor visibility closer to the work with jobsite-first time tracking.",
        "Let project managers issue, assign, and close punch items with less friction.",
        "Keep critical project information accessible in the field, not buried in back-office tools.",
        "Align office teams, clients, and trade partners around one live operating picture.",
        "Standardize daily documentation so decisions, risks, and progress are captured as they happen."
    ]

    private let platformSignals: [(String, String, Color)] = [
        ("FIELD RHYTHM", "Work stays connected to labor, logs, punch, and live issues.", Theme.cyan),
        ("COMMERCIAL DISCIPLINE", "Budgets, billing, and change activity stay tied to execution.", Theme.green),
        ("LEADERSHIP SIGNAL", "Portfolio-level visibility stays clean enough to drive action.", Theme.gold)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("CONSTRUCTION OPERATING SYSTEM")
                            .font(.system(size: 10, weight: .bold))
                            .tracking(4)
                            .foregroundColor(Theme.accent)

                        Text("Operate with control.\nScale with confidence.")
                            .font(.system(size: 34, weight: .heavy))
                            .foregroundColor(Theme.text)

                        Text("A unified system for preconstruction, project delivery, financial control, and field execution. Give leadership better visibility, give project teams cleaner workflows, and give every job a stronger command structure from pursuit through closeout.")
                            .font(.system(size: 14, weight: .regular))
                            .lineSpacing(2)
                            .foregroundColor(Theme.muted)

                        HStack(spacing: 10) {
                            pricingStat(value: "Tighter", label: "handoffs + approvals", color: Theme.gold)
                            pricingStat(value: "Fewer", label: "misses + delays", color: Theme.cyan)
                            pricingStat(value: "Clearer", label: "margin + accountability", color: Theme.green)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(platformSignals, id: \.0) { signal in
                            PricingBadge(title: signal.0, description: signal.1, color: signal.2)
                        }
                    }
                    .frame(width: 260)
                }
                .padding(22)
                .background(Theme.panel)
                .premiumGlow(cornerRadius: 18, color: Theme.gold)

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(
                            eyebrow: "WHY IT STICKS",
                            title: "Why teams standardize on it",
                            detail: "Instead of splitting execution across disconnected tools, teams operate from one coordinated system for planning, reporting, approvals, cost control, and field communication."
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(spacing: 10) {
                        ForEach(outcomeHighlights, id: \.self) { item in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(Theme.accent)
                                    .frame(width: 7, height: 7)
                                    .padding(.top, 5)
                                Text(item)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(Theme.text)
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(18)
                .background(Theme.panel)
                .premiumGlow(cornerRadius: 16, color: Theme.cyan)

                VStack(alignment: .leading, spacing: 12) {
                    SectionHeading(
                        eyebrow: "PLATFORM COVERAGE",
                        title: "Tools that run the job from pursuit to closeout",
                        detail: "Operational and financial workflows stay connected so execution quality and margin control reinforce each other."
                    )

                    HStack(alignment: .top, spacing: 12) {
                        capabilityColumn(
                            title: "PROJECT MANAGEMENT TOOLS",
                            subtitle: "Control schedule, coordination, documentation, and field execution from one workflow.",
                            items: projectManagementTools,
                            accent: Theme.accent
                        )

                        capabilityColumn(
                            title: "FINANCIAL MANAGEMENT TOOLS",
                            subtitle: "Protect margin with better estimating discipline, budget visibility, and billing control.",
                            items: financialManagementTools,
                            accent: Theme.green
                        )
                    }
                }
                .padding(18)
                .background(Theme.panel)
                .premiumGlow(cornerRadius: 16, color: Theme.accent)

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(
                            eyebrow: "EXECUTION IMPACT",
                            title: "Operational discipline that compounds",
                            detail: "Faster approvals, cleaner documentation, stronger field accountability, and better visibility for both internal teams and external stakeholders."
                        )
                    }
                    .frame(width: 250, alignment: .leading)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        FeatureCardSmall(icon: "\u{1F4C1}", title: "Operational Clarity", desc: "Schedules, documents, photos, and field notes live in one controlled workflow", color: Theme.gold)
                        FeatureCardSmall(icon: "\u{1F91D}", title: "Stakeholder Trust", desc: "Approvals, signatures, and communication move through a disciplined client-ready experience", color: Theme.cyan)
                        FeatureCardSmall(icon: "\u{1F6E0}", title: "Field Accountability", desc: "Labor, tasks, punch, and reporting stay anchored to the work in place", color: Theme.green)
                        FeatureCardSmall(icon: "\u{1F4B5}", title: "Commercial Control", desc: "Estimates, budgets, change events, and billing stay connected to execution", color: Theme.accent)
                    }
                }
                .padding(18)
                .background(Theme.panel)
                .premiumGlow(cornerRadius: 16, color: Theme.purple)
            }
            .padding(16)
        }
        .background(Theme.bg)
    }

    private func pricingStat(value: String, label: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.system(size: 18, weight: .heavy))
                .foregroundColor(color)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Theme.surface.opacity(0.78))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
        .cornerRadius(10)
    }

    private func capabilityColumn(title: String, subtitle: String, items: [String], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .black))
                .tracking(2)
                .foregroundColor(accent)

            Text(subtitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Theme.muted)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\u{2022}")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(accent)
                        Text(item)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(Theme.text)
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Theme.surface.opacity(0.74))
        .premiumGlow(cornerRadius: 16, color: accent)
    }
}
