import SwiftUI
import Combine

// MARK: - ========== LayoutChrome.swift ==========

// MARK: - Premium Background

struct PremiumBackgroundView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Theme.bg, Theme.surface.opacity(0.96), Theme.bg]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                gradient: Gradient(colors: [Theme.gold.opacity(0.24), .clear]),
                center: .topLeading,
                startRadius: 20,
                endRadius: 420
            )
            .offset(x: -120, y: -160)

            RadialGradient(
                gradient: Gradient(colors: [Theme.cyan.opacity(0.14), .clear]),
                center: .bottomTrailing,
                startRadius: 40,
                endRadius: 360
            )
            .offset(x: 120, y: 180)

            LinearGradient(
                gradient: Gradient(colors: [Theme.gold.opacity(0.04), .clear, Theme.cyan.opacity(0.05)]),
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(spacing: 120) {
                Capsule()
                    .fill(Theme.gold.opacity(0.08))
                    .frame(width: 280, height: 280)
                    .blur(radius: 90)
                    .offset(x: -140, y: -40)

                Capsule()
                    .fill(Theme.cyan.opacity(0.07))
                    .frame(width: 260, height: 260)
                    .blur(radius: 100)
                    .offset(x: 150, y: 80)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - Header View

struct HeaderView: View {
    // MARK: - Phase 14: Notifications header bell
    // ContentView injects this store via .environmentObject so the bell badge
    // updates live without HeaderView needing to be re-instantiated.
    @EnvironmentObject private var notificationsStore: NotificationsStore
    var onBellTap: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                LinearGradient(
                    gradient: Gradient(colors: [Theme.accent, Theme.gold]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 36, height: 36)
                .cornerRadius(8)
                .overlay(
                    Text("\u{2B21}")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(.black)
                )

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 3) {
                        Text("CONSTRUCT")
                            .font(.system(size: 17, weight: .heavy))
                            .tracking(2)
                            .foregroundColor(Theme.text)
                        Text("OS")
                            .font(.system(size: 17, weight: .heavy))
                            .tracking(2)
                            .foregroundColor(Theme.accent)
                    }
                    Text("GLOBAL CONSTRUCTION INTELLIGENCE")
                        .font(.system(size: 8, weight: .regular))
                        .tracking(2)
                        .foregroundColor(Theme.muted)
                }

                Spacer()

                Circle()
                    .fill(Theme.green)
                    .frame(width: 7, height: 7)

                Text("142,891")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.green)

                // MARK: - Phase 14: Header bell with unread badge
                Button(action: { onBellTap?() }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(Theme.text)
                            .font(.system(size: 14, weight: .semibold))
                            .frame(width: 30, height: 30)
                            .background(Theme.bg.opacity(0.4))
                            .cornerRadius(8)
                        if !notificationsStore.displayBadge.isEmpty {
                            Text(notificationsStore.displayBadge)
                                .font(.system(size: 9, weight: .heavy))
                                .foregroundColor(.black)
                                .padding(.horizontal, 4)
                                .frame(minWidth: 16, minHeight: 14)
                                .background(Capsule().fill(Theme.accent))
                                .offset(x: 4, y: -4)
                        }
                    }
                }
                .accessibilityLabel("Notifications, \(notificationsStore.unreadCount) unread")

                Button(action: { NotificationCenter.default.post(name: .init("ConstructOS.NavToProjects"), object: nil) }) {
                    Text("NEW PROJECT")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .frame(height: 36)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Theme.accent, Theme.gold]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(8)
                }
                    .frame(minWidth: 112)
            }
            .padding(14)
            .background(Theme.surface)
            .border(width: 1, edges: [.bottom], color: Theme.border)
        }
    }
}

// MARK: - Navigation Tabs

struct NavigationTabsView: View {
    @Binding var activeNav: ContentView.NavTab
    let navItems: [(String, String, String, String)]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(navItems.enumerated()), id: \.element.0) { index, item in
                    let (id, label, icon, group) = item
                    // Group separator
                    if index > 0 && group != navItems[index - 1].3 {
                        Rectangle().fill(Theme.border.opacity(0.4)).frame(width: 1, height: 36).padding(.horizontal, 2)
                    }
                    Button(action: {
                        if let tab = ContentView.NavTab(rawValue: id) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                activeNav = tab
                            }
                        }
                    }) {
                        VStack(spacing: 4) {
                            Text(icon)
                                .font(.system(size: 16, weight: .bold))

                            Text(label)
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1)
                                .lineLimit(1)
                        }
                        .foregroundColor(activeNav.rawValue == id ? .black : Theme.text)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 60)
                        .background(
                            Group {
                                if activeNav.rawValue == id {
                                    LinearGradient(
                                        gradient: Gradient(colors: [Theme.accent, Theme.gold]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                } else {
                                    Theme.panel.opacity(0.88)
                                }
                            }
                        )
                        .cornerRadius(14)
                        .shadow(color: activeNav.rawValue == id ? Theme.green.opacity(0.18) : .clear, radius: 14, x: 0, y: 6)
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(Theme.surface)
    }
}

struct NavigationRailView: View {
    @Binding var activeNav: ContentView.NavTab
    let navItems: [(String, String, String, String)]
    @State private var hoveredNav: String?

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(navItems.enumerated()), id: \.element.0) { index, item in
                let (id, label, icon, group) = item
                // Group separator with label
                if index > 0 && group != navItems[index - 1].3 {
                    HStack(spacing: 6) {
                        Rectangle().fill(Theme.border.opacity(0.3)).frame(height: 1)
                        Text(group.uppercased())
                            .font(.system(size: 8, weight: .bold)).tracking(2)
                            .foregroundColor(Theme.muted)
                        Rectangle().fill(Theme.border.opacity(0.3)).frame(height: 1)
                    }
                    .padding(.vertical, 4)
                }
                Button(action: {
                    if let tab = ContentView.NavTab(rawValue: id) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            activeNav = tab
                        }
                    }
                }) {
                    HStack(spacing: 10) {
                        Text(icon)
                            .font(.system(size: 15, weight: .bold))
                            .frame(width: 18)

                        Text(label)
                            .font(.system(size: 11, weight: .bold))
                            .tracking(1)

                        Spacer()
                    }
                    .foregroundColor(activeNav.rawValue == id ? .black : Theme.text)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 48)
                    .background(
                        Group {
                            if activeNav.rawValue == id {
                                LinearGradient(
                                    gradient: Gradient(colors: [Theme.accent, Theme.gold]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            } else if hoveredNav == id {
                                Theme.panel.opacity(0.96)
                            } else {
                                Theme.panel.opacity(0.85)
                            }
                        }
                    )
                    .cornerRadius(11)
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)
                .onHover { hovering in
                    hoveredNav = hovering ? id : nil
                }
            }

            Spacer()
        }
        .padding(12)
        .frame(maxHeight: .infinity)
    }
}

struct SidebarStatusView: View {
    @Binding var pulse: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Theme.green)
                .frame(width: 8, height: 8)
                .opacity(pulse ? 1 : 0.35)
                .animation(.easeInOut(duration: 0.9).repeatForever(), value: pulse)
                .onAppear { pulse = true }

            Text("SYSTEMS LIVE")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.2)
                .foregroundColor(Theme.green)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Theme.surface)
        .border(width: 1, edges: [.top], color: Theme.border)
    }
}

// MARK: - Footer View

struct FooterView: View {
    @Binding var pulse: Bool

    var body: some View {
        HStack(spacing: 20) {
            HStack(spacing: 3) {
                Text("CONSTRUCT")
                    .font(.system(size: 15, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.text)
                Text("OS")
                    .font(.system(size: 15, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(Theme.accent)
            }

            Spacer()

            HStack(spacing: 6) {
                Circle()
                    .fill(Theme.green)
                    .frame(width: 7, height: 7)
                    .opacity(pulse ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.9).repeatForever(), value: pulse)
                    .onAppear { pulse = true }

                Text("ALL SYSTEMS OPERATIONAL")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(Theme.green)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.surface)
        .border(width: 1, edges: [.top], color: Theme.border)
    }
}

// MARK: - Ticker View

struct TickerView: View {
    @State private var tickerIndex = 0
    private let tickerTimer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    let all = (tickerItems + tickerItems)

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .center, spacing: 0) {
                Text("\u{1F534} LIVE")
                    .font(.system(size: 10, weight: .heavy))
                    .tracking(1)
                    .foregroundColor(.white)
            }
            .frame(width: 76, height: 34)
            .background(Color.black)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(0..<all.count, id: \.self) { i in
                            Text(all[i])
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.black)
                                .padding(.horizontal, 20)
                                .lineLimit(1)
                                .id(i)
                        }
                    }
                    .frame(height: 34)
                }
                .onAppear {
                    proxy.scrollTo(0, anchor: .leading)
                }
                .onReceive(tickerTimer) { _ in
                    let next = (tickerIndex + 1) % all.count
                    withAnimation(.linear(duration: 1.1)) {
                        tickerIndex = next
                        proxy.scrollTo(next, anchor: .leading)
                    }
                }
            }
        }
        .frame(height: 34)
        .background(Theme.accent)
    }
}
