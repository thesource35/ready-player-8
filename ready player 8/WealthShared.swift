import Foundation
import SwiftUI

// MARK: - ========== WealthShared.swift ==========

// MARK: - Colors (defined in Theme struct, aliased here for convenience)

let wealthGold = Theme.wealthGold
let wealthGradientSurface = Theme.wealthGradientSurface

// MARK: - Models

struct MoneyPrinciple { let title: String; let body: String; let color: Color }
struct MoneyReframe { let old: String; let new: String }
struct WealthArchetype { let name: String; let minScore: Int; let description: String; let traits: [String]; let color: Color }
struct LimitingBeliefItem { let belief: String; let reframe: String }
struct ThinkingMode { let name: String; let description: String; let usage: String; let color: Color; let icon: String }
struct YesFilterGate { let gate: String; let question: String }
struct SecondOrderItem { let decision: String; let first: String; let second: String }
struct LeverageCategory: Identifiable { let id: String; let name: String; let description: String; let icon: String; let defaultScore: Double }
struct LeverageFormula { let icon: String; let formula: String; let description: String }
struct OpportunityCriterion: Identifiable { let id: String; let label: String; let icon: String; let color: Color }

struct WealthOpportunity: Identifiable, Codable {
    let id: UUID
    let name: String
    let scores: [String: Int]
    let createdAt: Date
    var contractId: String?
    var status: String = "active"

    var wealthSignal: Int {
        guard !scores.isEmpty else { return 0 }
        return scores.values.reduce(0, +) / scores.count
    }
    var signalLabel: String {
        switch wealthSignal {
        case 80...100: return "HIGH SIGNAL"
        case 60..<80:  return "MEDIUM SIGNAL"
        case 40..<60:  return "WEAK SIGNAL"
        default:       return "NO-GO"
        }
    }
    var signalColor: Color {
        switch wealthSignal {
        case 80...100: return Theme.green
        case 60..<80:  return Theme.gold
        case 40..<60:  return Theme.gold.opacity(0.7)
        default:       return Theme.red
        }
    }
}

struct DecisionJournalEntry: Identifiable, Codable {
    let id: UUID
    var title: String
    var context: String
    var thinkingMode: String
    var decision: String
    var firstOrder: String
    var secondOrder: String
    var gatesPassed: Int
    var outcomeStatus: String
    let createdAt: Date
    var reviewedAt: Date?
}

struct WealthTrackingEntry: Identifiable, Codable {
    let id: UUID
    var date: String
    var revenue: Double
    var expenses: Double
    var notes: String
    let createdAt: Date

    var margin: Double { revenue > 0 ? (revenue - expenses) / revenue * 100 : 0 }
    var profit: Double { revenue - expenses }
}

struct PsychologySession: Identifiable, Codable {
    let id: UUID
    var score: Double
    var profileLabel: String
    let createdAt: Date
}

struct LeverageSnapshot: Identifiable, Codable {
    let id: UUID
    var scores: [String: Double]
    var totalScore: Double
    let createdAt: Date
}

// MARK: - Static Data

let moneyLensPrinciples = [
    MoneyPrinciple(title: "Every hour has a market rate", body: "Know your hourly wealth-creation rate. Anything below it must be delegated, automated, or eliminated.", color: Theme.gold),
    MoneyPrinciple(title: "Revenue is vanity, margin is sanity", body: "A $500K job at 8% margin destroys more wealth than a $200K job at 35%. Filter by margin first.", color: Theme.green),
    MoneyPrinciple(title: "Speed of money is a multiplier", body: "Faster payment cycles = more capital rotations per year = exponential compounding. Negotiate 10/30 net terms.", color: Theme.cyan),
    MoneyPrinciple(title: "Expertise commands pricing power", body: "Specialists charge 3–10x generalists. Narrow your niche, deepen your moat, raise your price.", color: Theme.purple),
]

let moneyReframes = [
    MoneyReframe(old: "I need to take every job to keep cash flow", new: "I only take jobs that accelerate my wealth trajectory"),
    MoneyReframe(old: "That project is too expensive to pursue", new: "What is the ROI on winning this contract?"),
    MoneyReframe(old: "I can't afford to hire right now", new: "I can't afford NOT to hire — my time is the bottleneck"),
    MoneyReframe(old: "The market is too competitive", new: "The market is full of undifferentiated competitors — my gap is wide open"),
]

let wealthArchetypes = [
    WealthArchetype(name: "The Builder", minScore: 0, description: "Building foundational wealth systems. Focus on cash flow and margin before scale.", traits: ["Cash flow first", "Debt averse", "Single market"], color: Theme.muted),
    WealthArchetype(name: "The Accumulator", minScore: 40, description: "Converting income into assets. Starting to leverage OPM and OPT.", traits: ["Asset acquisition", "First hires", "Margin discipline"], color: Theme.cyan),
    WealthArchetype(name: "The Multiplier", minScore: 60, description: "Deploying leverage at scale. Systems generating income independent of personal time.", traits: ["Systems thinker", "Leverage stacker", "Portfolio view"], color: Theme.purple),
    WealthArchetype(name: "The Architect", minScore: 80, description: "Operating as a wealth architect. Capital allocation + network effects compound automatically.", traits: ["Capital allocator", "Network leverage", "Exits + reinvestment"], color: wealthGold),
]

let limitingBeliefs = [
    LimitingBeliefItem(belief: "Rich people are greedy", reframe: "Wealth is a tool — its ethics are determined by how you deploy it"),
    LimitingBeliefItem(belief: "I have to work harder to make more", reframe: "Leverage allows you to earn more while working less"),
    LimitingBeliefItem(belief: "I'm not the type who gets wealthy", reframe: "Wealth follows a system, not a personality type"),
    LimitingBeliefItem(belief: "It's too late for me to build serious wealth", reframe: "The best decade to build wealth is always the current one"),
    LimitingBeliefItem(belief: "I'll start investing when I have more money", reframe: "The vehicle for wealth is built with the money you have today"),
]

let identityStatements = [
    "I am a builder of systems that generate wealth without my direct time.",
    "I attract high-margin opportunities because I lead with rare value.",
    "Money flows into my business as a result of the problems I solve at scale.",
    "I make decisions from abundance, not from fear of scarcity.",
    "My wealth expands because I consistently invest in the highest-leverage activities.",
    "I am worthy of financial freedom and I am building it deliberately.",
]

let thinkingModes = [
    ThinkingMode(name: "Strategic", description: "Zoom out to 10,000 ft. What is the destination? What are the critical path moves?", usage: "Quarterly planning, major bids, market pivots", color: Theme.gold, icon: "🗺"),
    ThinkingMode(name: "Leverage", description: "Identify the 20% of actions producing 80% of outcomes. Amplify them.", usage: "Weekly priorities, resource allocation", color: Theme.cyan, icon: "🔱"),
    ThinkingMode(name: "Visionary", description: "Suspend constraints. Design the future you want, then reverse engineer the path.", usage: "Annual vision, new market entry", color: Theme.purple, icon: "✦"),
    ThinkingMode(name: "Execution", description: "Convert vision to daily action. Specific, time-bound, accountable.", usage: "Daily task design, project delivery", color: Theme.green, icon: "⚡"),
]

let powerQuestions = [
    "What is the highest-leverage action I can take in the next 90 minutes?",
    "If this decision compounds over 5 years, what does my world look like?",
    "What would I do if I knew I couldn't fail?",
    "Who has already solved this problem and how can I absorb their model?",
    "What am I tolerating that is costing me money, energy, or forward momentum?",
    "What is the ONE constraint holding back 10x growth in this business?",
    "How can I 10x the price and 10x the value simultaneously?",
]

let yesFilterGates = [
    YesFilterGate(gate: "Margin Gate", question: "Is the gross margin above 25%? If no, restructure or decline."),
    YesFilterGate(gate: "Time Gate", question: "Can this run primarily without my direct time within 90 days?"),
    YesFilterGate(gate: "Scale Gate", question: "Does this create assets, systems, or relationships that compound?"),
    YesFilterGate(gate: "Energy Gate", question: "Does this energize me or drain me? Sustained excellence requires energy alignment."),
    YesFilterGate(gate: "Alignment Gate", question: "Does this advance the 3-year financial vision or distract from it?"),
    YesFilterGate(gate: "Risk Gate", question: "Is the downside survivable and bounded? Asymmetric risk only."),
    YesFilterGate(gate: "Relationship Gate", question: "Does the client, partner, or team elevate my standard or lower it?"),
]

let secondOrderExamples = [
    SecondOrderItem(
        decision: "Underbid to win a large project",
        first: "Win the contract, cash flow increases short-term",
        second: "Margin compression trains the market on low prices; attracts more low-margin work; team burnout follows"
    ),
    SecondOrderItem(
        decision: "Delay hiring until you're overwhelmed",
        first: "Preserve cash, maintain control",
        second: "Top talent is hired by competition; your growth ceiling is your personal bandwidth; burnout caps execution"
    ),
    SecondOrderItem(
        decision: "Invest in systems and SOPs now",
        first: "Short-term cost and time to build",
        second: "Team executes without you; margin improves; business becomes sellable or scale-ready in 24 months"
    ),
]

let leverageCategories: [LeverageCategory] = [
    LeverageCategory(id: "financial", name: "Financial Leverage", description: "Using debt, credit, and capital structures to amplify returns on equity", icon: "💵", defaultScore: 40),
    LeverageCategory(id: "operational", name: "Operational Leverage", description: "Systems, SOPs, and processes that scale output without scaling headcount proportionally", icon: "⚙️", defaultScore: 35),
    LeverageCategory(id: "network", name: "Network Leverage", description: "Relationships, referrals, and reputation generating deal flow without paid acquisition", icon: "🔗", defaultScore: 50),
    LeverageCategory(id: "knowledge", name: "Knowledge Leverage", description: "Expertise and specialization commanding a premium that generalists cannot match", icon: "📚", defaultScore: 55),
    LeverageCategory(id: "technology", name: "Technology Leverage", description: "Software, AI, and automation compressing time and eliminating low-leverage tasks", icon: "⚡", defaultScore: 30),
]

let leverageFormulas = [
    LeverageFormula(icon: "💵", formula: "Financial: OPM × ROI = Wealth Velocity", description: "Other People's Money deployed at superior returns creates wealth faster than earned income alone."),
    LeverageFormula(icon: "⚙️", formula: "Operational: Systems × Volume = Margin at Scale", description: "Every process you document and delegate frees capacity for higher-leverage work."),
    LeverageFormula(icon: "🔗", formula: "Network: Trust × Reach = Deal Flow", description: "Your network is a compounding asset. One referral partner can outperform a full sales team."),
    LeverageFormula(icon: "📚", formula: "Knowledge: Depth × Scarcity = Pricing Power", description: "The narrower your specialty and the shallower the talent pool, the higher your hourly wealth rate."),
    LeverageFormula(icon: "⚡", formula: "Technology: Automation × Scale = Asymmetric Output", description: "Tools that eliminate $50/hr tasks free you to operate exclusively in $500/hr territory."),
]

let leveragePlaybook = [
    "Identify lowest-scoring leverage category. Map three friction points costing money or time. Eliminate one.",
    "Build or buy one system that runs without you. Document one SOP. Make one strategic hire or delegation move.",
    "Activate network leverage. Identify top 5 referral sources. Create a structured follow-up rhythm.",
    "Deploy technology lever. Implement one AI or automation tool that saves 5+ hours per week.",
]

let opportunityCriteria: [OpportunityCriterion] = [
    OpportunityCriterion(id: "margin", label: "Margin", icon: "💹", color: Theme.green),
    OpportunityCriterion(id: "scale", label: "Scalability", icon: "📈", color: Theme.cyan),
    OpportunityCriterion(id: "speed", label: "Cash Speed", icon: "⚡", color: wealthGold),
    OpportunityCriterion(id: "expertise", label: "Expertise Fit", icon: "🎯", color: Theme.purple),
    OpportunityCriterion(id: "relationship", label: "Relationship", icon: "🤝", color: Theme.accent),
    OpportunityCriterion(id: "timing", label: "Market Timing", icon: "⏱", color: Theme.red),
]

let highIncomePrinciples = [
    "Only pursue opportunities where your expertise commands a meaningful premium over market rate.",
    "High income is a byproduct of high value delivered to a market willing and able to pay.",
    "Your next income level requires a version of you that doesn't exist yet — invest in that version now.",
    "Most high-income opportunities are concentrated in a few high-leverage moves. Find them.",
    "The fastest path to high income is solving expensive problems for people with money.",
    "Raise your prices before you feel ready. You're almost certainly undercharging.",
]

let mindsetQuestions: [(String, [String])] = [
    ("When you see a highly profitable competitor, your first thought is:", [
        "They got lucky or cut corners", "I can learn from their model", "I'll outperform them in 12 months",  "I should partner with or acquire them"
    ]),
    ("Your biggest project finishes 30% over budget. You:", [
        "Absorb the loss and move on", "Blame the client or subs", "Conduct a full margin autopsy and systematize the fix", "Fire the PM and rebuild the team"
    ]),
    ("A premium client offers a contract at 40% margin but requires new capabilities. You:", [
        "Pass — too risky", "Take it and figure it out as you go", "Negotiate scope to match current strength", "Invest in the capability specifically to win it"
    ]),
    ("How do you think about debt?", [
        "Terrifying — avoid at all costs", "Necessary evil for equipment", "A tool — deploy only for high-ROI assets", "Leverage engine — maximize use for compounding returns"
    ]),
    ("When a top employee asks for a raise you can't easily afford, you:", [
        "Tell them the budget doesn't allow it", "Give a token increase to keep them", "Calculate their true ROI and pay accordingly", "Create a performance structure that funds itself"
    ]),
    ("Your pricing strategy is:", [
        "Match or slightly beat competitors", "Cover cost plus a margin", "Based on the value I deliver to the client", "Premium — I'm building a brand that commands highest rates"
    ]),
    ("Your ideal business in 5 years runs:", [
        "Exactly like it does now", "With a few more employees", "Primarily through systems and a strong leadership team", "Across multiple markets with me as capital allocator"
    ]),
    ("When evaluating risk, you primarily consider:", [
        "What could go wrong and avoid it", "Whether the odds are in my favor", "The ratio of upside to bounded downside", "Whether the risk builds asymmetric optionality"
    ]),
    ("When someone on your team underperforms, your instinct is:", [
        "Tolerate it to avoid conflict", "Do the work yourself", "Create accountability systems and clear expectations", "Upgrade the role with a hire who raises the bar"
    ]),
    ("Your relationship with delegation is:", [
        "I can't trust anyone to do it right", "I delegate admin but keep the real work", "I delegate everything that isn't in my zone of genius", "I architect systems where delegation is automatic"
    ]),
    ("When a client tries to negotiate your price down, you:", [
        "Usually agree to keep the relationship", "Split the difference", "Hold firm and explain the value differential", "Walk away — price integrity protects brand positioning"
    ]),
    ("Your daily energy goes primarily toward:", [
        "Putting out fires and reacting", "Executing today's task list", "Building systems that eliminate future fires", "Strategic moves that compound over years"
    ]),
    ("When you think about your revenue ceiling, you believe:", [
        "It's mostly determined by the market", "I can push it slowly over time", "My ceiling is a function of my current systems", "There is no ceiling — only my thinking constrains it"
    ]),
    ("When you have unexpected cash surplus, you:", [
        "Save it for a rainy day", "Reward yourself — you earned it", "Reinvest in the highest-leverage growth area", "Allocate across growth, reserve, and strategic bets"
    ]),
    ("Your definition of financial freedom is:", [
        "Not worrying about bills", "Comfortable retirement someday", "Passive income exceeding expenses within 5 years", "Building generational wealth and permanently leaving the time-for-money trap"
    ]),
]

// MARK: - Shared Sub-views

struct WealthSectionHeader: View {
    let icon: String; let title: String; let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(icon).font(.system(size: 18))
                Text(title).font(.system(size: 10, weight: .bold)).tracking(3).foregroundColor(wealthGold)
            }
            Text(subtitle).font(.system(size: 12)).foregroundColor(Theme.muted)
        }
    }
}

struct WealthLensLabel: View {
    let text: String
    var body: some View {
        Text(text).font(.system(size: 9, weight: .bold)).tracking(2).foregroundColor(Theme.muted)
    }
}

struct WealthMetricCard: View {
    let value: String; let label: String; let delta: String; let color: Color; let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon).font(.system(size: 12)).foregroundColor(color)
                Spacer()
                Text(delta).font(.system(size: 9, weight: .bold)).foregroundColor(color)
            }
            Text(value).font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text)
            Text(label).font(.system(size: 10)).foregroundColor(Theme.muted)
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
        .premiumGlow(cornerRadius: 10, color: color)
    }
}

struct AllocationQuadrant: View {
    let label: String; let value: String; let color: Color; let detail: String
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 16, weight: .heavy)).foregroundColor(color)
            Text(label).font(.system(size: 9, weight: .bold)).tracking(0.3).foregroundColor(Theme.text).multilineTextAlignment(.center)
            Text(detail).font(.system(size: 8)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.10))
        .cornerRadius(8)
    }
}

struct CriteriaLegendChip: View {
    let criterion: OpportunityCriterion
    var body: some View {
        VStack(spacing: 3) {
            Text(criterion.icon).font(.system(size: 16))
            Text(criterion.label).font(.system(size: 9, weight: .bold)).tracking(0.3).foregroundColor(Theme.text).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(criterion.color.opacity(0.10))
        .cornerRadius(8)
    }
}

struct MoneyLensCard: View {
    let principle: MoneyPrinciple
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle().fill(principle.color).frame(width: 3).cornerRadius(2)
            VStack(alignment: .leading, spacing: 4) {
                Text(principle.title).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                Text(principle.body).font(.system(size: 11)).foregroundColor(Theme.muted)
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
        .premiumGlow(cornerRadius: 10, color: principle.color)
    }
}

struct WealthArchetypeCard: View {
    let archetype: WealthArchetype
    let isActive: Bool
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Circle()
                    .fill(isActive ? archetype.color : Theme.border.opacity(0.3))
                    .frame(width: 12, height: 12)
                if isActive {
                    Rectangle().fill(archetype.color.opacity(0.4)).frame(width: 2).frame(maxHeight: .infinity)
                }
            }
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(archetype.name)
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundColor(isActive ? archetype.color : Theme.muted)
                    if isActive { Text("ACTIVE").font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(archetype.color).padding(.horizontal, 6).padding(.vertical, 2).background(archetype.color.opacity(0.12)).cornerRadius(3) }
                    Spacer()
                    Text("Score \(archetype.minScore)+").font(.system(size: 9)).foregroundColor(Theme.muted)
                }
                Text(archetype.description).font(.system(size: 11)).foregroundColor(isActive ? Theme.muted : Theme.muted.opacity(0.5))
                HStack(spacing: 6) {
                    ForEach(archetype.traits, id: \.self) { trait in
                        Text(trait).font(.system(size: 9)).foregroundColor(isActive ? archetype.color : Theme.muted.opacity(0.4))
                            .padding(.horizontal, 6).padding(.vertical, 3).background(isActive ? archetype.color.opacity(0.10) : Theme.surface).cornerRadius(4)
                    }
                }
            }
        }
        .padding(12)
        .background(isActive ? Theme.surface : Theme.panel.opacity(0.4))
        .cornerRadius(10)
        .premiumGlow(cornerRadius: 10, color: isActive ? archetype.color : Color.clear)
    }
}

struct LimitingBeliefRow: View {
    let item: LimitingBeliefItem
    @State private var expanded = false
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button { withAnimation { expanded.toggle() } } label: {
                HStack {
                    Image(systemName: "xmark.circle").font(.system(size: 12)).foregroundColor(Theme.red)
                    Text(item.belief).font(.system(size: 12)).foregroundColor(Theme.text).multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.system(size: 10)).foregroundColor(Theme.muted)
                }
            }
            .accessibilityLabel(expanded ? "Collapse belief details" : "Expand belief details")
            .buttonStyle(.plain)
            if expanded {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 12)).foregroundColor(Theme.green)
                    Text(item.reframe).font(.system(size: 11, weight: .medium)).foregroundColor(Theme.green.opacity(0.9))
                }
                .padding(8).background(Theme.green.opacity(0.08)).cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
    }
}

struct ThinkingModeCard: View {
    let mode: ThinkingMode
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(mode.icon).font(.system(size: 16))
                Text(mode.name.uppercased()).font(.system(size: 10, weight: .bold)).tracking(1).foregroundColor(mode.color)
            }
            Text(mode.description).font(.system(size: 11)).foregroundColor(Theme.muted)
            Text(mode.usage).font(.system(size: 9)).foregroundColor(mode.color).italic()
        }
        .padding(12).background(Theme.surface).cornerRadius(10)
        .premiumGlow(cornerRadius: 10, color: mode.color)
    }
}

struct PowerQuestionRow: View {
    let number: Int; let question: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number)").font(.system(size: 11, weight: .heavy)).foregroundColor(wealthGold).frame(width: 18)
            Text(question).font(.system(size: 12)).foregroundColor(Theme.text)
        }
        .padding(.vertical, 2)
    }
}

struct SecondOrderRow: View {
    let item: SecondOrderItem
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.decision).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
            HStack(alignment: .top, spacing: 6) {
                Text("1st").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.gold).frame(width: 22)
                Text(item.first).font(.system(size: 11)).foregroundColor(Theme.muted)
            }
            HStack(alignment: .top, spacing: 6) {
                Text("2nd").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.red).frame(width: 22)
                Text(item.second).font(.system(size: 11)).foregroundColor(Theme.muted)
            }
        }
        .padding(10).background(Theme.panel.opacity(0.5)).cornerRadius(8)
    }
}

struct LeverageSliderRow: View {
    let category: LeverageCategory
    @Binding var score: Double
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(category.icon).font(.system(size: 14))
                Text(category.name).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                Spacer()
                Text("\(Int(score))").font(.system(size: 14, weight: .heavy)).foregroundColor(leverageColor(score))
                Text("/ 100").font(.system(size: 10)).foregroundColor(Theme.muted)
            }
            Text(category.description).font(.system(size: 10)).foregroundColor(Theme.muted)
            Slider(value: $score, in: 0...100, step: 5)
                .accentColor(leverageColor(score))
        }
        .padding(.vertical, 4)
    }
    private func leverageColor(_ s: Double) -> Color {
        switch s {
        case 70...100: return Theme.green
        case 40..<70:  return wealthGold
        default:       return Theme.red
        }
    }
}

struct OpportunityResultCard: View {
    let opportunity: WealthOpportunity
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(opportunity.name).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.text)
                    Text(opportunity.createdAt, style: .date).font(.system(size: 10)).foregroundColor(Theme.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("\(opportunity.wealthSignal)").font(.system(size: 26, weight: .heavy)).foregroundColor(opportunity.signalColor)
                    Text(opportunity.signalLabel).font(.system(size: 8, weight: .bold)).tracking(1).foregroundColor(opportunity.signalColor)
                        .padding(.horizontal, 6).padding(.vertical, 2).background(opportunity.signalColor.opacity(0.12)).cornerRadius(3)
                }
            }
            HStack(spacing: 8) {
                ForEach(opportunityCriteria, id: \.id) { c in
                    if let score = opportunity.scores[c.id] {
                        VStack(spacing: 2) {
                            Text(c.icon).font(.system(size: 12))
                            Text("\(score)").font(.system(size: 10, weight: .bold)).foregroundColor(c.color)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(c.color.opacity(0.08))
                        .cornerRadius(6)
                    }
                }
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .premiumGlow(cornerRadius: 12, color: opportunity.signalColor)
    }
}

// MARK: - Wealth Score Ring

struct WealthScoreRing: View {
    let score: Double
    let label: String
    let color: Color
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.2), lineWidth: size > 60 ? 6 : 3).frame(width: size, height: size)
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(color, style: StrokeStyle(lineWidth: size > 60 ? 6 : 3, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
            VStack(spacing: size > 60 ? 2 : 1) {
                Text("\(Int(score))").font(.system(size: size * 0.28, weight: .heavy)).foregroundColor(color)
                Text(label).font(.system(size: max(size * 0.09, 7), weight: .bold)).tracking(1).foregroundColor(Theme.muted)
            }
        }
    }
}

// MARK: - Shared Helpers

func psychologyProfileLabel(for score: Double) -> String {
    switch score {
    case 80...100: return "Abundance Builder"
    case 60..<80:  return "Strategic Accumulator"
    case 40..<60:  return "Growth-In-Progress"
    case 20..<40:  return "Scarcity Pattern Active"
    default:       return "Uncalibrated — Run Decoder"
    }
}

func psychologyProfileDescription(for score: Double) -> String {
    switch score {
    case 80...100: return "Operating from abundance. Money flows to you as a natural consequence of value creation."
    case 60..<80:  return "Mostly growth-oriented. Minor scarcity patterns surface under pressure — identify and eliminate them."
    case 40..<60:  return "Mixed signals. Wealth-building potential is high but internal friction is costing you deals and energy."
    case 20..<40:  return "Scarcity patterns are actively limiting your ceiling. Reprogramming required before scaling."
    default:       return "Tap 'Run Decoder' to calibrate your wealth psychology profile and unlock your personalized blueprint."
    }
}

func leverageLabel(_ score: Double) -> String {
    switch score {
    case 80...100: return "Maximum Leverage"
    case 60..<80:  return "Strong Leverage Position"
    case 40..<60:  return "Building Leverage"
    case 20..<40:  return "Underleveraged"
    default:       return "Leverage Deficit"
    }
}

func leverageDescription(_ score: Double) -> String {
    switch score {
    case 80...100: return "You're operating the billionaire way — systems and assets working while you sleep."
    case 60..<80:  return "Good foundation. Identify the lowest-scoring leverage category and double down."
    case 40..<60:  return "Time is your scarcest resource. Prioritize building systems over delivering time."
    default:       return "High income requires high leverage. Start with one category and move the needle 10 points."
    }
}

func computePsychologyScore(from answers: [Int: Int]) -> Double {
    guard !answers.isEmpty else { return 0 }
    let total = answers.values.reduce(0, +)
    let max = answers.count * 4
    return Double(total) / Double(max) * 100
}
