import Combine
import Foundation
import PhotosUI
import SwiftUI
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif


// MARK: - ========== ConstructionOSNetwork.swift ==========


// MARK: - Construction OS Network

enum ConstructionOSNetworkPostType: String, CaseIterable {
    case workUpdate    = "Work Update"
    case projectWin    = "Project Win"
    case jobPosting    = "Job Posting"
    case bidOpportunity = "Bid Request"
    case shoutout      = "Shoutout"

    var icon: String {
        switch self {
        case .workUpdate:     return "🔧"
        case .projectWin:     return "🏆"
        case .jobPosting:     return "💼"
        case .bidOpportunity: return "📋"
        case .shoutout:       return "🙌"
        }
    }
    var color: Color {
        switch self {
        case .workUpdate:     return Theme.cyan
        case .projectWin:     return Theme.gold
        case .jobPosting:     return Theme.accent
        case .bidOpportunity: return Theme.green
        case .shoutout:       return Theme.purple
        }
    }
}

enum ConstructionOSNetworkTrade: String, CaseIterable {
    case general    = "General"
    case concrete   = "Concrete"
    case steel      = "Steel"
    case electrical = "Electrical"
    case plumbing   = "Plumbing"
    case hvac       = "HVAC"
    case framing    = "Framing"
    case roofing    = "Roofing"
    case crane      = "Crane"
    case finishing  = "Finishing"

    var icon: String {
        switch self {
        case .general:    return "🏗"
        case .concrete:   return "🧱"
        case .steel:      return "⚙️"
        case .electrical: return "⚡"
        case .plumbing:   return "🔧"
        case .hvac:       return "❄️"
        case .framing:    return "🪵"
        case .roofing:    return "🏠"
        case .crane:      return "🏗"
        case .finishing:  return "🎨"
        }
    }
}

struct ConstructionOSNetworkPost: Identifiable {
    let id = UUID()
    let authorName: String
    let authorRole: String
    let authorTrade: ConstructionOSNetworkTrade
    let postType: ConstructionOSNetworkPostType
    let content: String
    let tags: [String]
    let timeAgo: String
    let likes: Int
    let comments: Int
    let projectRef: String?
    let initials: String
    let avatarColors: [Color]
}

struct ConstructionOSNetworkCrewMember: Identifiable {
    let id = UUID()
    let name: String
    let trade: ConstructionOSNetworkTrade
    let role: String
    let yearsExp: Int
    let location: String
    let rating: Double
    let jobsDone: Int
    let socialHealthScore: Int
    let workEthicScore: Int
    let socialHealthTrend7d: [Int]
    let workEthicTrend7d: [Int]
    let available: Bool
    let badge: String?
    let connections: Int
    let initials: String
}

struct ConstructionOSNetworkJobListing: Identifiable {
    let id = UUID()
    let title: String
    let company: String
    let trade: ConstructionOSNetworkTrade
    let location: String
    let payRate: String
    let startDate: String
    let duration: String
    let urgent: Bool
    let applicants: Int
    let requirements: [String]
}

struct ConstructionOSNetworkComment: Identifiable {
    let id = UUID()
    let authorName: String
    let text: String
    let timeAgo: String
    let photoData: Data?
}

private let mockConstructionOSNetworkPosts: [ConstructionOSNetworkPost] = [
    ConstructionOSNetworkPost(
        authorName: "Marcus Rivera", authorRole: "Senior Ironworker",
        authorTrade: .steel, postType: .projectWin,
        content: "Just wrapped the structural steel on the Harborview Tower. 47 floors, 14 months, zero LTIs. Crew of 38 — every single one of you made this possible. 💪 Proud doesn't cover it.",
        tags: ["#SteelWork", "#SafetyFirst", "#Harborview"],
        timeAgo: "2h ago", likes: 184, comments: 42,
        projectRef: "Harborview Tower", initials: "MR",
        avatarColors: [Theme.accent, Theme.gold]
    ),
    ConstructionOSNetworkPost(
        authorName: "Delta Build Group", authorRole: "General Contractor · Licensed",
        authorTrade: .general, postType: .bidOpportunity,
        content: "🔔 SEEKING BIDS — 240-unit residential complex, Phoenix AZ. Packages open: MEP, framing, exterior envelope. Min bonding $2M. Prevailing wage applies. DM or reply with qualifications.",
        tags: ["#OpenBid", "#PhoenixAZ", "#MEP", "#Framing"],
        timeAgo: "4h ago", likes: 67, comments: 31,
        projectRef: "Phoenix Residential Phase 2", initials: "DB",
        avatarColors: [Theme.cyan, Theme.green]
    ),
    ConstructionOSNetworkPost(
        authorName: "Priya Nair", authorRole: "Project Manager · LEED AP",
        authorTrade: .general, postType: .workUpdate,
        content: "Day 180 on the Eastside Medical Center. MEP rough-in is 92% complete ahead of the drywall sequence. Running 6 days ahead of schedule — shoutout to the Phoenix MEP crew for the push this week.",
        tags: ["#Healthcare", "#MEP", "#LEED"],
        timeAgo: "6h ago", likes: 93, comments: 18,
        projectRef: "Eastside Medical Center", initials: "PN",
        avatarColors: [Theme.green, Theme.cyan]
    ),
    ConstructionOSNetworkPost(
        authorName: "TruBuild Electrical", authorRole: "Electrical Contractor",
        authorTrade: .electrical, postType: .jobPosting,
        content: "NOW HIRING — Journeyman Electricians (4 positions) for a data center project in Austin, TX. 12-month contract, $42–$48/hr DOE. Per diem available. IBEW card preferred but not required.",
        tags: ["#Hiring", "#Electrician", "#AustinTX", "#DataCenter"],
        timeAgo: "8h ago", likes: 112, comments: 58,
        projectRef: nil, initials: "TE",
        avatarColors: [Theme.gold, Theme.accent]
    ),
    ConstructionOSNetworkPost(
        authorName: "Darnell Washington", authorRole: "Concrete Foreman · 21 yrs",
        authorTrade: .concrete, postType: .shoutout,
        content: "Huge shoutout to my pour crew — 8,400 SF mat slab in 11 hours straight. Not a single cold joint. This is what it looks like when you trust your team. 🏆",
        tags: ["#ConcreteCrew", "#Foundation", "#SiteLife"],
        timeAgo: "12h ago", likes: 247, comments: 89,
        projectRef: "Central District Highrise", initials: "DW",
        avatarColors: [Theme.red, Theme.gold]
    ),
    ConstructionOSNetworkPost(
        authorName: "Apex MEP Solutions", authorRole: "Mechanical Contractor",
        authorTrade: .hvac, postType: .workUpdate,
        content: "HVAC main trunk install complete on floors 12–24 of the Gateway Office Tower. BIM coordination saved us 340 hours of rework this phase. The model doesn't lie.",
        tags: ["#HVAC", "#BIM", "#MEP"],
        timeAgo: "1d ago", likes: 61, comments: 14,
        projectRef: "Gateway Office Tower", initials: "AM",
        avatarColors: [Theme.cyan, Theme.purple]
    ),
]

private let mockConstructionOSNetworkCrew: [ConstructionOSNetworkCrewMember] = [
    ConstructionOSNetworkCrewMember(name: "Jerome Okafor",   trade: .crane,      role: "Tower Crane Operator",       yearsExp: 18, location: "Chicago, IL",  rating: 4.9, jobsDone: 94,  socialHealthScore: 92, workEthicScore: 96, socialHealthTrend7d: [88, 89, 89, 90, 91, 92, 92], workEthicTrend7d: [93, 93, 94, 94, 95, 95, 96], available: true,  badge: "NCCCO Certified",  connections: 312, initials: "JO"),
    ConstructionOSNetworkCrewMember(name: "Sofia Mendez",    trade: .electrical, role: "Master Electrician",          yearsExp: 14, location: "Dallas, TX",   rating: 4.8, jobsDone: 127, socialHealthScore: 94, workEthicScore: 92, socialHealthTrend7d: [90, 91, 92, 92, 93, 93, 94], workEthicTrend7d: [90, 90, 91, 91, 92, 92, 92], available: true,  badge: "IBEW L20",         connections: 488, initials: "SM"),
    ConstructionOSNetworkCrewMember(name: "Kevin Park",      trade: .plumbing,   role: "Plumbing Foreman",            yearsExp: 11, location: "Seattle, WA",  rating: 4.7, jobsDone: 83,  socialHealthScore: 79, workEthicScore: 84, socialHealthTrend7d: [82, 82, 81, 81, 80, 79, 79], workEthicTrend7d: [86, 86, 85, 85, 84, 84, 84], available: false, badge: "Master Plumber",   connections: 201, initials: "KP"),
    ConstructionOSNetworkCrewMember(name: "Asha Williams",   trade: .steel,      role: "Structural Detailer",         yearsExp: 9,  location: "Atlanta, GA",  rating: 4.9, jobsDone: 61,  socialHealthScore: 87, workEthicScore: 90, socialHealthTrend7d: [84, 84, 85, 86, 86, 87, 87], workEthicTrend7d: [87, 88, 88, 89, 89, 90, 90], available: true,  badge: "AWS Certified",    connections: 274, initials: "AW"),
    ConstructionOSNetworkCrewMember(name: "Tomás Fuentes",   trade: .concrete,   role: "Concrete Superintendent",     yearsExp: 22, location: "Phoenix, AZ",  rating: 5.0, jobsDone: 148, socialHealthScore: 91, workEthicScore: 95, socialHealthTrend7d: [88, 89, 89, 90, 90, 91, 91], workEthicTrend7d: [92, 93, 93, 94, 94, 95, 95], available: true,  badge: "ACI Grade 1",      connections: 390, initials: "TF"),
    ConstructionOSNetworkCrewMember(name: "Rachel Kim",      trade: .hvac,       role: "HVAC Lead Technician",        yearsExp: 8,  location: "Denver, CO",   rating: 4.6, jobsDone: 54,  socialHealthScore: 77, workEthicScore: 82, socialHealthTrend7d: [80, 80, 79, 79, 78, 78, 77], workEthicTrend7d: [84, 84, 83, 83, 83, 82, 82], available: false, badge: "EPA 608",          connections: 165, initials: "RK"),
    ConstructionOSNetworkCrewMember(name: "DeShawn Morris",  trade: .roofing,    role: "Roofing Foreman",             yearsExp: 16, location: "Miami, FL",    rating: 4.8, jobsDone: 109, socialHealthScore: 85, workEthicScore: 88, socialHealthTrend7d: [82, 82, 83, 84, 84, 85, 85], workEthicTrend7d: [85, 86, 86, 87, 87, 88, 88], available: true,  badge: "NRCA Certified",   connections: 258, initials: "DM"),
]

private let mockConstructionOSNetworkJobs: [ConstructionOSNetworkJobListing] = [
    ConstructionOSNetworkJobListing(title: "Concrete Superintendent",    company: "Trident Construction",   trade: .concrete,   location: "Las Vegas, NV", payRate: "$95–$115K/yr", startDate: "Mar 24",    duration: "18 months", urgent: true,  applicants: 7,  requirements: ["ACI certified", "10+ yrs high-rise", "OSHA 30"]),
    ConstructionOSNetworkJobListing(title: "Journeyman Electrician",     company: "TruBuild Electrical",    trade: .electrical, location: "Austin, TX",    payRate: "$42–$48/hr",   startDate: "Apr 1",     duration: "12 months", urgent: false, applicants: 23, requirements: ["IBEW preferred", "Commercial exp", "Lift cert"]),
    ConstructionOSNetworkJobListing(title: "Tower Crane Operator",       company: "Skyline Lift Solutions", trade: .crane,      location: "New York, NY",  payRate: "$85–$105/hr",  startDate: "Immediate", duration: "24 months", urgent: true,  applicants: 3,  requirements: ["NCCCO certified", "NYC DOB approved", "5+ yrs high-rise"]),
    ConstructionOSNetworkJobListing(title: "Structural Steel Foreman",   company: "Atlas Iron Works",       trade: .steel,      location: "Houston, TX",   payRate: "$88–$102K/yr", startDate: "Apr 15",    duration: "14 months", urgent: false, applicants: 11, requirements: ["AISC knowledge", "AWS D1.1", "15+ crew exp"]),
    ConstructionOSNetworkJobListing(title: "HVAC Project Manager",       company: "Apex MEP Solutions",     trade: .hvac,       location: "Denver, CO",    payRate: "$110–$130K/yr", startDate: "May 1",    duration: "Full-time", urgent: false, applicants: 5,  requirements: ["PE or LEED AP", "BIM/Revit MEP", "PMP preferred"]),
    ConstructionOSNetworkJobListing(title: "Plumbing Foreman",           company: "Summit Mechanical",      trade: .plumbing,   location: "Portland, OR",  payRate: "$75–$90K/yr",  startDate: "Mar 31",    duration: "10 months", urgent: true,  applicants: 9,  requirements: ["Master plumber lic.", "Commercial exp", "OSHA 30"]),
]

struct ConstructionOSNetworkLiveSeed {
    let authorName: String
    let authorRole: String
    let trade: ConstructionOSNetworkTrade
    let postType: ConstructionOSNetworkPostType
    let content: String
    let tags: [String]
    let projectRef: String?
}

private let constructionOSNetworkLiveSeeds: [ConstructionOSNetworkLiveSeed] = [
    ConstructionOSNetworkLiveSeed(authorName: "Skyline Lift Ops", authorRole: "Crane Operations", trade: .crane, postType: .workUpdate, content: "Tower crane #2 back online after wind hold release. Steel picks resumed on north core.", tags: ["#CraneOps", "#LiveSite"], projectRef: "Harborview Tower"),
    ConstructionOSNetworkLiveSeed(authorName: "TruBuild Electrical", authorRole: "Electrical Contractor", trade: .electrical, postType: .workUpdate, content: "Power-up complete for level 5 switchgear. Field verification signed and released.", tags: ["#Electrical", "#Commissioning"], projectRef: "Eastside Medical Center"),
    ConstructionOSNetworkLiveSeed(authorName: "Delta Build Group", authorRole: "General Contractor", trade: .general, postType: .bidOpportunity, content: "Live package release: interior framing + drywall bundle now open for fast-track pricing.", tags: ["#BidRelease", "#FastTrack"], projectRef: "Phoenix Residential Phase 2"),
    ConstructionOSNetworkLiveSeed(authorName: "Apex MEP Solutions", authorRole: "Mechanical Contractor", trade: .hvac, postType: .projectWin, content: "Inspection passed for AHU tie-in sequence. Zero punch items on turnover.", tags: ["#MEP", "#ProjectWin"], projectRef: "Gateway Office Tower"),
]

@MainActor
final class ConstructionOSNetworkService: ObservableObject {
    @Published var posts: [ConstructionOSNetworkPost] = mockConstructionOSNetworkPosts

    private let storageKey = "ConstructOS.Network.State.v1"
    @Published private var likedPostKeys: Set<String> = []
    @Published private var followedCrewKeys: Set<String> = []
    @Published private var appliedJobKeys: Set<String> = []
    @Published private var commentsByPostKey: [String: [ConstructionOSNetworkComment]] = [:]
    @Published private var persistedPosts: [PersistedPost] = []

    init() {
        loadState()
    }

    func isLiked(_ post: ConstructionOSNetworkPost) -> Bool {
        likedPostKeys.contains(postKey(post))
    }

    func isFollowing(_ member: ConstructionOSNetworkCrewMember) -> Bool {
        followedCrewKeys.contains(crewKey(member))
    }

    func hasApplied(_ job: ConstructionOSNetworkJobListing) -> Bool {
        appliedJobKeys.contains(jobKey(job))
    }

    func publishPost(text: String, postType: ConstructionOSNetworkPostType, trade: ConstructionOSNetworkTrade) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let hashtags = extractTags(from: trimmed)
        let newPost = ConstructionOSNetworkPost(
            authorName: "You",
            authorRole: "ConstructionOS Member",
            authorTrade: trade,
            postType: postType,
            content: trimmed,
            tags: hashtags,
            timeAgo: "just now",
            likes: 0,
            comments: 0,
            projectRef: nil,
            initials: "YOU",
            avatarColors: [Theme.accent, Theme.cyan]
        )

        persistedPosts.insert(
            PersistedPost(
                authorName: newPost.authorName,
                authorRole: newPost.authorRole,
                authorTrade: newPost.authorTrade.rawValue,
                postType: newPost.postType.rawValue,
                content: newPost.content,
                tags: newPost.tags,
                timeAgo: newPost.timeAgo,
                likes: newPost.likes,
                comments: newPost.comments,
                projectRef: newPost.projectRef,
                initials: newPost.initials
            ),
            at: 0
        )
        posts.insert(newPost, at: 0)
        saveState()
    }

    func injectLivePost(seed: ConstructionOSNetworkLiveSeed) {
        let newPost = ConstructionOSNetworkPost(
            authorName: seed.authorName,
            authorRole: seed.authorRole,
            authorTrade: seed.trade,
            postType: seed.postType,
            content: seed.content,
            tags: seed.tags,
            timeAgo: "just now",
            likes: 0,
            comments: 0,
            projectRef: seed.projectRef,
            initials: String(seed.authorName.prefix(2)).uppercased(),
            avatarColors: [Theme.cyan, Theme.green]
        )
        posts.insert(newPost, at: 0)
        saveState()
    }

    func toggleLike(post: ConstructionOSNetworkPost) {
        let key = postKey(post)
        if likedPostKeys.contains(key) {
            likedPostKeys.remove(key)
        } else {
            likedPostKeys.insert(key)
        }
        saveState()
    }

    func toggleFollow(member: ConstructionOSNetworkCrewMember) {
        let key = crewKey(member)
        if followedCrewKeys.contains(key) {
            followedCrewKeys.remove(key)
        } else {
            followedCrewKeys.insert(key)
        }
        saveState()
    }

    func applyToJob(job: ConstructionOSNetworkJobListing) {
        appliedJobKeys.insert(jobKey(job))
        saveState()
    }

    func addComment(post: ConstructionOSNetworkPost, text: String, photoData: Data? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty || photoData != nil else { return }
        let key = postKey(post)
        let comment = ConstructionOSNetworkComment(
            authorName: "You",
            text: trimmed.isEmpty ? "Photo attachment" : trimmed,
            timeAgo: "now",
            photoData: photoData
        )
        commentsByPostKey[key, default: []].append(comment)
        saveState()
    }

    func comments(for post: ConstructionOSNetworkPost) -> [ConstructionOSNetworkComment] {
        commentsByPostKey[postKey(post)] ?? []
    }

    func totalComments(for post: ConstructionOSNetworkPost) -> Int {
        post.comments + (commentsByPostKey[postKey(post)]?.count ?? 0)
    }

    private func postKey(_ post: ConstructionOSNetworkPost) -> String {
        "\(post.authorName)|\(post.authorRole)|\(post.content)|\(post.timeAgo)"
    }

    private func crewKey(_ member: ConstructionOSNetworkCrewMember) -> String {
        "\(member.name)|\(member.role)|\(member.location)"
    }

    private func jobKey(_ job: ConstructionOSNetworkJobListing) -> String {
        "\(job.title)|\(job.company)|\(job.location)|\(job.startDate)"
    }

    private func loadState() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let snapshot = try? JSONDecoder().decode(ConstructionOSNetworkSnapshot.self, from: data)
        else {
            posts = mockConstructionOSNetworkPosts
            return
        }

        likedPostKeys = Set(snapshot.likedPostKeys)
        followedCrewKeys = Set(snapshot.followedCrewKeys)
        appliedJobKeys = Set(snapshot.appliedJobKeys)
        commentsByPostKey = Dictionary(
            uniqueKeysWithValues: snapshot.commentsByPostKey.map { key, values in
                    (
                        key,
                        values.map {
                            ConstructionOSNetworkComment(
                                authorName: $0.authorName,
                                text: $0.text,
                                timeAgo: $0.timeAgo,
                                photoData: $0.photoData
                            )
                        }
                    )
                }
        )
        persistedPosts = snapshot.persistedPosts

        let restored = persistedPosts.map { persisted -> ConstructionOSNetworkPost in
            let trade = ConstructionOSNetworkTrade(rawValue: persisted.authorTrade) ?? .general
            let type = ConstructionOSNetworkPostType(rawValue: persisted.postType) ?? .workUpdate
            return ConstructionOSNetworkPost(
                authorName: persisted.authorName,
                authorRole: persisted.authorRole,
                authorTrade: trade,
                postType: type,
                content: persisted.content,
                tags: persisted.tags,
                timeAgo: persisted.timeAgo,
                likes: persisted.likes,
                comments: persisted.comments,
                projectRef: persisted.projectRef,
                initials: persisted.initials,
                avatarColors: [Theme.accent, Theme.cyan]
            )
        }

        posts = restored + mockConstructionOSNetworkPosts
    }

    private func saveState() {
        let commentSnapshot = Dictionary(
            uniqueKeysWithValues: commentsByPostKey.map { key, values in
                    (
                        key,
                        values.map {
                            PersistedComment(
                                authorName: $0.authorName,
                                text: $0.text,
                                timeAgo: $0.timeAgo,
                                photoData: $0.photoData
                            )
                        }
                    )
                }
        )

        let snapshot = ConstructionOSNetworkSnapshot(
            likedPostKeys: Array(likedPostKeys),
            followedCrewKeys: Array(followedCrewKeys),
            appliedJobKeys: Array(appliedJobKeys),
            commentsByPostKey: commentSnapshot,
            persistedPosts: persistedPosts
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private func extractTags(from text: String) -> [String] {
        text.split(separator: " ")
            .map(String.init)
            .filter { $0.hasPrefix("#") && $0.count > 1 }
            .prefix(4)
            .map { $0 }
    }

    private struct PersistedComment: Codable {
        let authorName: String
        let text: String
        let timeAgo: String
        let photoData: Data?

        init(authorName: String, text: String, timeAgo: String, photoData: Data? = nil) {
            self.authorName = authorName
            self.text = text
            self.timeAgo = timeAgo
            self.photoData = photoData
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            authorName = try container.decode(String.self, forKey: .authorName)
            text = try container.decode(String.self, forKey: .text)
            timeAgo = try container.decode(String.self, forKey: .timeAgo)
            photoData = try container.decodeIfPresent(Data.self, forKey: .photoData)
        }
    }

    private struct PersistedPost: Codable {
        let authorName: String
        let authorRole: String
        let authorTrade: String
        let postType: String
        let content: String
        let tags: [String]
        let timeAgo: String
        let likes: Int
        let comments: Int
        let projectRef: String?
        let initials: String
    }

    private struct ConstructionOSNetworkSnapshot: Codable {
        let likedPostKeys: [String]
        let followedCrewKeys: [String]
        let appliedJobKeys: [String]
        let commentsByPostKey: [String: [PersistedComment]]
        let persistedPosts: [PersistedPost]
    }
}

enum ConstructionOSNetworkLiveMode: String, CaseIterable {
    case off = "Off"
    case normal = "Normal"
    case highActivity = "High"

    var interval: TimeInterval {
        switch self {
        case .off: return .infinity
        case .normal: return 8
        case .highActivity: return 3
        }
    }

    var accentColor: Color {
        switch self {
        case .off: return Theme.muted
        case .normal: return Theme.green
        case .highActivity: return Theme.red
        }
    }
}

struct ConstructionOSNetworkPanel: View {
    @StateObject private var backend = ConstructionOSNetworkService()
    @State private var activeTab: String = "Feed"
    @State private var selectedTrade: String = "All"
    @State private var showCompose: Bool = false
    @State private var composeText: String = ""
    @State private var composeType: ConstructionOSNetworkPostType = .workUpdate
    @State private var commentDrafts: [UUID: String] = [:]
    @State private var commentPhotoSelections: [UUID: PhotosPickerItem] = [:]
    @State private var commentPhotoDrafts: [UUID: Data] = [:]
    @State private var commentAttachmentStatuses: [UUID: String] = [:]
    @State private var searchText: String = ""
    @State private var liveOnlineCount: Int = 2400
    @State private var livePulseText: String = "Live pulse online"
    @State private var livePulseColor: Color = Theme.green
    @State private var liveEventsCount: Int = 0
    @State private var liveTickCount: Int = 0
    @State private var liveMode: ConstructionOSNetworkLiveMode = .normal
    @State private var lastLiveCycleAt: Date = .distantPast

    private let tabs = ["Feed", "Crew", "Jobs"]
    private let tradeFilters = ["All"] + ConstructionOSNetworkTrade.allCases.map(\.rawValue)
    private let liveTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let maxCommentPhotoBytes = 1_500_000

    private let livePulseMessages: [(text: String, color: Color)] = [
        ("Permit inspection marked complete on active site", Theme.green),
        ("New bid request posted by a GC in your network", Theme.accent),
        ("Safety update published from field team", Theme.cyan),
        ("Crew availability changed in your selected trade", Theme.gold),
    ]

    private var filteredPosts: [ConstructionOSNetworkPost] {
        let base = selectedTrade == "All" ? backend.posts : backend.posts.filter { $0.authorTrade.rawValue == selectedTrade }
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.authorName.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText) ||
            $0.tags.joined().localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredCrew: [ConstructionOSNetworkCrewMember] {
        let base = selectedTrade == "All" ? mockConstructionOSNetworkCrew : mockConstructionOSNetworkCrew.filter { $0.trade.rawValue == selectedTrade }
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.role.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var filteredJobs: [ConstructionOSNetworkJobListing] {
        let base = selectedTrade == "All" ? mockConstructionOSNetworkJobs : mockConstructionOSNetworkJobs.filter { $0.trade.rawValue == selectedTrade }
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.company.localizedCaseInsensitiveContains(searchText) ||
            $0.location.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            HStack(spacing: 8) {
                DashboardPanelHeading(
                    eyebrow: "NETWORK",
                    title: "Construction OS Network",
                    detail: "Social signal for crews, jobs, bid flow, and field updates across the construction network.",
                    accent: Theme.accent
                )
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(Theme.green).frame(width: 6, height: 6)
                    Text("\(liveOnlineCount) ONLINE").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.green)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Theme.green.opacity(0.12)).cornerRadius(10)
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 10)

            HStack(spacing: 8) {
                DashboardStatPill(value: "\(liveOnlineCount)", label: "ONLINE", color: Theme.green)
                DashboardStatPill(value: "\(liveEventsCount)", label: "LIVE EVENTS", color: livePulseColor)
                DashboardStatPill(value: activeTab.uppercased(), label: "ACTIVE VIEW", color: Theme.accent)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            HStack(spacing: 8) {
                Text("LIVE")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(livePulseColor)
                    .cornerRadius(4)

                Text(livePulseText)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(livePulseColor)
                    .lineLimit(1)

                Spacer()

                Text("EVENTS \(liveEventsCount)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Theme.muted)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)
            .overlay(Rectangle().fill(Theme.border.opacity(0.45)).frame(height: 1), alignment: .bottom)

            HStack(spacing: 6) {
                Text("MODE")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(Theme.muted)

                ForEach(ConstructionOSNetworkLiveMode.allCases, id: \.rawValue) { mode in
                    Button(action: {
                        liveMode = mode
                        if mode == .off {
                            livePulseText = "Live feed paused"
                            livePulseColor = Theme.muted
                        } else {
                            livePulseText = mode == .normal ? "Live pulse online" : "High activity monitoring"
                            livePulseColor = mode.accentColor
                            lastLiveCycleAt = .distantPast
                        }
                    }) {
                        Text(mode.rawValue.uppercased())
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(liveMode == mode ? .black : mode.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(liveMode == mode ? mode.accentColor : mode.accentColor.opacity(0.14))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 10)

            // ── Stats strip ─────────────────────────────────────────────────
            HStack(spacing: 0) {
                BNStatChip(value: "48.6K", label: "Members",    color: Theme.accent)
                Rectangle().fill(Theme.border).frame(width: 1, height: 28)
                BNStatChip(value: "312",   label: "Open Jobs",  color: Theme.cyan)
                Rectangle().fill(Theme.border).frame(width: 1, height: 28)
                BNStatChip(value: "94",    label: "Bid Requests", color: Theme.gold)
                Rectangle().fill(Theme.border).frame(width: 1, height: 28)
                BNStatChip(value: "1.2K",  label: "Posts Today", color: Theme.green)
            }
            .padding(.horizontal, 14).padding(.bottom, 10)

            // ── Compose ─────────────────────────────────────────────────────
            if showCompose {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("COMPOSE POST").font(.system(size: 10, weight: .bold)).foregroundColor(Theme.accent)
                        Spacer()
                        Button(action: { withAnimation { showCompose = false; composeText = "" } }) {
                            Text("✕").font(.system(size: 12)).foregroundColor(Theme.muted)
                        }.buttonStyle(.plain)
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(ConstructionOSNetworkPostType.allCases, id: \.rawValue) { type in
                                Button(action: { composeType = type }) {
                                    HStack(spacing: 4) {
                                        Text(type.icon).font(.system(size: 10))
                                        Text(type.rawValue).font(.system(size: 9, weight: .semibold))
                                    }
                                    .foregroundColor(composeType == type ? .black : type.color)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(composeType == type ? type.color : type.color.opacity(0.12))
                                    .cornerRadius(6)
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    TextEditor(text: $composeText)
                        .font(.system(size: 12)).foregroundColor(Theme.text)
                        .scrollContentBackground(.hidden).background(Theme.surface)
                        .frame(height: 72).padding(6)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                        .cornerRadius(8)
                    HStack {
                        Text("\(composeText.count)/500").font(.system(size: 9)).foregroundColor(Theme.muted)
                        Spacer()
                        Button(action: {
                            backend.publishPost(text: composeText, postType: composeType, trade: selectedTradeModel)
                            withAnimation { showCompose = false; composeText = "" }
                        }) {
                            Text("PUBLISH")
                                .font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .background(composeText.isEmpty ? Theme.muted : Theme.accent)
                                .cornerRadius(6)
                        }.buttonStyle(.plain).disabled(composeText.isEmpty)
                    }
                }
                .padding(12)
                .background(Theme.surface.opacity(0.9))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                .cornerRadius(10)
                .padding(.horizontal, 14).padding(.bottom, 8)
            } else {
                Button(action: { withAnimation(.spring()) { showCompose = true } }) {
                    HStack(spacing: 8) {
                        LinearGradient(colors: [Theme.accent, Theme.cyan], startPoint: .leading, endPoint: .trailing)
                            .frame(width: 30, height: 30).cornerRadius(15)
                            .overlay(Text("YOU").font(.system(size: 7, weight: .black)).foregroundColor(.black))
                        Text("Share an update, find crew, post a bid request...")
                            .font(.system(size: 12)).foregroundColor(Theme.muted)
                        Spacer()
                        Text("POST").font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(Theme.accent).cornerRadius(6)
                    }
                    .padding(10).background(Theme.surface)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.border, lineWidth: 1))
                    .cornerRadius(10)
                }.buttonStyle(.plain)
                .padding(.horizontal, 14).padding(.bottom, 8)
            }

            // ── Tab bar ─────────────────────────────────────────────────────
            HStack(spacing: 0) {
                ForEach(tabs, id: \.self) { tab in
                    Button(action: { activeTab = tab }) {
                        VStack(spacing: 2) {
                            Text(tab.uppercased()).font(.system(size: 10, weight: .bold))
                                .foregroundColor(activeTab == tab ? Theme.accent : Theme.muted)
                            Rectangle().fill(activeTab == tab ? Theme.accent : Color.clear).frame(height: 2)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                    }.buttonStyle(.plain)
                }
            }
            .background(Theme.surface)
            .overlay(Rectangle().fill(Theme.border).frame(height: 1), alignment: .bottom)

            // ── Search + trade filter ────────────────────────────────────────
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass").font(.system(size: 11)).foregroundColor(Theme.muted)
                    TextField(
                        activeTab == "Feed" ? "Search posts, hashtags, members..." :
                        activeTab == "Crew" ? "Search by name, trade, location..." :
                                             "Search jobs, companies, locations...",
                        text: $searchText
                    ).font(.system(size: 12)).foregroundColor(Theme.text)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 11)).foregroundColor(Theme.muted)
                        }.buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(Theme.panel)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.border, lineWidth: 1))
                .cornerRadius(8)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tradeFilters, id: \.self) { trade in
                            Button(action: { selectedTrade = trade }) {
                                Text(trade).font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(selectedTrade == trade ? .black : Theme.text)
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(selectedTrade == trade ? Theme.accent : Theme.surface)
                                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(
                                        selectedTrade == trade ? Theme.accent : Theme.border, lineWidth: 1))
                                    .cornerRadius(6)
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 10)

            // ── Content ─────────────────────────────────────────────────────
            if activeTab == "Feed" {
                VStack(spacing: 10) {
                    if filteredPosts.isEmpty {
                        Text("No posts match your filters.")
                            .font(.system(size: 12)).foregroundColor(Theme.muted)
                            .frame(maxWidth: .infinity).padding(20)
                    } else {
                        ForEach(filteredPosts) { post in
                            ConstructionOSPostCard(
                                post: post,
                                isLiked: backend.isLiked(post),
                                commentCount: backend.totalComments(for: post),
                                comments: backend.comments(for: post),
                                commentDraft: Binding(
                                    get: { commentDrafts[post.id, default: ""] },
                                    set: { commentDrafts[post.id] = $0 }
                                ),
                                commentPhotoItem: commentPhotoSelectionBinding(for: post.id),
                                pendingCommentPhotoData: commentPhotoDrafts[post.id],
                                commentAttachmentStatus: commentAttachmentStatuses[post.id],
                                onLike: { backend.toggleLike(post: post) },
                                onRemoveCommentPhoto: { removeCommentPhoto(for: post.id) },
                                onSubmitComment: {
                                    let draft = commentDrafts[post.id, default: ""]
                                    let photoData = commentPhotoDrafts[post.id]
                                    backend.addComment(post: post, text: draft, photoData: photoData)
                                    commentDrafts[post.id] = ""
                                    commentPhotoDrafts[post.id] = nil
                                    commentPhotoSelections[post.id] = nil
                                    commentAttachmentStatuses[post.id] = nil
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 14)

            } else if activeTab == "Crew" {
                VStack(spacing: 10) {
                    if filteredCrew.isEmpty {
                        Text("No crew members match your filters.")
                            .font(.system(size: 12)).foregroundColor(Theme.muted)
                            .frame(maxWidth: .infinity).padding(20)
                    } else {
                        ForEach(filteredCrew) { member in
                            BNCrewCard(member: member, isConnected: backend.isFollowing(member)) {
                                backend.toggleFollow(member: member)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 14)

            } else {
                VStack(spacing: 10) {
                    if filteredJobs.isEmpty {
                        Text("No job listings match your filters.")
                            .font(.system(size: 12)).foregroundColor(Theme.muted)
                            .frame(maxWidth: .infinity).padding(20)
                    } else {
                        ForEach(filteredJobs) { job in
                            BNJobCard(job: job, hasApplied: backend.hasApplied(job)) {
                                backend.applyToJob(job: job)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14).padding(.bottom, 14)
            }
        }
        .background(Theme.panel)
        .premiumGlow(cornerRadius: 16, color: Theme.accent)
        .onReceive(liveTimer) { _ in
            guard liveMode != .off else { return }

            let now = Date()
            guard now.timeIntervalSince(lastLiveCycleAt) >= liveMode.interval else { return }
            lastLiveCycleAt = now

            liveTickCount += 1
            let onlineDeltaRange: ClosedRange<Int> = liveMode == .highActivity ? -20...34 : -12...20
            liveOnlineCount = max(1700, min(3900, liveOnlineCount + Int.random(in: onlineDeltaRange)))

            if let pulse = livePulseMessages.randomElement() {
                livePulseText = pulse.text
                livePulseColor = pulse.color
            }

            if liveTickCount % 2 == 0 {
                liveEventsCount += 1
            }

            if Int.random(in: 0...3) == 0, let seed = constructionOSNetworkLiveSeeds.randomElement() {
                backend.injectLivePost(seed: seed)
                livePulseText = "New live post from \(seed.authorName)"
                livePulseColor = Theme.accent
                liveEventsCount += 1
            }
        }
    }

    private func commentPhotoSelectionBinding(for postID: UUID) -> Binding<PhotosPickerItem?> {
        Binding(
            get: { commentPhotoSelections[postID] },
            set: { newValue in
                commentPhotoSelections[postID] = newValue
                loadCommentPhoto(for: postID, item: newValue)
            }
        )
    }

    private func loadCommentPhoto(for postID: UUID, item: PhotosPickerItem?) {
        guard let item else {
            commentPhotoDrafts[postID] = nil
            commentAttachmentStatuses[postID] = nil
            return
        }

        Task {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                await MainActor.run {
                    commentPhotoDrafts[postID] = nil
                    commentPhotoSelections[postID] = nil
                    commentAttachmentStatuses[postID] = "Could not load selected photo."
                }
                return
            }

            await MainActor.run {
                if data.count > maxCommentPhotoBytes {
                    let limit = ByteCountFormatter.string(fromByteCount: Int64(maxCommentPhotoBytes), countStyle: .file)
                    commentPhotoDrafts[postID] = nil
                    commentPhotoSelections[postID] = nil
                    commentAttachmentStatuses[postID] = "Photo too large. Max \(limit)."
                } else {
                    commentPhotoDrafts[postID] = data
                    let size = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
                    commentAttachmentStatuses[postID] = "Photo attached (\(size))."
                }
            }
        }
    }

    private func removeCommentPhoto(for postID: UUID) {
        commentPhotoSelections[postID] = nil
        commentPhotoDrafts[postID] = nil
        commentAttachmentStatuses[postID] = nil
    }

    private var selectedTradeModel: ConstructionOSNetworkTrade {
        ConstructionOSNetworkTrade(rawValue: selectedTrade) ?? .general
    }
}

// MARK: Construction OS Network Subviews

struct BNStatChip: View {
    let value: String
    let label: String
    let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.system(size: 15, weight: .heavy)).foregroundColor(color)
            Text(label).font(.system(size: 9)).foregroundColor(Theme.muted)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 6)
    }
}

struct TrendSparkline: View {
    let values: [Int]
    let color: Color

    private var minValue: Int { values.min() ?? 0 }
    private var maxValue: Int { values.max() ?? 1 }

    private func normalizedHeight(_ value: Int) -> CGFloat {
        if maxValue == minValue { return 8 }
        let ratio = Double(value - minValue) / Double(maxValue - minValue)
        return CGFloat(4 + ratio * 10)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(values.enumerated()), id: \.offset) { _, value in
                Capsule()
                    .fill(color)
                    .frame(width: 3, height: normalizedHeight(value))
            }
        }
        .padding(.vertical, 1)
    }
}

struct ConstructionOSPostCard: View {
    let post: ConstructionOSNetworkPost
    let isLiked: Bool
    let commentCount: Int
    let comments: [ConstructionOSNetworkComment]
    @Binding var commentDraft: String
    @Binding var commentPhotoItem: PhotosPickerItem?
    let pendingCommentPhotoData: Data?
    let commentAttachmentStatus: String?
    let onLike: () -> Void
    let onRemoveCommentPhoto: () -> Void
    let onSubmitComment: () -> Void

    private var canSubmitComment: Bool {
        !commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || pendingCommentPhotoData != nil
    }

    private func image(from data: Data) -> Image? {
#if os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
#elseif os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
#else
        return nil
#endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                LinearGradient(colors: post.postType == .projectWin ? [Theme.gold, Theme.accent] : [Theme.accent, Theme.cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .frame(width: 38, height: 38).cornerRadius(19)
                    .overlay(Text(post.initials).font(.system(size: 11, weight: .heavy)).foregroundColor(.black))
                VStack(alignment: .leading, spacing: 1) {
                    Text(post.authorName).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                    Text(post.authorRole).font(.system(size: 10)).foregroundColor(Theme.muted)
                }
                Spacer()
                HStack(spacing: 3) {
                    Text(post.postType.icon).font(.system(size: 9))
                    Text(post.postType.rawValue.uppercased()).font(.system(size: 8, weight: .bold))
                }
                .foregroundColor(post.postType.color)
                .padding(.horizontal, 7).padding(.vertical, 3)
                .background(post.postType.color.opacity(0.14)).cornerRadius(5)
            }

            if let ref = post.projectRef {
                HStack(spacing: 4) {
                    Image(systemName: "building.2").font(.system(size: 9)).foregroundColor(Theme.cyan)
                    Text(ref).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.cyan)
                }
            }

            Text(post.content)
                .font(.system(size: 12)).foregroundColor(Theme.text)
                .lineSpacing(3).fixedSize(horizontal: false, vertical: true)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(post.tags, id: \.self) { tag in
                        Text(tag).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.accent)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Theme.accent.opacity(0.1)).cornerRadius(4)
                    }
                }
            }

            Rectangle().fill(Theme.border).frame(height: 1)

            HStack(spacing: 0) {
                Button(action: onLike) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "hand.thumbsup.fill" : "hand.thumbsup")
                            .font(.system(size: 11))
                            .foregroundColor(isLiked ? Theme.accent : Theme.muted)
                        Text("\(post.likes + (isLiked ? 1 : 0))")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(isLiked ? Theme.accent : Theme.muted)
                    }.frame(maxWidth: .infinity)
                }.buttonStyle(.plain)

                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left").font(.system(size: 11)).foregroundColor(Theme.muted)
                        Text("\(commentCount)").font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.muted)
                    }.frame(maxWidth: .infinity)
                }.buttonStyle(.plain)

                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrowshape.turn.up.forward").font(.system(size: 11)).foregroundColor(Theme.muted)
                        Text("Share").font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.muted)
                    }.frame(maxWidth: .infinity)
                }.buttonStyle(.plain)

                Text(post.timeAgo).font(.system(size: 9)).foregroundColor(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            if !comments.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(comments.suffix(2))) { comment in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text(comment.authorName.uppercased())
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(Theme.cyan)
                                Text(comment.timeAgo)
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(Theme.muted)
                            }
                            if let photoData = comment.photoData, let commentImage = image(from: photoData) {
                                commentImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 180, height: 120)
                                    .clipped()
                                    .cornerRadius(6)
                            }
                            Text(comment.text)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Theme.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Theme.panel)
                        .cornerRadius(6)
                    }
                }
            }

            if let pendingData = pendingCommentPhotoData, let pendingImage = image(from: pendingData) {
                HStack(spacing: 8) {
                    pendingImage
                        .resizable()
                        .scaledToFill()
                        .frame(width: 68, height: 48)
                        .clipped()
                        .cornerRadius(6)
                    Text("Photo ready")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Theme.muted)
                    Spacer()
                    Button("Remove", action: onRemoveCommentPhoto)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.red)
                        .buttonStyle(.plain)
                }
            }

            if let commentAttachmentStatus {
                Text(commentAttachmentStatus)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(commentAttachmentStatus.contains("too large") ? Theme.red : Theme.muted)
            }

            HStack(spacing: 6) {
                PhotosPicker(selection: $commentPhotoItem, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Theme.gold)
                        .cornerRadius(6)
                }

                TextField("Add comment...", text: $commentDraft)
                    .font(.system(size: 11)).foregroundColor(Theme.text)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(Theme.panel)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Theme.border, lineWidth: 1))
                    .cornerRadius(6)

                Button(action: onSubmitComment) {
                    Text("Send")
                        .font(.system(size: 10, weight: .bold)).foregroundColor(.black)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(canSubmitComment ? Theme.accent : Theme.muted)
                        .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(!canSubmitComment)
            }
        }
        .padding(14).background(Theme.surface)
        .premiumGlow(cornerRadius: 12, color: Theme.border.opacity(0.5))
    }
}

struct BNCrewCard: View {
    let member: ConstructionOSNetworkCrewMember
    let isConnected: Bool
    let onConnect: () -> Void

    private func trendDelta(_ history: [Int]) -> Int {
        guard let first = history.first, let last = history.last else { return 0 }
        return last - first
    }

    private func trendSymbol(_ delta: Int) -> String {
        if delta > 0 { return "↑" }
        if delta < 0 { return "↓" }
        return "→"
    }

    private func trendColor(_ delta: Int) -> Color {
        if delta > 0 { return Theme.green }
        if delta < 0 { return Theme.red }
        return Theme.muted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack(alignment: .bottomTrailing) {
                    LinearGradient(colors: [Theme.cyan, Theme.accent], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .frame(width: 42, height: 42).cornerRadius(21)
                    Text(member.initials).font(.system(size: 12, weight: .heavy)).foregroundColor(.black)
                        .frame(width: 42, height: 42)
                    if member.available {
                        Circle().fill(Theme.green).frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Theme.panel, lineWidth: 2))
                            .offset(x: 2, y: 2)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(member.name).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                        if let badge = member.badge {
                            Text(badge).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.gold)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Theme.gold.opacity(0.12)).cornerRadius(4)
                        }
                    }
                    Text(member.role).font(.system(size: 10)).foregroundColor(Theme.muted)
                    HStack(spacing: 4) {
                        Text(member.trade.icon).font(.system(size: 10))
                        Text(member.trade.rawValue).font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.cyan)
                        Text("·").foregroundColor(Theme.muted).font(.system(size: 10))
                        Image(systemName: "mappin").font(.system(size: 9)).foregroundColor(Theme.muted)
                        Text(member.location).font(.system(size: 10)).foregroundColor(Theme.muted)
                    }
                }
                Spacer()
                Text(member.available ? "AVAILABLE" : "ON PROJECT")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(member.available ? Theme.green : Theme.gold)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background((member.available ? Theme.green : Theme.gold).opacity(0.14))
                    .cornerRadius(5)
            }

            HStack(spacing: 4) {
                Text("WORK ETHIC")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(Theme.muted)
                Text("\(member.workEthicScore)")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(member.workEthicScore >= 90 ? Theme.green : (member.workEthicScore >= 80 ? Theme.cyan : Theme.gold))
                    .cornerRadius(5)
                Text("\(trendSymbol(trendDelta(member.workEthicTrend7d)))\(trendDelta(member.workEthicTrend7d))")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(trendColor(trendDelta(member.workEthicTrend7d)))
                Spacer()
                Text("SOCIAL \(member.socialHealthScore)")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(Theme.muted)
                Text("\(trendSymbol(trendDelta(member.socialHealthTrend7d)))\(trendDelta(member.socialHealthTrend7d))")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(trendColor(trendDelta(member.socialHealthTrend7d)))
            }

            HStack(spacing: 4) {
                TrendSparkline(values: member.workEthicTrend7d, color: Theme.green)
                    .frame(maxWidth: .infinity)
                TrendSparkline(values: member.socialHealthTrend7d, color: Theme.cyan)
                    .frame(maxWidth: .infinity)
            }

            HStack(spacing: 0) {
                VStack(spacing: 2) {
                    Text("\(member.yearsExp)yr").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.accent)
                    Text("Experience").font(.system(size: 9)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity)
                Rectangle().fill(Theme.border).frame(width: 1, height: 28)
                VStack(spacing: 2) {
                    HStack(spacing: 2) {
                        Text("⭐").font(.system(size: 10))
                        Text(String(format: "%.1f", member.rating)).font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.gold)
                    }
                    Text("Rating").font(.system(size: 9)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity)
                Rectangle().fill(Theme.border).frame(width: 1, height: 28)
                VStack(spacing: 2) {
                    Text("\(member.jobsDone)").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.cyan)
                    Text("Jobs Done").font(.system(size: 9)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity)
                Rectangle().fill(Theme.border).frame(width: 1, height: 28)
                VStack(spacing: 2) {
                    Text("\(member.connections)").font(.system(size: 14, weight: .heavy)).foregroundColor(Theme.green)
                    Text("Network").font(.system(size: 9)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity)
            }

            HStack(spacing: 8) {
                Button(action: onConnect) {
                    Text(isConnected ? "✓ Following" : "+ Follow")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isConnected ? .black : Theme.accent)
                        .frame(maxWidth: .infinity).frame(height: 30)
                        .background(isConnected ? Theme.accent : Theme.accent.opacity(0.15))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.accent.opacity(0.5), lineWidth: 1))
                        .cornerRadius(7)
                }.buttonStyle(.plain)
                Button(action: {}) {
                    Text("Message")
                        .font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.cyan)
                        .frame(maxWidth: .infinity).frame(height: 30)
                        .background(Theme.cyan.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.cyan.opacity(0.4), lineWidth: 1))
                        .cornerRadius(7)
                }.buttonStyle(.plain)
            }
        }
        .padding(14).background(Theme.surface)
        .premiumGlow(cornerRadius: 12, color: Theme.cyan.opacity(0.6))
    }
}

struct BNJobCard: View {
    let job: ConstructionOSNetworkJobListing
    let hasApplied: Bool
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(job.title).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                        if job.urgent {
                            Text("URGENT").font(.system(size: 8, weight: .black)).foregroundColor(.black)
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(Theme.red).cornerRadius(4)
                        }
                    }
                    Text(job.company).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.accent)
                    HStack(spacing: 6) {
                        Text(job.trade.icon).font(.system(size: 10))
                        Text(job.trade.rawValue).font(.system(size: 10, weight: .semibold)).foregroundColor(Theme.cyan)
                        Text("·").foregroundColor(Theme.muted).font(.system(size: 10))
                        Image(systemName: "mappin").font(.system(size: 9)).foregroundColor(Theme.muted)
                        Text(job.location).font(.system(size: 10)).foregroundColor(Theme.muted)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(job.payRate).font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.green)
                    Text("\(job.applicants) applied").font(.system(size: 9)).foregroundColor(Theme.muted)
                }
            }

            HStack(spacing: 14) {
                Label(job.startDate, systemImage: "calendar").font(.system(size: 10)).foregroundColor(Theme.muted)
                Label(job.duration,  systemImage: "clock").font(.system(size: 10)).foregroundColor(Theme.muted)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(job.requirements, id: \.self) { req in
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.green)
                            Text(req).font(.system(size: 9, weight: .medium)).foregroundColor(Theme.text)
                        }
                        .padding(.horizontal, 7).padding(.vertical, 3)
                        .background(Theme.green.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.green.opacity(0.25), lineWidth: 1))
                        .cornerRadius(5)
                    }
                }
            }

            HStack(spacing: 8) {
                Button(action: { if !hasApplied { onApply() } }) {
                    Text(hasApplied ? "✓ APPLIED" : "QUICK APPLY")
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.black)
                        .frame(maxWidth: .infinity).frame(height: 30)
                        .background(hasApplied ? Theme.muted : (job.urgent ? Theme.red : Theme.accent))
                        .cornerRadius(7)
                }.buttonStyle(.plain)
                Button(action: {}) {
                    Text("SAVE JOB").font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.gold)
                        .frame(width: 80).frame(height: 30)
                        .background(Theme.gold.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 7).stroke(Theme.gold.opacity(0.35), lineWidth: 1))
                        .cornerRadius(7)
                }.buttonStyle(.plain)
            }
        }
        .padding(14).background(Theme.surface)
        .premiumGlow(cornerRadius: 12, color: job.urgent ? Theme.red.opacity(0.5) : Theme.accent.opacity(0.4))
    }
}
