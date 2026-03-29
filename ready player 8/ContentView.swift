import SwiftUI

// MARK: - Auth Gate View (Procore-style with 2FA)

enum AuthStep { case login, signup, twoFactor, forgotPassword, companySelect }

struct AuthGateView: View {
    @ObservedObject var supabase = SupabaseService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var company = ""
    @State private var jobTitle = ""
    @State private var phone = ""
    @State private var twoFactorCode = ""
    @State private var step: AuthStep = .login
    @State private var error: String?
    @State private var isLoading = false
    @State private var rememberMe = true
    @State private var show2FASetup = false

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.03, green: 0.05, blue: 0.08).ignoresSafeArea()

            // Subtle gradient orbs
            RadialGradient(colors: [Theme.accent.opacity(0.08), .clear], center: .topTrailing, startRadius: 50, endRadius: 400)
                .ignoresSafeArea()
            RadialGradient(colors: [Theme.cyan.opacity(0.05), .clear], center: .bottomLeading, startRadius: 50, endRadius: 350)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer().frame(height: 60)

                    // Logo
                    VStack(spacing: 12) {
                        LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .topLeading, endPoint: .bottomTrailing)
                            .frame(width: 56, height: 56).cornerRadius(14)
                            .overlay(Text("\u{2B21}").font(.system(size: 26, weight: .heavy)).foregroundColor(.black))

                        HStack(spacing: 4) {
                            Text("CONSTRUCT").font(.system(size: 26, weight: .heavy)).tracking(2).foregroundColor(Theme.text)
                            Text("OS").font(.system(size: 26, weight: .heavy)).tracking(2).foregroundColor(Theme.accent)
                        }
                        Text("CONSTRUCTION NETWORK").font(.system(size: 10, weight: .bold)).tracking(4).foregroundColor(Theme.muted)
                    }

                    Spacer().frame(height: 36)

                    // Auth card
                    VStack(spacing: 0) {
                        switch step {
                        case .login: loginView
                        case .signup: signupView
                        case .twoFactor: twoFactorView
                        case .forgotPassword: forgotPasswordView
                        case .companySelect: companySelectView
                        }
                    }
                    .frame(maxWidth: 380)
                    .background(Theme.surface.opacity(0.6))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.border.opacity(0.3), lineWidth: 1))
                    .cornerRadius(16)
                    .padding(.horizontal, 24)

                    Spacer().frame(height: 20)

                    // Skip
                    Button {
                        supabase.accessToken = "skip"
                        supabase.currentUserEmail = "local"
                    } label: {
                        Text("Continue as Guest").font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.muted.opacity(0.6))
                    }.buttonStyle(.plain)

                    Spacer().frame(height: 20)

                    // Trust badges
                    HStack(spacing: 16) {
                        trustBadge(icon: "lock.shield.fill", text: "256-bit encryption")
                        trustBadge(icon: "checkmark.seal.fill", text: "SOC 2 compliant")
                        trustBadge(icon: "person.badge.shield.checkmark.fill", text: "GDPR ready")
                    }

                    Spacer().frame(height: 30)

                    // Footer
                    VStack(spacing: 6) {
                        Text("Trusted by 142,891 construction professionals").font(.system(size: 10)).foregroundColor(Theme.muted.opacity(0.5))
                        HStack(spacing: 16) {
                            Button("Terms of Service") {}.font(.system(size: 10)).foregroundColor(Theme.muted.opacity(0.4))
                            Button("Privacy Policy") {}.font(.system(size: 10)).foregroundColor(Theme.muted.opacity(0.4))
                            Button("Support") {}.font(.system(size: 10)).foregroundColor(Theme.muted.opacity(0.4))
                        }.buttonStyle(.plain)
                    }

                    Spacer().frame(height: 40)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Login View
    private var loginView: some View {
        VStack(spacing: 16) {
            Text("Sign in to your account").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                .padding(.top, 24)

            // SSO Buttons
            VStack(spacing: 10) {
                ssoButton(icon: "apple.logo", text: "Continue with Apple", bgColor: .white, textColor: .black)
                ssoButton(icon: "g.circle.fill", text: "Continue with Google", bgColor: Color(red: 0.26, green: 0.52, blue: 0.96), textColor: .white)
                ssoButton(icon: "building.2.fill", text: "Continue with SSO", bgColor: Theme.surface, textColor: Theme.text)
            }.padding(.horizontal, 24)

            // Divider
            HStack {
                Rectangle().fill(Theme.border.opacity(0.3)).frame(height: 1)
                Text("or sign in with email").font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.muted).fixedSize()
                Rectangle().fill(Theme.border.opacity(0.3)).frame(height: 1)
            }.padding(.horizontal, 24)

            // Email & Password
            VStack(spacing: 12) {
                authField(icon: "envelope.fill", placeholder: "Work email address", text: $email, isSecure: false)
                authField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)

                HStack {
                    Button { rememberMe.toggle() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                .font(.system(size: 14)).foregroundColor(rememberMe ? Theme.accent : Theme.muted)
                            Text("Remember me").font(.system(size: 11)).foregroundColor(Theme.muted)
                        }
                    }.buttonStyle(.plain)
                    Spacer()
                    Button { step = .forgotPassword } label: {
                        Text("Forgot password?").font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.accent)
                    }.buttonStyle(.plain)
                }.padding(.horizontal, 24)
            }

            if let error {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10)).foregroundColor(Theme.red)
                    Text(error).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.red)
                }.padding(.horizontal, 24)
            }

            // Sign In Button
            Button {
                guard !email.isEmpty else { error = "Email is required"; return }
                guard !password.isEmpty else { error = "Password is required"; return }
                isLoading = true; error = nil
                Task {
                    do {
                        try await supabase.signIn(email: email, password: password)
                        await MainActor.run { step = .twoFactor }
                    } catch {
                        await MainActor.run { self.error = "Invalid email or password. Please try again." }
                    }
                    await MainActor.run { isLoading = false }
                }
            } label: {
                Group {
                    if isLoading {
                        HStack(spacing: 8) { ProgressView().tint(.black); Text("Signing in...").font(.system(size: 13, weight: .bold)) }
                    } else {
                        Text("SIGN IN").font(.system(size: 13, weight: .bold)).tracking(1)
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity).frame(height: 48)
                .background(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(10)
            }
            .buttonStyle(.plain).disabled(isLoading)
            .padding(.horizontal, 24)

            // Switch to signup
            HStack(spacing: 4) {
                Text("New to ConstructionOS?").font(.system(size: 12)).foregroundColor(Theme.muted)
                Button { withAnimation { step = .signup; error = nil } } label: {
                    Text("Create an account").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.accent)
                }.buttonStyle(.plain)
            }.padding(.bottom, 24)
        }
    }

    // MARK: - Signup View
    private var signupView: some View {
        VStack(spacing: 16) {
            Text("Create your account").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
                .padding(.top, 24)
            Text("Join 142,891 construction professionals").font(.system(size: 11)).foregroundColor(Theme.muted)

            VStack(spacing: 12) {
                authField(icon: "person.fill", placeholder: "Full name", text: $fullName, isSecure: false)
                authField(icon: "envelope.fill", placeholder: "Work email address", text: $email, isSecure: false)
                authField(icon: "building.2.fill", placeholder: "Company name", text: $company, isSecure: false)
                authField(icon: "briefcase.fill", placeholder: "Job title (e.g. Superintendent, PM)", text: $jobTitle, isSecure: false)
                authField(icon: "phone.fill", placeholder: "Phone number", text: $phone, isSecure: false)
                authField(icon: "lock.fill", placeholder: "Create password (8+ characters)", text: $password, isSecure: true)
                authField(icon: "lock.rotation", placeholder: "Confirm password", text: $confirmPassword, isSecure: true)
            }

            if let error {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 10)).foregroundColor(Theme.red)
                    Text(error).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.red)
                }.padding(.horizontal, 24)
            }

            Button {
                guard !fullName.isEmpty else { error = "Full name is required"; return }
                guard !email.isEmpty else { error = "Email is required"; return }
                guard password.count >= 8 else { error = "Password must be at least 8 characters"; return }
                guard password == confirmPassword else { error = "Passwords do not match"; return }
                isLoading = true; error = nil
                Task {
                    do {
                        try await supabase.signUp(email: email, password: password)
                        await MainActor.run { step = .twoFactor }
                    } catch {
                        await MainActor.run { self.error = "Could not create account. Try a different email." }
                    }
                    await MainActor.run { isLoading = false }
                }
            } label: {
                Group {
                    if isLoading {
                        HStack(spacing: 8) { ProgressView().tint(.black); Text("Creating account...").font(.system(size: 13, weight: .bold)) }
                    } else {
                        Text("CREATE ACCOUNT").font(.system(size: 13, weight: .bold)).tracking(1)
                    }
                }
                .foregroundColor(.black)
                .frame(maxWidth: .infinity).frame(height: 48)
                .background(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(10)
            }
            .buttonStyle(.plain).disabled(isLoading)
            .padding(.horizontal, 24)

            Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                .font(.system(size: 9)).foregroundColor(Theme.muted.opacity(0.5)).multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            HStack(spacing: 4) {
                Text("Already have an account?").font(.system(size: 12)).foregroundColor(Theme.muted)
                Button { withAnimation { step = .login; error = nil } } label: {
                    Text("Sign in").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.accent)
                }.buttonStyle(.plain)
            }.padding(.bottom, 24)
        }
    }

    // MARK: - 2FA View
    private var twoFactorView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 24)

            Image(systemName: "lock.shield.fill").font(.system(size: 40)).foregroundColor(Theme.accent)

            Text("Two-Factor Authentication").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
            Text("Enter the 6-digit code sent to\n\(email)").font(.system(size: 12)).foregroundColor(Theme.muted)
                .multilineTextAlignment(.center)

            // Code input
            HStack(spacing: 8) {
                ForEach(0..<6, id: \.self) { i in
                    let char = i < twoFactorCode.count ? String(Array(twoFactorCode)[i]) : ""
                    Text(char)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(Theme.text)
                        .frame(width: 44, height: 52)
                        .background(Theme.panel)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(i == twoFactorCode.count ? Theme.accent : Theme.border.opacity(0.3), lineWidth: i == twoFactorCode.count ? 2 : 1))
                        .cornerRadius(8)
                }
            }

            TextField("", text: $twoFactorCode)
                .keyboardType(.numberPad)
                .foregroundColor(.clear).accentColor(.clear)
                .frame(width: 1, height: 1).opacity(0.01)
                .onChange(of: twoFactorCode) { _, newVal in
                    twoFactorCode = String(newVal.prefix(6).filter { $0.isNumber })
                    if twoFactorCode.count == 6 { verify2FA() }
                }

            if let error {
                Text(error).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.red)
            }

            Button { verify2FA() } label: {
                Text("VERIFY").font(.system(size: 13, weight: .bold)).tracking(1)
                    .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 48)
                    .background(twoFactorCode.count == 6 ?
                        LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .leading, endPoint: .trailing) :
                        LinearGradient(colors: [Theme.muted.opacity(0.3), Theme.muted.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain).disabled(twoFactorCode.count < 6)
            .padding(.horizontal, 24)

            HStack(spacing: 16) {
                Button("Resend code") {
                    twoFactorCode = ""
                    error = nil
                }.font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.cyan)

                Button("Use backup code") {}.font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.muted)
            }

            // Skip 2FA for demo
            Button {
                supabase.accessToken = supabase.accessToken ?? "verified"
            } label: {
                Text("Skip verification (demo)").font(.system(size: 11)).foregroundColor(Theme.muted.opacity(0.4))
            }.buttonStyle(.plain)

            Spacer().frame(height: 24)
        }
    }

    // MARK: - Forgot Password
    private var forgotPasswordView: some View {
        VStack(spacing: 20) {
            Spacer().frame(height: 24)
            Image(systemName: "key.fill").font(.system(size: 36)).foregroundColor(Theme.gold)
            Text("Reset your password").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)
            Text("Enter your email and we'll send a reset link").font(.system(size: 12)).foregroundColor(Theme.muted)

            authField(icon: "envelope.fill", placeholder: "Work email address", text: $email, isSecure: false)

            Button {
                error = nil
                // Simulate sending reset email
                error = "Reset link sent to \(email)"
            } label: {
                Text("SEND RESET LINK").font(.system(size: 13, weight: .bold)).tracking(1)
                    .foregroundColor(.black).frame(maxWidth: .infinity).frame(height: 48)
                    .background(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
            }
            .buttonStyle(.plain).padding(.horizontal, 24)

            if let error {
                Text(error).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.green)
            }

            Button { withAnimation { step = .login; error = nil } } label: {
                Text("Back to sign in").font(.system(size: 12, weight: .bold)).foregroundColor(Theme.accent)
            }.buttonStyle(.plain)

            Spacer().frame(height: 24)
        }
    }

    // MARK: - Company Select
    private var companySelectView: some View {
        VStack(spacing: 16) {
            Spacer().frame(height: 24)
            Text("Select your company").font(.system(size: 16, weight: .bold)).foregroundColor(Theme.text)

            let companies = ["NailedIt Construction", "Fagan Builders LLC", "ConstructionOS Demo"]
            ForEach(companies, id: \.self) { co in
                Button {
                    supabase.accessToken = supabase.accessToken ?? "verified"
                } label: {
                    HStack(spacing: 12) {
                        Circle().fill(Theme.accent.opacity(0.15)).frame(width: 36, height: 36)
                            .overlay(Text(String(co.prefix(1))).font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.accent))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(co).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                            Text("Active workspace").font(.system(size: 10)).foregroundColor(Theme.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(Theme.muted)
                    }
                    .padding(14).background(Theme.panel)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.2), lineWidth: 1))
                    .cornerRadius(10)
                }.buttonStyle(.plain).padding(.horizontal, 24)
            }
            Spacer().frame(height: 24)
        }
    }

    // MARK: - Helper Views
    private func authField(icon: String, placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(Theme.muted).frame(width: 20)
            if isSecure {
                SecureField(placeholder, text: text)
                    .font(.system(size: 14)).foregroundColor(Theme.text)
            } else {
                TextField(placeholder, text: text)
                    .font(.system(size: 14)).foregroundColor(Theme.text)
                    #if os(iOS)
                    .autocapitalization(.none)
                    #endif
            }
        }
        .padding(14).background(Theme.panel)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.2), lineWidth: 1))
        .cornerRadius(10)
        .padding(.horizontal, 24)
    }

    private func ssoButton(icon: String, text: String, bgColor: Color, textColor: Color) -> some View {
        Button {
            supabase.accessToken = "sso"
            supabase.currentUserEmail = "sso@constructionos.app"
        } label: {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 16)).foregroundColor(textColor)
                Text(text).font(.system(size: 13, weight: .semibold)).foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity).frame(height: 44)
            .background(bgColor.opacity(icon == "building.2.fill" ? 1 : 0.95))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.2), lineWidth: icon == "building.2.fill" ? 1 : 0))
            .cornerRadius(10)
        }.buttonStyle(.plain)
    }

    private func trustBadge(icon: String, text: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(Theme.green.opacity(0.6))
            Text(text).font(.system(size: 8, weight: .semibold)).foregroundColor(Theme.muted.opacity(0.4))
        }
    }

    private func verify2FA() {
        guard twoFactorCode.count == 6 else { return }
        isLoading = true
        // Simulate 2FA verification
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if twoFactorCode == "000000" {
                error = "Invalid code. Please try again."
                twoFactorCode = ""
            } else {
                // 2FA verified — proceed to app
                if supabase.accessToken == nil { supabase.accessToken = "verified" }
                if supabase.currentUserEmail == nil { supabase.currentUserEmail = email }
            }
            isLoading = false
        }
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
            } else if !supabase.isAuthenticated {
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
