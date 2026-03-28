import SwiftUI

// MARK: - Auth Gate View

struct AuthGateView: View {
    @ObservedObject var supabase = SupabaseService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var error: String?
    @State private var isLoading = false

    var body: some View {
        ZStack {
            PremiumBackgroundView()
            VStack(spacing: 20) {
                Spacer()
                HStack(spacing: 6) {
                    Text("CONSTRUCT").font(.system(size: 28, weight: .heavy)).tracking(2).foregroundColor(Theme.text)
                    Text("OS").font(.system(size: 28, weight: .heavy)).tracking(2).foregroundColor(Theme.accent)
                }
                Text(isSignUp ? "CREATE ACCOUNT" : "SIGN IN")
                    .font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.muted)

                VStack(spacing: 12) {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .font(.system(size: 14)).foregroundColor(Theme.text)
                        .padding(12).background(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                        .cornerRadius(8)
                    #if os(iOS)
                    SecureField("Password", text: $password)
                        .textContentType(isSignUp ? .newPassword : .password)
                        .font(.system(size: 14)).foregroundColor(Theme.text)
                        .padding(12).background(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                        .cornerRadius(8)
                    #else
                    SecureField("Password", text: $password)
                        .font(.system(size: 14)).foregroundColor(Theme.text)
                        .padding(12).background(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                        .cornerRadius(8)
                    #endif
                }
                .frame(maxWidth: 320)

                if let error {
                    Text(error).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.red)
                        .multilineTextAlignment(.center).frame(maxWidth: 320)
                }

                Button {
                    guard !email.isEmpty, !password.isEmpty else { error = "Email and password required"; return }
                    isLoading = true; error = nil
                    Task {
                        do {
                            if isSignUp { try await supabase.signUp(email: email, password: password) }
                            else { try await supabase.signIn(email: email, password: password) }
                        } catch { await MainActor.run { self.error = error.localizedDescription } }
                        await MainActor.run { isLoading = false }
                    }
                } label: {
                    Group {
                        if isLoading {
                            ProgressView().tint(.black)
                        } else {
                            Text(isSignUp ? "CREATE ACCOUNT" : "SIGN IN")
                                .font(.system(size: 13, weight: .bold)).tracking(1)
                        }
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: 320).frame(height: 44)
                    .background(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)

                Button(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up") {
                    isSignUp.toggle(); error = nil
                }
                .font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.cyan)

                Button("Skip (use without account)") {
                    supabase.accessToken = "skip"
                    supabase.currentUserEmail = "local"
                }
                .font(.system(size: 11)).foregroundColor(Theme.muted)

                Spacer()
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
    }
}

struct ContentView: View {
    @StateObject private var actionLog = RiskActionLogStore()
    @ObservedObject private var supabase = SupabaseService.shared
    @State private var activeNav: NavTab = .home
    @State private var pulse = false

    enum NavTab: String, CaseIterable {
        case home = "home"; case projects = "projects"; case contracts = "contracts"
        case market = "market"; case maps = "maps"; case network = "network"
        case ops = "ops"; case hub = "hub"; case security = "security"
        case pricing = "pricing"; case angelic = "angelic"; case wealth = "wealth"
        case cosNetwork = "cos-network"
        case rentals = "rentals"
        case electrical = "electrical"
        case tax = "tax"
        case field = "field"
        case finance = "finance"
        case compliance = "compliance"
        case clientPortal = "client-portal"
        case analytics = "analytics"
        case schedule = "schedule"
        case training = "training"
        case scanner = "scanner"
        case tech = "tech"
        case punchPro = "punch-pro"
        case roofEstimate = "roof-estimate"
        case smartBuild = "smart-build"
        case contractors = "contractors"
        case settings = "settings"
    }

    private let navItems: [(String, String, String, String)] = [
        ("home","COMMAND","\u{2318}","core"),("projects","PROJECTS","\u{1F3D7}","core"),
        ("contracts","CONTRACTS","\u{1F4CB}","core"),("market","MARKET","\u{1F4CA}","core"),
        ("maps","MAPS","\u{1F5FA}","core"),("network","NETWORK","\u{1F4E1}","core"),
        ("ops","OPS","\u{2699}\u{FE0F}","intel"),("hub","HUB","\u{1F50C}","intel"),
        ("security","SECURITY","\u{1F512}","intel"),("pricing","PRICING","\u{1F4B2}","intel"),
        ("angelic","ANGELIC","\u{1F47C}","intel"),("wealth","WEALTH","\u{1F48E}","wealth"),
        ("cos-network","COS NET","\u{1F310}","wealth"),
        ("rentals","RENTALS","\u{1F6E0}","wealth"),
        ("electrical","ELECTRIC","\u{26A1}","trade"),
        ("tax","TAX","\u{1F4B0}","trade"),
        ("field","FIELD","\u{1F4F1}","field"),
        ("finance","FINANCE","\u{1F4B5}","field"),
        ("compliance","COMPLY","\u{1F6E1}","field"),
        ("client-portal","CLIENTS","\u{1F465}","field"),
        ("analytics","ANALYTICS","\u{1F4C8}","field"),
        ("schedule","SCHEDULE","\u{1F4C5}","plan"),
        ("training","TRAINING","\u{1F393}","plan"),
        ("scanner","SCANNER","\u{1F4F7}","plan"),
        ("tech","TECH 2026","\u{1F916}","tech"),
        ("punch-pro","PUNCH","\u{2705}","build"),
        ("roof-estimate","ROOFING","\u{1F3E0}","build"),
        ("smart-build","BUILD AI","\u{1F3D7}","build"),
        ("contractors","DIRECTORY","\u{1F4D6}","build"),
        ("settings","SETTINGS","\u{2699}\u{FE0F}","settings"),
    ]

    @State private var wealthTab: WealthSubTab = .moneyLens
    enum WealthSubTab: String, CaseIterable {
        case moneyLens = "Money Lens"; case psychology = "Psychology"
        case power = "Power Thinking"; case leverage = "Leverage"; case opportunity = "Opportunity"
    }

    @State private var showSearch = false
    @State private var biometricUnlocked = false
    @AppStorage("ConstructOS.OnboardingComplete") private var onboardingComplete = false

    var body: some View {
        Group {
            if !onboardingComplete {
                OnboardingView(isComplete: $onboardingComplete)
            } else if !supabase.isAuthenticated && supabase.isConfigured {
                AuthGateView(supabase: supabase)
            } else if BiometricAuthManager.shared.biometricEnabled && !biometricUnlocked {
                BiometricLockScreen(isUnlocked: $biometricUnlocked)
            } else {
                mainAppView
            }
        }
        .onAppear {
            supabase.restoreSession()
            supabase.loadPendingWrites()
            Task {
                await supabase.flushPendingWrites()
                await NotificationManager.shared.requestAuthorization()
            }
            if supabase.isConfigured { supabase.startRealtimeSync() }
            SpotlightIndexer.shared.indexProjects(mockProjects)
            SpotlightIndexer.shared.indexRentalItems(rentalInventory)
        }
        .onChange(of: activeNav) { _, _ in HapticEngine.tap() }
        .onOpenURL { url in
            if let tab = DeepLinkHandler.handleURL(url) { activeNav = tab }
        }
        .sheet(isPresented: $showSearch) {
            GlobalSearchView(isPresented: $showSearch)
        }
    }

    private var mainAppView: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > 800
            ZStack {
                PremiumBackgroundView()
                VStack(spacing: 0) {
                    HeaderView()
                    OfflineIndicatorBar(pendingCount: supabase.pendingWrites.count)
                    TickerView()
                    if isWide {
                        HStack(spacing: 0) {
                            VStack(spacing: 0) {
                                ScrollView { NavigationRailView(activeNav: $activeNav, navItems: navItems) }
                                SidebarStatusView(pulse: $pulse)
                            }.frame(width: 180).background(Theme.surface)
                            .border(width: 1, edges: [.trailing], color: Theme.border)
                            ScrollView { activeTabContent.padding(16) }
                        }
                    } else {
                        NavigationTabsView(activeNav: $activeNav, navItems: navItems)
                        ScrollView { activeTabContent.padding(16) }
                    }
                    FooterView(pulse: $pulse)
                }
            }
        }
        .preferredColorScheme(.dark)
        .environmentObject(actionLog)
        .onReceive(NotificationCenter.default.publisher(for: .init("ConstructOS.NavToProjects"))) { _ in
            activeNav = .projects
        }
    }

    @ViewBuilder
    private var activeTabContent: some View {
        switch activeNav {
        case .home:
            VStack(alignment: .leading, spacing: 14) {
                SiteRiskScorePanel(); WeatherRiskPanel(); SiteStatusDashboard()
                CrewDeployBoard(); InspectionPermitTracker(); StandupReportPanel()
            }
        case .projects: ProjectsView()
        case .contracts: ContractsView()
        case .market: MarketView()
        case .maps: MapsView()
        case .network: NetworkView()
        case .ops:
            VStack(alignment: .leading, spacing: 14) {
                OperationsCommandCenterPanel(); ChangeOrderTrackerPanel()
                SafetyIncidentPanel(); MaterialDeliveryPanel()
                PunchListPanel(); SubcontractorScorecardPanel()
                DailyCostTrackerPanel(); SubmittalLogPanel()
                ProjectContractAccountPanel(); ExecutivePortfolioPanel()
                RFITrackerPanel(); BudgetBurnPanel()
            }
        case .hub: PlatformIntegrationPanel()
        case .security: SecurityAccessPanel()
        case .pricing: AIPricingDashboardView()
        case .angelic: AngelicAIView()
        case .wealth:
            VStack(alignment: .leading, spacing: 14) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(WealthSubTab.allCases, id: \.self) { tab in
                            Button(action: { wealthTab = tab }) {
                                Text(tab.rawValue.uppercased())
                                    .font(.system(size: 10, weight: .bold)).tracking(1)
                                    .foregroundColor(wealthTab == tab ? .black : Theme.text)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(wealthTab == tab ? Theme.gold : Theme.surface)
                                    .cornerRadius(8)
                            }.buttonStyle(.plain)
                        }
                    }
                }
                switch wealthTab {
                case .moneyLens: MoneyLensView()
                case .psychology: PsychologyDecoderView()
                case .power: PowerThinkingView()
                case .leverage: LeverageSystemView()
                case .opportunity: OpportunityFilterView()
                }
            }
        case .cosNetwork: ConstructionOSNetworkPanel()
        case .rentals: RentalSearchView()
        case .electrical: ElectricalFiberView()
        case .tax: TaxAccountantView()
        case .field: FieldOpsView()
        case .finance: FinanceHubView()
        case .compliance: ComplianceView()
        case .clientPortal: ClientPortalView()
        case .analytics: AnalyticsDashboardView()
        case .schedule: ScheduleHubView()
        case .training: TrainingCertView()
        case .scanner: ScannerToolsView()
        case .tech: ConstructionTech2026View()
        case .punchPro: PunchListProView()
        case .roofEstimate: SatelliteRoofEstimatorView()
        case .smartBuild: SmartBuildHubView()
        case .contractors: GlobalContractorDirectoryView()
        case .settings: SettingsProfileView()
        }
    }
}
