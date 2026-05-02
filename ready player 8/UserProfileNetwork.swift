import SwiftUI
import Combine
import PhotosUI

// MARK: - ========== User Profile & Network System ==========

// MARK: - User Profile Model

struct UserProfile: Identifiable, Codable {
    var id = UUID()
    var email: String
    var fullName: String
    var company: String
    var jobTitle: String
    var trade: String
    var birthdate: String
    var yearsExperience: Int
    var phone: String
    var bio: String
    var location: String
    var profilePhotoData: Data?
    var coverPhotoData: Data?
    var certifications: [String]
    var skills: [String]
    var connectionIDs: [String]
    var pendingConnectionIDs: [String]
    var joinedDate: Date
    var isVerified: Bool
    var profileComplete: Bool {
        !fullName.isEmpty && !company.isEmpty && !jobTitle.isEmpty && !trade.isEmpty && !bio.isEmpty
    }
    var initials: String {
        let parts = fullName.split(separator: " ")
        if parts.count >= 2 { return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased() }
        return String(fullName.prefix(2)).uppercased()
    }
}

// MARK: - User Profile Store

@MainActor
final class UserProfileStore: ObservableObject {
    /// Backward-compat singleton — prefer @EnvironmentObject injection in views
    static let shared = UserProfileStore()

    @Published var currentUser: UserProfile?
    @Published var allUsers: [UserProfile] = []
    @Published var suggestedConnections: [UserProfile] = []
    @Published var pendingRequests: [UserProfile] = []
    @Published var connections: [UserProfile] = []
    @Published var emailConfirmationSent = false
    @Published var emailConfirmed = false

    private let profileKey = "ConstructOS.UserProfile"
    private let usersKey = "ConstructOS.AllUsers"

    init() {
        currentUser = loadJSON(profileKey, default: nil as UserProfile?)
        allUsers = loadJSON(usersKey, default: mockNetworkUsers)
        if let user = currentUser {
            updateSuggestions(for: user)
        }
    }

    func createAccount(profile: UserProfile) -> Bool {
        // Check duplicate email
        if allUsers.contains(where: { $0.email.lowercased() == profile.email.lowercased() }) {
            return false // duplicate
        }
        var newProfile = profile
        newProfile.joinedDate = Date()
        currentUser = newProfile
        allUsers.append(newProfile)
        saveJSON(profileKey, value: newProfile)
        saveJSON(usersKey, value: allUsers)
        updateSuggestions(for: newProfile)
        return true
    }

    // AUTH-GATE-01 (Phase 29.1): removed password-free local login shim.
    // Authentication MUST go through SupabaseService.signIn (accessToken is the
    // source of truth for `isAuthenticated`). Do NOT re-introduce a local-only
    // login method — see .planning/phases/29.1-fix-critical-auth-bug/29.1-RESEARCH.md §Candidate 1.

    func updateProfile(_ profile: UserProfile) {
        currentUser = profile
        if let i = allUsers.firstIndex(where: { $0.id == profile.id }) {
            allUsers[i] = profile
        }
        saveJSON(profileKey, value: profile)
        saveJSON(usersKey, value: allUsers)
        updateSuggestions(for: profile)
    }

    func sendConnectionRequest(to user: UserProfile) {
        guard var current = currentUser else { return }
        if !current.pendingConnectionIDs.contains(user.id.uuidString) {
            current.pendingConnectionIDs.append(user.id.uuidString)
            updateProfile(current)
        }
    }

    func acceptConnection(from user: UserProfile) {
        guard var current = currentUser else { return }
        current.connectionIDs.append(user.id.uuidString)
        current.pendingConnectionIDs.removeAll { $0 == user.id.uuidString }
        updateProfile(current)
    }

    func removeConnection(_ user: UserProfile) {
        guard var current = currentUser else { return }
        current.connectionIDs.removeAll { $0 == user.id.uuidString }
        updateProfile(current)
    }

    func isConnected(to user: UserProfile) -> Bool {
        currentUser?.connectionIDs.contains(user.id.uuidString) ?? false
    }

    func isPending(to user: UserProfile) -> Bool {
        currentUser?.pendingConnectionIDs.contains(user.id.uuidString) ?? false
    }

    func logout() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: profileKey)
    }

    private func updateSuggestions(for user: UserProfile) {
        suggestedConnections = allUsers.filter { other in
            other.id != user.id &&
            !user.connectionIDs.contains(other.id.uuidString) &&
            !user.pendingConnectionIDs.contains(other.id.uuidString) &&
            (other.trade == user.trade || other.location == user.location || other.company == user.company)
        }.prefix(10).map { $0 }

        connections = allUsers.filter { user.connectionIDs.contains($0.id.uuidString) }
        pendingRequests = allUsers.filter { user.pendingConnectionIDs.contains($0.id.uuidString) }
    }
}

// MARK: - Mock Network Users
//
// 999.5 (d) Tier 3: bundle-gated.
#if DEBUG
let mockNetworkUsers: [UserProfile] = [
    UserProfile(email: "marcus.r@powergrid.com", fullName: "Marcus Rivera", company: "PowerGrid Construction", jobTitle: "Senior Superintendent", trade: "General", birthdate: "1985-06-15", yearsExperience: 18, phone: "713-555-0142", bio: "18 years in commercial construction. Specialized in high-rise and mixed-use projects. OSHA 30, PMP certified.", location: "Houston, TX", certifications: ["OSHA 30", "PMP", "LEED AP"], skills: ["Project Management", "Scheduling", "Safety"], connectionIDs: [], pendingConnectionIDs: [], joinedDate: Date().addingTimeInterval(-86400*90), isVerified: true),
    UserProfile(email: "sarah.c@fiberlink.com", fullName: "Sarah Chen", company: "FiberLink Solutions", jobTitle: "Lead Fiber Installer", trade: "Fiber Optic", birthdate: "1990-03-22", yearsExperience: 12, phone: "415-555-0198", bio: "BICSI RCDD certified. Specializing in data center and campus fiber builds. 200+ projects completed.", location: "San Francisco, CA", certifications: ["BICSI RCDD", "CFOT", "OSHA 10"], skills: ["Fiber Optic", "OTDR Testing", "Splicing"], connectionIDs: [], pendingConnectionIDs: [], joinedDate: Date().addingTimeInterval(-86400*60), isVerified: true),
    UserProfile(email: "james.w@steelworks.com", fullName: "James Washington", company: "Atlas Steel Works", jobTitle: "Ironworker Foreman", trade: "Steel", birthdate: "1982-11-08", yearsExperience: 22, phone: "312-555-0276", bio: "22 years structural steel. Union ironworker turned foreman. Zero LTI record across 47 projects.", location: "Chicago, IL", certifications: ["AWS D1.1", "OSHA 30", "NCCCO Signal"], skills: ["Structural Steel", "Welding", "Rigging"], connectionIDs: [], pendingConnectionIDs: [], joinedDate: Date().addingTimeInterval(-86400*120), isVerified: true),
    UserProfile(email: "priya.p@lightspeed.com", fullName: "Priya Patel", company: "LightSpeed Electric", jobTitle: "Master Electrician", trade: "Electrical", birthdate: "1988-07-19", yearsExperience: 14, phone: "212-555-0341", bio: "Master electrician licensed in 3 states. Data center and healthcare specialist. IBEW Local 3.", location: "New York, NY", certifications: ["Master Electrician", "IBEW", "OSHA 30"], skills: ["Commercial Electric", "Data Centers", "Fire Alarm"], connectionIDs: [], pendingConnectionIDs: [], joinedDate: Date().addingTimeInterval(-86400*45), isVerified: true),
    UserProfile(email: "carlos.m@apexconcrete.com", fullName: "Carlos Mendez", company: "Apex Concrete", jobTitle: "Concrete Superintendent", trade: "Concrete", birthdate: "1979-01-30", yearsExperience: 25, phone: "305-555-0189", bio: "25 years concrete. From laborer to superintendent. ACI Grade 1 certified. Specialist in post-tension and tilt-up.", location: "Miami, FL", certifications: ["ACI Grade 1", "OSHA 30", "CPR/First Aid"], skills: ["Post-Tension", "Tilt-Up", "Foundation"], connectionIDs: [], pendingConnectionIDs: [], joinedDate: Date().addingTimeInterval(-86400*180), isVerified: true),
    UserProfile(email: "derek.t@sunvolt.com", fullName: "Derek Torres", company: "SunVolt Energy", jobTitle: "Solar Project Manager", trade: "Solar", birthdate: "1992-09-12", yearsExperience: 8, phone: "602-555-0234", bio: "NABCEP certified PV installer. Managing commercial solar + battery storage projects across the Southwest.", location: "Phoenix, AZ", certifications: ["NABCEP PV", "OSHA 10", "First Aid"], skills: ["Solar PV", "Battery Storage", "EV Charging"], connectionIDs: [], pendingConnectionIDs: [], joinedDate: Date().addingTimeInterval(-86400*30), isVerified: false),
    UserProfile(email: "kim.n@securewire.com", fullName: "Kim Nguyen", company: "SecureWire Systems", jobTitle: "Low Voltage Tech Lead", trade: "Low Voltage", birthdate: "1994-05-03", yearsExperience: 7, phone: "206-555-0156", bio: "Access control, security cameras, and structured cabling. BICSI TECH certified.", location: "Seattle, WA", certifications: ["BICSI TECH", "NICET II", "OSHA 10"], skills: ["Access Control", "CCTV", "Structured Cabling"], connectionIDs: [], pendingConnectionIDs: [], joinedDate: Date().addingTimeInterval(-86400*15), isVerified: false),
    UserProfile(email: "ashley.w@roofpro.com", fullName: "Ashley Williams", company: "RoofPro Services", jobTitle: "Roofing Foreman", trade: "Roofing", birthdate: "1987-12-25", yearsExperience: 16, phone: "214-555-0298", bio: "Commercial roofing specialist. TPO, EPDM, and modified bitumen. GAF Master Elite contractor.", location: "Dallas, TX", certifications: ["GAF Master Elite", "OSHA 30", "Fall Protection"], skills: ["TPO", "EPDM", "Metal Roofing"], connectionIDs: [], pendingConnectionIDs: [], joinedDate: Date().addingTimeInterval(-86400*75), isVerified: true),
]
#else
let mockNetworkUsers: [UserProfile] = []
#endif

// MARK: - User Profile View (Instagram-style)

struct UserProfileView: View {
    let user: UserProfile
    let isOwnProfile: Bool
    @ObservedObject var store = UserProfileStore.shared
    @State private var activeTab = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Cover photo area
                ZStack(alignment: .bottomLeading) {
                    Rectangle().fill(LinearGradient(colors: [Theme.accent.opacity(0.3), Theme.cyan.opacity(0.2), Theme.surface], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(height: 140)

                    // Profile photo
                    HStack(alignment: .bottom, spacing: 14) {
                        Circle()
                            .fill(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 80, height: 80)
                            .overlay(Text(user.initials).font(.system(size: 28, weight: .heavy)).foregroundColor(.black))
                            .overlay(Circle().stroke(Theme.bg, lineWidth: 4))
                            .offset(y: 40)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(user.fullName).font(.system(size: 18, weight: .heavy)).foregroundColor(Theme.text)
                                if user.isVerified {
                                    Image(systemName: "checkmark.seal.fill").font(.system(size: 12)).foregroundColor(Theme.cyan)
                                }
                            }
                            Text(user.jobTitle).font(.system(size: 12, weight: .semibold)).foregroundColor(Theme.accent)
                        }.offset(y: 20)

                        Spacer()
                    }.padding(.horizontal, 16)
                }

                Spacer().frame(height: 50)

                // Stats row
                HStack(spacing: 0) {
                    profileStat(value: "\(user.connectionIDs.count)", label: "Connections")
                    Rectangle().fill(Theme.border.opacity(0.2)).frame(width: 1, height: 36)
                    profileStat(value: "\(user.yearsExperience)", label: "Years Exp")
                    Rectangle().fill(Theme.border.opacity(0.2)).frame(width: 1, height: 36)
                    profileStat(value: user.trade, label: "Trade")
                    Rectangle().fill(Theme.border.opacity(0.2)).frame(width: 1, height: 36)
                    profileStat(value: "\(user.certifications.count)", label: "Certs")
                }.padding(.horizontal, 16)

                // Action buttons
                HStack(spacing: 8) {
                    if isOwnProfile {
                        Button { ToastManager.shared.show("Coming soon") } label: {
                            Text("EDIT PROFILE").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(Theme.surface)
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                                .cornerRadius(8)
                        }.buttonStyle(.plain)
                    } else {
                        if store.isConnected(to: user) {
                            Button { store.removeConnection(user) } label: {
                                Label("CONNECTED", systemImage: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.green)
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(Theme.green.opacity(0.1))
                                    .cornerRadius(8)
                            }.buttonStyle(.plain)
                        } else if store.isPending(to: user) {
                            Text("PENDING").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.gold)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(Theme.gold.opacity(0.1))
                                .cornerRadius(8)
                        } else {
                            Button { store.sendConnectionRequest(to: user) } label: {
                                Label("CONNECT", systemImage: "person.badge.plus").font(.system(size: 11, weight: .bold)).foregroundColor(.black)
                                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                                    .background(Theme.accent)
                                    .cornerRadius(8)
                            }.buttonStyle(.plain)
                        }
                        Button { ToastManager.shared.show("Coming soon") } label: {
                            Label("MESSAGE", systemImage: "bubble.left").font(.system(size: 11, weight: .bold)).foregroundColor(Theme.cyan)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(Theme.cyan.opacity(0.1))
                                .cornerRadius(8)
                        }.buttonStyle(.plain)
                    }
                }.padding(.horizontal, 16).padding(.top, 12)

                // Bio + Details
                VStack(alignment: .leading, spacing: 10) {
                    // Company + Location
                    HStack(spacing: 12) {
                        Label(user.company, systemImage: "building.2.fill").font(.system(size: 11)).foregroundColor(Theme.text)
                        Label(user.location, systemImage: "mappin.circle.fill").font(.system(size: 11)).foregroundColor(Theme.muted)
                    }

                    // Bio
                    if !user.bio.isEmpty {
                        Text(user.bio).font(.system(size: 12)).foregroundColor(Theme.text).lineLimit(4)
                    }

                    // Certifications
                    if !user.certifications.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(user.certifications, id: \.self) { cert in
                                    Text(cert).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.cyan)
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Theme.cyan.opacity(0.1)).cornerRadius(6)
                                }
                            }
                        }
                    }

                    // Skills
                    if !user.skills.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(user.skills, id: \.self) { skill in
                                    Text(skill).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.gold)
                                        .padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Theme.gold.opacity(0.1)).cornerRadius(6)
                                }
                            }
                        }
                    }

                    // Member info
                    HStack(spacing: 12) {
                        Label("Joined \(user.joinedDate, style: .date)", systemImage: "calendar").font(.system(size: 10)).foregroundColor(Theme.muted)
                        Label("\(user.yearsExperience) years in \(user.trade)", systemImage: "hammer.fill").font(.system(size: 10)).foregroundColor(Theme.muted)
                    }
                }.padding(16)

                Divider().background(Theme.border.opacity(0.2))

                // Suggested Connections
                if isOwnProfile && !store.suggestedConnections.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("PEOPLE YOU MAY KNOW").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.accent)
                            .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(store.suggestedConnections) { suggested in
                                    SuggestedUserCard(user: suggested)
                                }
                            }.padding(.horizontal, 16)
                        }
                    }.padding(.vertical, 14)
                }
            }
        }
        .background(Theme.bg)
    }

    private func profileStat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 15, weight: .heavy)).foregroundColor(Theme.text)
            Text(label).font(.system(size: 9)).foregroundColor(Theme.muted)
        }.frame(maxWidth: .infinity)
    }
}

struct SuggestedUserCard: View {
    let user: UserProfile
    @ObservedObject var store = UserProfileStore.shared

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(LinearGradient(colors: [Theme.accent, Theme.cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 56, height: 56)
                .overlay(Text(user.initials).font(.system(size: 18, weight: .heavy)).foregroundColor(.white))

            Text(user.fullName).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.text).lineLimit(1)
            Text(user.jobTitle).font(.system(size: 8)).foregroundColor(Theme.muted).lineLimit(1)
            Text(user.company).font(.system(size: 8)).foregroundColor(Theme.muted).lineLimit(1)

            if store.isPending(to: user) {
                Text("PENDING").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.gold)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Theme.gold.opacity(0.1)).cornerRadius(6)
            } else {
                Button { store.sendConnectionRequest(to: user) } label: {
                    Text("CONNECT").font(.system(size: 8, weight: .bold)).foregroundColor(.black)
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Theme.accent).cornerRadius(6)
                }.buttonStyle(.plain)
            }
        }
        .frame(width: 110)
        .padding(10).background(Theme.surface).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border.opacity(0.15), lineWidth: 1))
    }
}

// MARK: - Network Feed / Discover View

struct NetworkDiscoverView: View {
    @ObservedObject var store = UserProfileStore.shared
    @State private var searchText = ""
    @State private var selectedTrade: String? = nil

    private let trades = ["General", "Electrical", "Concrete", "Steel", "Roofing", "Plumbing", "HVAC", "Fiber Optic", "Solar", "Low Voltage"]

    private var filteredUsers: [UserProfile] {
        var list = store.allUsers.filter { $0.id != store.currentUser?.id }
        if let trade = selectedTrade { list = list.filter { $0.trade == trade } }
        if !searchText.isEmpty {
            let q = searchText.lowercased()
            list = list.filter {
                $0.fullName.lowercased().contains(q) ||
                $0.company.lowercased().contains(q) ||
                $0.jobTitle.lowercased().contains(q) ||
                $0.trade.lowercased().contains(q) ||
                $0.location.lowercased().contains(q)
            }
        }
        return list
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(Theme.muted)
                TextField("Search people, companies, trades...", text: $searchText)
                    .font(.system(size: 12)).foregroundColor(Theme.text)
            }
            .padding(10).background(Theme.surface)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border.opacity(0.2), lineWidth: 1))
            .cornerRadius(10)

            // Trade filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    Button { selectedTrade = nil } label: {
                        Text("ALL").font(.system(size: 9, weight: .bold))
                            .foregroundColor(selectedTrade == nil ? .black : Theme.text)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(selectedTrade == nil ? Theme.accent : Theme.surface).cornerRadius(6)
                    }.buttonStyle(.plain)
                    ForEach(trades, id: \.self) { trade in
                        Button { selectedTrade = selectedTrade == trade ? nil : trade } label: {
                            Text(trade).font(.system(size: 9, weight: .bold))
                                .foregroundColor(selectedTrade == trade ? .black : Theme.text)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(selectedTrade == trade ? Theme.cyan : Theme.surface).cornerRadius(6)
                        }.buttonStyle(.plain)
                    }
                }
            }

            // User cards
            ForEach(filteredUsers) { user in
                NetworkUserRow(user: user)
            }
        }
    }
}

struct NetworkUserRow: View {
    let user: UserProfile
    @ObservedObject var store = UserProfileStore.shared
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Circle()
                    .fill(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 48, height: 48)
                    .overlay(Text(user.initials).font(.system(size: 16, weight: .heavy)).foregroundColor(.black))

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(user.fullName).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                        if user.isVerified { Image(systemName: "checkmark.seal.fill").font(.system(size: 10)).foregroundColor(Theme.cyan) }
                    }
                    Text("\(user.jobTitle) at \(user.company)").font(.system(size: 10)).foregroundColor(Theme.muted)
                    HStack(spacing: 8) {
                        Label(user.location, systemImage: "mappin").font(.system(size: 9)).foregroundColor(Theme.muted)
                        Label("\(user.yearsExperience) yrs", systemImage: "clock").font(.system(size: 9)).foregroundColor(Theme.muted)
                    }
                }
                Spacer()

                if store.isConnected(to: user) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 18)).foregroundColor(Theme.green)
                } else if store.isPending(to: user) {
                    Text("PENDING").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.gold)
                } else {
                    Button { store.sendConnectionRequest(to: user) } label: {
                        Image(systemName: "person.badge.plus").font(.system(size: 16)).foregroundColor(Theme.accent)
                    }.buttonStyle(.plain)
                    .accessibilityLabel("Send connection request")
                }
            }

            if expanded {
                if !user.bio.isEmpty {
                    Text(user.bio).font(.system(size: 10)).foregroundColor(Theme.muted)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(user.certifications, id: \.self) { cert in
                            Text(cert).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.cyan)
                                .padding(.horizontal, 6).padding(.vertical, 3).background(Theme.cyan.opacity(0.08)).cornerRadius(4)
                        }
                        ForEach(user.skills, id: \.self) { skill in
                            Text(skill).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.gold)
                                .padding(.horizontal, 6).padding(.vertical, 3).background(Theme.gold.opacity(0.08)).cornerRadius(4)
                        }
                    }
                }
            }

            HStack {
                Text(user.trade).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.accent)
                Spacer()
                Button { withAnimation { expanded.toggle() } } label: {
                    Text(expanded ? "LESS" : "VIEW PROFILE").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.accent)
                }.buttonStyle(.plain)
            }
        }
        .padding(12).background(Theme.surface).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border.opacity(0.15), lineWidth: 1))
    }
}
