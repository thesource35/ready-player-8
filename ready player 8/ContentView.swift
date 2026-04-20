import SwiftUI

// MARK: - Auth Gate View (Procore-style with 2FA)

enum AuthStep { case login, signup, twoFactor, forgotPassword, companySelect }

struct AuthGateView: View {
    @EnvironmentObject var supabase: SupabaseService
    @ObservedObject var profileStore = UserProfileStore.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var birthdate = ""
    @State private var yearsExperience = ""
    @State private var trade = "General"
    @State private var bio = ""
    @State private var location = ""
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
    @State private var mfaFactorId: String?
    @State private var mfaChallengeId: String?
    @State private var useBackupCode = false

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
                    Spacer().frame(height: 12)

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
                            if let termsURL = URL(string: "https://constructionos.world/terms") {
                                Link("Terms of Service", destination: termsURL)
                                    .font(.system(size: 10)).foregroundColor(Theme.muted.opacity(0.4))
                            }
                            if let privacyURL = URL(string: "https://constructionos.world/privacy") {
                                Link("Privacy Policy", destination: privacyURL)
                                    .font(.system(size: 10)).foregroundColor(Theme.muted.opacity(0.4))
                            }
                            if let supportURL = URL(string: "https://constructionos.world/support") {
                                Link("Support", destination: supportURL)
                                    .font(.system(size: 10)).foregroundColor(Theme.muted.opacity(0.4))
                            }
                        }
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

            // SSO buttons hidden — OAuth (Apple, Google) deferred to v2 (AUTH-09)

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
                    .accessibilityLabel(rememberMe ? "Remember me, selected" : "Remember me, not selected")
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
                        let hasMFA = await supabase.hasMFAEnabled()
                        await MainActor.run {
                            if hasMFA {
                                step = .twoFactor
                                Task {
                                    let factors = (try? await supabase.listMFAFactors()) ?? []
                                    if let totpFactor = factors.first(where: { $0.factorType == "totp" && $0.status == "verified" }) {
                                        mfaFactorId = totpFactor.id
                                        mfaChallengeId = try? await supabase.createMFAChallenge(factorId: totpFactor.id)
                                    }
                                }
                            }
                            // No MFA — user is already authenticated (accessToken set by signIn)
                        }
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

                // Trade selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(["General", "Electrical", "Concrete", "Steel", "Roofing", "Plumbing", "HVAC", "Fiber Optic", "Solar", "Framing", "Drywall", "Painting"], id: \.self) { t in
                            Button { trade = t } label: {
                                Text(t).font(.system(size: 9, weight: .bold))
                                    .foregroundColor(trade == t ? .black : Theme.text)
                                    .padding(.horizontal, 8).padding(.vertical, 5)
                                    .background(trade == t ? Theme.accent : Theme.panel).cornerRadius(5)
                            }.buttonStyle(.plain)
                        }
                    }
                }.padding(.horizontal, 24)

                authField(icon: "calendar", placeholder: "Birthdate (MM/DD/YYYY)", text: $birthdate, isSecure: false)
                authField(icon: "clock.fill", placeholder: "Years of experience", text: $yearsExperience, isSecure: false)
                authField(icon: "mappin.circle.fill", placeholder: "City, State", text: $location, isSecure: false)
                authField(icon: "phone.fill", placeholder: "Phone number", text: $phone, isSecure: false)
                authField(icon: "text.quote", placeholder: "Bio — tell the network about yourself", text: $bio, isSecure: false)
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
                guard !email.isEmpty else { error = "Work email is required"; return }
                guard !company.isEmpty else { error = "Company name is required"; return }
                guard !jobTitle.isEmpty else { error = "Job title is required"; return }
                guard !location.isEmpty else { error = "Location is required"; return }
                guard password.count >= AppConstants.Auth.minPasswordLength else { error = "Password must be at least \(AppConstants.Auth.minPasswordLength) characters"; return }
                guard password == confirmPassword else { error = "Passwords do not match"; return }
                isLoading = true; error = nil

                // Create profile in local network
                let profile = UserProfile(
                    email: email, fullName: fullName, company: company,
                    jobTitle: jobTitle, trade: trade, birthdate: birthdate,
                    yearsExperience: Int(yearsExperience) ?? 0, phone: phone,
                    bio: bio, location: location, certifications: [], skills: [],
                    connectionIDs: [], pendingConnectionIDs: [],
                    joinedDate: Date(), isVerified: false
                )

                if !profileStore.createAccount(profile: profile) {
                    error = "An account with this email already exists. Try signing in."
                    isLoading = false
                    return
                }

                // Also try Supabase signup
                Task {
                    do {
                        try await supabase.signUp(email: email, password: password)
                    } catch let signUpError {
                        await MainActor.run {
                            self.error = "Account created locally but server signup failed: \(signUpError.localizedDescription)"
                        }
                    }
                    await MainActor.run {
                        profileStore.emailConfirmationSent = true
                        step = .twoFactor
                        isLoading = false
                    }
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

                Button("Use backup code") {
                    useBackupCode = true
                    twoFactorCode = ""
                    error = nil
                }.font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.muted)

                if useBackupCode {
                    VStack(spacing: 8) {
                        Text("Enter your backup recovery code").font(.system(size: 11)).foregroundColor(Theme.muted)
                        authField(icon: "key.fill", placeholder: "Backup code (e.g. xxxx-xxxx-xxxx)", text: $twoFactorCode, isSecure: false)
                    }
                }
            }

            #if DEBUG
            // Demo access — DEBUG builds only, stripped from production
            Button {
                supabase.accessToken = supabase.accessToken ?? UUID().uuidString
                if profileStore.currentUser == nil {
                    let _ = profileStore.createAccount(profile: UserProfile(
                        email: "demo@constructionos.app", fullName: "Demo User", company: "ConstructionOS",
                        jobTitle: "Demo", trade: "General", birthdate: "01/01/2000",
                        yearsExperience: 1, phone: "", bio: "Demo account",
                        location: "Austin, TX", certifications: [], skills: [],
                        connectionIDs: [], pendingConnectionIDs: [],
                        joinedDate: Date(), isVerified: false
                    ))
                }
            } label: {
                Text("Continue to demo").font(.system(size: 10)).foregroundColor(Theme.muted.opacity(0.3))
            }.buttonStyle(.plain)
            #endif

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
                guard !email.isEmpty else { error = "Email is required"; return }
                isLoading = true; error = nil
                Task {
                    do {
                        try await supabase.resetPassword(email: email)
                        await MainActor.run {
                            error = "Password reset link sent to \(email). Check your inbox."
                        }
                    } catch {
                        await MainActor.run {
                            self.error = "Could not send reset link. Please check your email and try again."
                        }
                    }
                    await MainActor.run { isLoading = false }
                }
            } label: {
                Text(isLoading ? "Sending..." : "SEND RESET LINK").font(.system(size: 13, weight: .bold)).tracking(1)
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
                    .textInputAutocapitalization(.never)
                    #endif
            }
        }
        .padding(14).background(Theme.panel)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.2), lineWidth: 1))
        .cornerRadius(10)
        .padding(.horizontal, 24)
    }

    // ssoButton removed — OAuth (Apple, Google) deferred to v2 (AUTH-09)

    private func trustBadge(icon: String, text: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(Theme.green.opacity(0.6))
            Text(text).font(.system(size: 8, weight: .semibold)).foregroundColor(Theme.muted.opacity(0.4))
        }
    }

    private func verify2FA() {
        guard twoFactorCode.count == 6 else { return }
        guard let factorId = mfaFactorId, let challengeId = mfaChallengeId else {
            error = "MFA not configured. Contact support."
            return
        }
        isLoading = true
        Task {
            do {
                try await supabase.verifyMFA(factorId: factorId, challengeId: challengeId, code: twoFactorCode)
            } catch {
                await MainActor.run {
                    self.error = "Invalid verification code. Please try again."
                    twoFactorCode = ""
                    Task {
                        mfaChallengeId = try? await supabase.createMFAChallenge(factorId: factorId)
                    }
                }
            }
            await MainActor.run { isLoading = false }
        }
    }
}

struct ContentView: View {
    @StateObject private var actionLog = RiskActionLogStore()
    // MARK: - Phase 14: Notifications
    @StateObject private var notificationsStore = NotificationsStore()
    @State private var showInboxSheet: Bool = false
    @EnvironmentObject private var supabase: SupabaseService
    @State private var activeNav: NavTab = .home
    @State private var pulse = false

    enum NavTab: String, CaseIterable {
        case home = "home"; case projects = "projects"; case contracts = "contracts"
        case market = "market"; case maps = "maps"
        case liveFeed = "live-feed" // MARK: Phase 29 — LIVE-03 D-04 (intel group near Maps)
        case network = "network"
        case ops = "ops"; case hub = "hub"; case security = "security"
        case pricing = "pricing"; case angelic = "angelic"
        case inbox = "inbox" // MARK: Phase 14
        case team = "team" // MARK: Phase 15 — TEAM-01
        case certifications = "certifications" // MARK: Phase 15 — TEAM-03
        case dailyCrew = "daily-crew" // MARK: Phase 15 — TEAM-05
        case wealth = "wealth"
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
        case reports = "reports"
        case empire = "empire"
        case crypto = "crypto"
        case settings = "settings"
    }

    private let navItems: [(String, String, String, String)] = [
        ("home","COMMAND","\u{2318}","core"),("projects","PROJECTS","\u{1F3D7}","core"),
        ("contracts","CONTRACTS","\u{1F4CB}","core"),("market","MARKET","\u{1F4CA}","core"),
        ("maps","MAPS","\u{1F5FA}","core"),("network","NETWORK","\u{1F4E1}","core"),
        ("live-feed","LIVE FEED","\u{1F3A5}","intel"), // MARK: Phase 29 — LIVE-03 D-04
        ("ops","OPS","\u{2699}\u{FE0F}","intel"),("hub","HUB","\u{1F50C}","intel"),
        ("security","SECURITY","\u{1F512}","intel"),("pricing","PRICING","\u{1F4B2}","intel"),
        ("angelic","ANGELIC","\u{1F47C}","intel"),
        ("inbox","INBOX","\u{1F514}","intel"), // MARK: Phase 14
        ("team","TEAM","\u{1F465}","intel"), // MARK: Phase 15 — TEAM-01
        ("certifications","CERTS","\u{1F4DC}","intel"), // MARK: Phase 15 — TEAM-03
        ("daily-crew","DAILY CREW","\u{1F477}","intel"), // MARK: Phase 15 — TEAM-05
        ("wealth","WEALTH","\u{1F48E}","wealth"),
        ("cos-network","COS NET","\u{1F310}","wealth"),
        ("rentals","RENTALS","\u{1F6E0}","wealth"),
        ("electrical","ELECTRIC","\u{26A1}","trade"),
        ("tax","TAX","\u{1F4B0}","trade"),
        ("field","FIELD","\u{1F4F1}","field"),
        ("finance","FINANCE","\u{1F4B5}","field"),
        ("compliance","COMPLY","\u{1F6E1}","field"),
        ("client-portal","CLIENTS","\u{1F465}","field"),
        ("analytics","ANALYTICS","\u{1F4C8}","field"),
        ("reports","REPORTS","\u{1F4CA}","field"),
        ("schedule","SCHEDULE","\u{1F4C5}","plan"),
        ("training","TRAINING","\u{1F393}","plan"),
        ("scanner","SCANNER","\u{1F4F7}","plan"),
        ("tech","TECH 2026","\u{1F916}","tech"),
        ("punch-pro","PUNCH","\u{2705}","build"),
        ("roof-estimate","ROOFING","\u{1F3E0}","build"),
        ("smart-build","BUILD AI","\u{1F3D7}","build"),
        ("contractors","DIRECTORY","\u{1F4D6}","build"),
        ("empire","EMPIRE","\u{1F3E6}","empire"),
        ("crypto","CRYPTO","\u{1F48E}","empire"),
        ("settings","SETTINGS","\u{2699}\u{FE0F}","settings"),
    ]

    @State private var wealthTab: WealthSubTab = .moneyLens
    enum WealthSubTab: String, CaseIterable {
        case moneyLens = "Money Lens"; case psychology = "Psychology"
        case power = "Power Thinking"; case leverage = "Leverage"; case opportunity = "Opportunity"
    }

    @State private var showSearch = false
    @State private var biometricUnlocked = false
    @ObservedObject private var profileStore = UserProfileStore.shared
    @AppStorage("ConstructOS.OnboardingComplete") private var onboardingComplete = false
    // Phase 25: Live cert badge count from CertificationsView urgency calculation
    @AppStorage("ConstructOS.CertBadgeCount") private var certBadgeCount: Int = 0

    var body: some View {
        Group {
            if profileStore.currentUser == nil {
                // Login/Signup is ALWAYS the first screen — must have account to access app
                AuthGateView()
            } else if !onboardingComplete {
                OnboardingView(isComplete: $onboardingComplete)
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

            // Phase 25: Cold-launch deep-link from cert push notification (D-17)
            if let pendingCertId = UserDefaults.standard.string(forKey: "ConstructOS.PendingCertDeepLink") {
                activeNav = .certifications
                UserDefaults.standard.set(pendingCertId, forKey: "ConstructOS.HighlightCertId")
                UserDefaults.standard.removeObject(forKey: "ConstructOS.PendingCertDeepLink")
            }
        }
        .onChange(of: activeNav) { _, newTab in
            HapticEngine.tap()
            AnalyticsEngine.shared.trackScreen(newTab.rawValue)
        }
        .onAppear { AnalyticsEngine.shared.track("app_opened") }
        .onOpenURL { url in
            if let tab = DeepLinkHandler.handleURL(url) { activeNav = tab }
        }
        .sheet(isPresented: $showSearch) {
            GlobalSearchView(isPresented: $showSearch)
        }
        // MARK: - Phase 14: Notifications sheet + lifecycle
        .sheet(isPresented: $showInboxSheet) {
            InboxView(store: notificationsStore)
        }
        .task {
            await notificationsStore.start(userId: SupabaseService.shared.currentUserId)
        }
    }

    private var mainAppView: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > 800
            ZStack {
                PremiumBackgroundView()
                VStack(spacing: 0) {
                    // MARK: - Phase 14: HeaderView gets the bell tap handler
                    HeaderView(onBellTap: { showInboxSheet = true })
                    OfflineIndicatorBar(pendingCount: supabase.pendingWrites.count)
                    TickerView()
                    if isWide {
                        HStack(spacing: 0) {
                            VStack(spacing: 0) {
                                ScrollView { NavigationRailView(activeNav: $activeNav, navItems: navItems, certBadgeCount: certBadgeCount) }
                                SidebarStatusView(pulse: $pulse)
                            }.frame(width: 180).background(Theme.surface)
                            .border(width: 1, edges: [.trailing], color: Theme.border)
                            ScrollView { activeTabContent.padding(16) }
                        }
                    } else {
                        NavigationTabsView(activeNav: $activeNav, navItems: navItems, certBadgeCount: certBadgeCount)
                        ScrollView { activeTabContent.padding(16) }
                    }
                    FooterView(pulse: $pulse)
                }
            }
        }
        .preferredColorScheme(.dark)
        .environmentObject(actionLog)
        // MARK: - Phase 14: Notifications store environment
        .environmentObject(notificationsStore)
        .onReceive(NotificationCenter.default.publisher(for: .init("ConstructOS.NavToProjects"))) { _ in
            activeNav = .projects
        }
        // Phase 23: Cross-nav to DailyCrew tab (D-14)
        .onReceive(NotificationCenter.default.publisher(for: .init("ConstructOS.NavToDailyCrew"))) { _ in
            activeNav = .dailyCrew
        }
        // Phase 23: Basic team deep-link (D-10)
        .onReceive(NotificationCenter.default.publisher(for: .init("ConstructOS.NavToTeam"))) { _ in
            activeNav = .team
        }
        // Phase 25: Cert push notification deep-link (D-17)
        .onReceive(NotificationCenter.default.publisher(for: .init("ConstructOS.NavToCert"))) { notification in
            activeNav = .certifications
            if let certId = notification.userInfo?["cert_id"] as? String {
                UserDefaults.standard.set(certId, forKey: "ConstructOS.HighlightCertId")
            }
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
        case .liveFeed: LiveFeedView() // MARK: Phase 29 — LIVE-03
        case .network: SocialFeedView()
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
        // MARK: Phase 14
        case .inbox: InboxView(store: notificationsStore)
        // MARK: Phase 15 — TEAM-01
        case .team: TeamView()
        // MARK: Phase 15 — TEAM-03
        case .certifications: CertificationsView()
        // MARK: Phase 15 — TEAM-05 — project picker lives inside DailyCrewView (Phase 23-01).
        case .dailyCrew: DailyCrewView()
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
        case .reports: ReportsView()
        case .schedule: ScheduleHubView()
        case .training: TrainingCertView()
        case .scanner: ScannerToolsView()
        case .tech: ConstructionTech2026View()
        case .punchPro: PunchListProView()
        case .roofEstimate: SatelliteRoofEstimatorView()
        case .smartBuild: SmartBuildHubView()
        case .contractors: GlobalContractorDirectoryView()
        case .empire: EmpireDashboardView()
        case .crypto: CryptoPaymentView()
        case .settings: SettingsProfileView()
        }
    }
}
