import SwiftUI
import Combine

// MARK: - ========== Construction Social Network ==========

// MARK: - Feed Post Model

struct FeedPost: Identifiable, Codable {
    var id = UUID()
    let authorName: String
    let authorTitle: String
    let authorCompany: String
    let authorTrade: String
    let authorLocation: String
    let authorInitials: String
    let authorVerified: Bool
    let content: String
    let postType: String       // "update", "hiring", "available", "selling", "project", "story"
    let tags: [String]
    var likes: Int
    var comments: Int
    var shares: Int
    let photoCount: Int
    let timeAgo: String
    let projectRef: String?
    let equipmentListing: EquipmentListing?
    let jobListing: JobPost?
}

struct EquipmentListing: Codable {
    let name: String
    let price: String
    let condition: String
    let hours: String
    let location: String
    let listingType: String   // "sell", "rent"
}

struct JobPost: Codable {
    let title: String
    let company: String
    let trade: String
    let payRate: String
    let location: String
    let type: String          // "fulltime", "contract", "temp"
    let urgent: Bool
}

// MARK: - Story Model

struct UserStory: Identifiable {
    let id = UUID()
    let authorName: String
    let authorInitials: String
    let authorTrade: String
    let site: String
    let timeAgo: String
    let isViewed: Bool
    let photoCount: Int
}

// MARK: - DM Model

struct DirectMessage: Identifiable, Codable {
    var id = UUID()
    let fromName: String
    let fromInitials: String
    let content: String
    let timestamp: Date
    var isRead: Bool
    var delivered: Bool
}

struct DMConversation: Identifiable, Codable {
    var id = UUID()
    let participantName: String
    let participantInitials: String
    let participantTitle: String
    let participantCompany: String
    var messages: [DirectMessage]
    var unreadCount: Int
    let lastActive: String
}

// MARK: - Company Page Model

struct CompanyPage: Identifiable {
    let id = UUID()
    let name: String
    let trade: String
    let location: String
    let employees: String
    let activeProjects: Int
    let revenue: String
    let insurance: String
    let bondingCapacity: String
    let rating: Double
    let verified: Bool
    let description: String
    let specialties: [String]
    let initials: String
}

// MARK: - Project Portfolio

struct ProjectPortfolio: Identifiable {
    let id = UUID()
    let projectName: String
    let role: String
    let client: String
    let value: String
    let duration: String
    let scope: String
    let completionDate: String
    let photoCount: Int
    let tags: [String]
}

// MARK: - Verified Badge Store

@MainActor
final class VerificationStore: ObservableObject {
    /// Backward-compat singleton — prefer @EnvironmentObject injection in views
    static let shared = VerificationStore()
    @Published var isVerified = false
    @AppStorage("ConstructOS.Verification.Active") var verificationActive = false

    static let verificationPrice = "$27.99/mo"
    static let verificationAnnualPrice = "$279.99/yr"

    func requestVerification() {
        // In production: verify license, insurance, project history
        // Charge $27.99/mo via StoreKit
        verificationActive = true
        isVerified = true
    }

    var verificationBenefits: [String] {
        [
            "Verified blue badge on your profile",
            "Priority in search results and suggestions",
            "Verified badge on all posts and job listings",
            "License and insurance verification displayed",
            "Boosted visibility in the network feed",
            "Priority access to job leads and bid requests",
            "Featured in contractor directory",
        ]
    }
}

// MARK: - Mock Feed Data

let mockFeedPosts: [FeedPost] = [
    FeedPost(authorName: "Marcus Rivera", authorTitle: "Senior Superintendent", authorCompany: "PowerGrid Construction", authorTrade: "General", authorLocation: "Houston, TX", authorInitials: "MR", authorVerified: true, content: "Just wrapped structural steel on the Harborview Tower. 47 floors, 14 months, zero LTIs. Crew of 38 made this possible. Proud doesn't cover it.", postType: "update", tags: ["#SteelWork", "#SafetyFirst", "#ZeroIncidents"], likes: 247, comments: 42, shares: 18, photoCount: 4, timeAgo: "2h", projectRef: "Harborview Tower", equipmentListing: nil, jobListing: nil),

    FeedPost(authorName: "Apex Concrete LLC", authorTitle: "Concrete Contractor", authorCompany: "Apex Concrete", authorTrade: "Concrete", authorLocation: "Miami, FL", authorInitials: "AC", authorVerified: true, content: "", postType: "hiring", tags: ["#Hiring", "#ConcreteCrew", "#MiamiJobs"], likes: 89, comments: 31, shares: 45, photoCount: 0, timeAgo: "4h", projectRef: nil, equipmentListing: nil, jobListing: JobPost(title: "Concrete Finisher", company: "Apex Concrete LLC", trade: "Concrete", payRate: "$32-$38/hr", location: "Miami, FL", type: "fulltime", urgent: true)),

    FeedPost(authorName: "Sarah Chen", authorTitle: "Lead Fiber Installer", authorCompany: "FiberLink Solutions", authorTrade: "Fiber Optic", authorLocation: "San Francisco, CA", authorInitials: "SC", authorVerified: true, content: "OTDR test results looking clean on the downtown campus backbone. 68M points, all splices passing. This is what precision looks like.", postType: "update", tags: ["#FiberOptic", "#OTDR", "#DataCenter"], likes: 134, comments: 19, shares: 8, photoCount: 3, timeAgo: "5h", projectRef: "Metro Campus Backbone", equipmentListing: nil, jobListing: nil),

    FeedPost(authorName: "James Washington", authorTitle: "Ironworker Foreman", authorCompany: "Atlas Steel Works", authorTrade: "Steel", authorLocation: "Chicago, IL", authorInitials: "JW", authorVerified: true, content: "", postType: "selling", tags: ["#ForSale", "#Equipment", "#Welding"], likes: 56, comments: 14, shares: 22, photoCount: 6, timeAgo: "8h", projectRef: nil, equipmentListing: EquipmentListing(name: "Lincoln Ranger 330MPX Welder/Generator", price: "$4,200", condition: "Excellent", hours: "420 hrs", location: "Chicago, IL", listingType: "sell"), jobListing: nil),

    FeedPost(authorName: "Derek Torres", authorTitle: "Solar Project Manager", authorCompany: "SunVolt Energy", authorTrade: "Solar", authorLocation: "Phoenix, AZ", authorInitials: "DT", authorVerified: false, content: "240kW commercial array going live this week. Battery storage + EV charging integrated. The future of jobsite power is here.", postType: "project", tags: ["#Solar", "#CleanEnergy", "#EV"], likes: 312, comments: 67, shares: 41, photoCount: 8, timeAgo: "1d", projectRef: "SunVolt Commercial Array", equipmentListing: nil, jobListing: nil),

    FeedPost(authorName: "Kim Nguyen", authorTitle: "Low Voltage Tech Lead", authorCompany: "SecureWire Systems", authorTrade: "Low Voltage", authorLocation: "Seattle, WA", authorInitials: "KN", authorVerified: false, content: "Certified and ready for new projects. 7 years access control, CCTV, and structured cabling. BICSI TECH. Open to contracts in the PNW.", postType: "available", tags: ["#Available", "#LowVoltage", "#Seattle"], likes: 45, comments: 12, shares: 8, photoCount: 0, timeAgo: "1d", projectRef: nil, equipmentListing: nil, jobListing: nil),

    FeedPost(authorName: "Priya Patel", authorTitle: "Master Electrician", authorCompany: "LightSpeed Electric", authorTrade: "Electrical", authorLocation: "New York, NY", authorInitials: "PP", authorVerified: true, content: "Switchgear energization complete on the new data center. 4,000A service, redundant feeds, 99.999% uptime spec. Took 11 months but we nailed it.", postType: "project", tags: ["#Electrical", "#DataCenter", "#PowerUp"], likes: 198, comments: 34, shares: 15, photoCount: 5, timeAgo: "2d", projectRef: "NYC Data Center", equipmentListing: nil, jobListing: nil),

    FeedPost(authorName: "Ashley Williams", authorTitle: "Roofing Foreman", authorCompany: "RoofPro Services", authorTrade: "Roofing", authorLocation: "Dallas, TX", authorInitials: "AW", authorVerified: true, content: "", postType: "selling", tags: ["#ForSale", "#Roofing", "#Equipment"], likes: 33, comments: 8, shares: 11, photoCount: 3, timeAgo: "2d", projectRef: nil, equipmentListing: EquipmentListing(name: "2022 Ford F-350 Flatbed (Roofing setup)", price: "$52,000", condition: "Good", hours: "48K miles", location: "Dallas, TX", listingType: "sell"), jobListing: nil),

    FeedPost(authorName: "Carlos Mendez", authorTitle: "Concrete Superintendent", authorCompany: "Apex Concrete", authorTrade: "Concrete", authorLocation: "Miami, FL", authorInitials: "CM", authorVerified: true, content: "8,400 SF mat slab in 11 hours. Not a single cold joint. This is what trust looks like when your crew has been together 8 years.", postType: "update", tags: ["#Concrete", "#MatSlab", "#CrewGoals"], likes: 421, comments: 89, shares: 52, photoCount: 6, timeAgo: "3d", projectRef: "Central District Highrise", equipmentListing: nil, jobListing: nil),
]

let mockStories: [UserStory] = [
    UserStory(authorName: "Marcus R.", authorInitials: "MR", authorTrade: "General", site: "Harborview", timeAgo: "2h", isViewed: false, photoCount: 5),
    UserStory(authorName: "Sarah C.", authorInitials: "SC", authorTrade: "Fiber", site: "Campus", timeAgo: "4h", isViewed: false, photoCount: 3),
    UserStory(authorName: "Carlos M.", authorInitials: "CM", authorTrade: "Concrete", site: "Central District", timeAgo: "6h", isViewed: true, photoCount: 8),
    UserStory(authorName: "Priya P.", authorInitials: "PP", authorTrade: "Electrical", site: "Data Center", timeAgo: "8h", isViewed: true, photoCount: 4),
    UserStory(authorName: "Derek T.", authorInitials: "DT", authorTrade: "Solar", site: "SunVolt", timeAgo: "12h", isViewed: false, photoCount: 6),
]

let mockDMConversations: [DMConversation] = [
    DMConversation(participantName: "Marcus Rivera", participantInitials: "MR", participantTitle: "Superintendent", participantCompany: "PowerGrid", messages: [
        DirectMessage(fromName: "Marcus Rivera", fromInitials: "MR", content: "Hey, you available for the steel package on Harborview Phase 2?", timestamp: Date().addingTimeInterval(-3600), isRead: true, delivered: true),
        DirectMessage(fromName: "You", fromInitials: "ME", content: "Yeah let me pull the drawings and get back to you tomorrow", timestamp: Date().addingTimeInterval(-1800), isRead: true, delivered: true),
    ], unreadCount: 0, lastActive: "30m ago"),
    DMConversation(participantName: "Sarah Chen", participantInitials: "SC", participantTitle: "Lead Fiber", participantCompany: "FiberLink", messages: [
        DirectMessage(fromName: "Sarah Chen", fromInitials: "SC", content: "Can you send me the specs for the fiber run in Building C? Need to order materials.", timestamp: Date().addingTimeInterval(-7200), isRead: false, delivered: true),
    ], unreadCount: 1, lastActive: "2h ago"),
    DMConversation(participantName: "Carlos Mendez", participantInitials: "CM", participantTitle: "Concrete Super", participantCompany: "Apex", messages: [
        DirectMessage(fromName: "Carlos Mendez", fromInitials: "CM", content: "Pour scheduled for 7AM tomorrow. Pump truck confirmed. Weather looks clear.", timestamp: Date().addingTimeInterval(-14400), isRead: true, delivered: true),
    ], unreadCount: 0, lastActive: "4h ago"),
]

let mockCompanyPages: [CompanyPage] = [
    CompanyPage(name: "PowerGrid Construction", trade: "General Contractor", location: "Houston, TX", employees: "850+", activeProjects: 24, revenue: "$420M", insurance: "$5M GL / $10M Umbrella", bondingCapacity: "$50M single / $150M aggregate", rating: 4.9, verified: true, description: "Full-service general contractor specializing in commercial, healthcare, and data center construction across the Gulf Coast.", specialties: ["Commercial TI", "Healthcare", "Data Centers", "Mixed-Use"], initials: "PG"),
    CompanyPage(name: "Apex Concrete LLC", trade: "Concrete Contractor", location: "Miami, FL", employees: "320+", activeProjects: 12, revenue: "$85M", insurance: "$2M GL / $5M Umbrella", bondingCapacity: "$15M single / $40M aggregate", rating: 4.8, verified: true, description: "Southeast's premier concrete contractor. Post-tension, tilt-up, and high-rise foundations.", specialties: ["Post-Tension", "Tilt-Up", "Mat Foundations", "Structural"], initials: "AC"),
    CompanyPage(name: "FiberLink Solutions", trade: "Fiber Optic Contractor", location: "San Francisco, CA", employees: "180+", activeProjects: 8, revenue: "$42M", insurance: "$2M GL", bondingCapacity: "$10M", rating: 4.9, verified: true, description: "Data center and enterprise fiber infrastructure. BICSI certified. Coast to coast.", specialties: ["Data Center", "Campus Fiber", "FTTH", "5G Small Cell"], initials: "FL"),
]

let mockPortfolios: [ProjectPortfolio] = [
    ProjectPortfolio(projectName: "Harborview Tower", role: "Lead Superintendent", client: "Metro Development", value: "$142M", duration: "14 months", scope: "47-story mixed-use tower, structural steel, MEP, finishes", completionDate: "Mar 2026", photoCount: 24, tags: ["High-Rise", "Steel", "Mixed-Use"]),
    ProjectPortfolio(projectName: "Metro Data Center", role: "Electrical PM", client: "CloudScale Inc", value: "$68M", duration: "11 months", scope: "Tier IV data center, 40MW critical load, redundant power", completionDate: "Jan 2026", photoCount: 18, tags: ["Data Center", "Electrical", "Critical Infrastructure"]),
    ProjectPortfolio(projectName: "Central District Highrise", role: "Concrete Superintendent", client: "Urban Core Holdings", value: "$92M", duration: "18 months", scope: "32-story residential, post-tension slabs, mat foundation", completionDate: "Dec 2025", photoCount: 31, tags: ["Concrete", "High-Rise", "Residential"]),
]

// MARK: - Social Feed View

struct SocialFeedView: View {
    @State private var activeTab = 0
    @State private var feedFilter = "all"
    @ObservedObject var profileStore = UserProfileStore.shared

    private let tabs = ["Feed", "Jobs", "Market", "DMs", "Companies"]

    private var filteredPosts: [FeedPost] {
        switch feedFilter {
        case "hiring": return mockFeedPosts.filter { $0.postType == "hiring" }
        case "selling": return mockFeedPosts.filter { $0.postType == "selling" }
        case "available": return mockFeedPosts.filter { $0.postType == "available" }
        case "projects": return mockFeedPosts.filter { $0.postType == "project" }
        default: return mockFeedPosts
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 10) {
                    if let user = profileStore.currentUser {
                        Circle().fill(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 36, height: 36)
                            .overlay(Text(user.initials).font(.system(size: 12, weight: .heavy)).foregroundColor(.black))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CONSTRUCTION NETWORK").font(.system(size: 11, weight: .bold)).tracking(3).foregroundColor(Theme.accent)
                        Text("\(mockFeedPosts.count) posts today").font(.system(size: 9)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    HStack(spacing: 4) {
                        Circle().fill(Theme.green).frame(width: 6, height: 6)
                        Text("\(mockNetworkUsers.count + 142883) online").font(.system(size: 9)).foregroundColor(Theme.green)
                    }
                }.padding(14).background(Theme.surface).cornerRadius(12)

                // Sub-tabs
                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { i in
                        Button { withAnimation { activeTab = i } } label: {
                            VStack(spacing: 2) {
                                Text(tabs[i].uppercased()).font(.system(size: 9, weight: .bold)).tracking(1)
                                    .foregroundColor(activeTab == i ? Theme.accent : Theme.muted)
                                if i == 3 && mockDMConversations.contains(where: { $0.unreadCount > 0 }) {
                                    Circle().fill(Theme.red).frame(width: 5, height: 5)
                                }
                            }
                            .frame(maxWidth: .infinity).padding(.vertical, 9)
                            .background(activeTab == i ? Theme.accent.opacity(0.08) : Color.clear)
                        }.buttonStyle(.plain)
                    }
                }.background(Theme.surface).cornerRadius(8)

                switch activeTab {
                case 0: feedContent
                case 1: jobBoardContent
                case 2: equipmentMarketContent
                case 3: dmContent
                default: companyPagesContent
                }
            }.padding(16)
        }.background(Theme.bg)
    }

    // MARK: - Feed

    private var feedContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Stories
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    // Your story
                    VStack(spacing: 4) {
                        ZStack {
                            Circle().fill(Theme.surface).frame(width: 56, height: 56)
                            Image(systemName: "plus.circle.fill").font(.system(size: 20)).foregroundColor(Theme.accent)
                        }
                        Text("Your Story").font(.system(size: 8, weight: .bold)).foregroundColor(Theme.muted)
                    }
                    ForEach(mockStories) { story in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(LinearGradient(colors: story.isViewed ? [Theme.muted, Theme.muted] : [Theme.accent, Theme.gold, Theme.cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 58, height: 58)
                                .overlay(Circle().fill(Theme.bg).frame(width: 52, height: 52))
                                .overlay(Text(story.authorInitials).font(.system(size: 14, weight: .heavy)).foregroundColor(story.isViewed ? Theme.muted : Theme.text))
                            Text(story.authorName).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.text).lineLimit(1)
                            Text(story.site).font(.system(size: 7)).foregroundColor(Theme.muted).lineLimit(1)
                        }.frame(width: 62)
                    }
                }
            }

            // Feed filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(["all", "projects", "hiring", "available", "selling"], id: \.self) { f in
                        Button { feedFilter = f } label: {
                            Text(f == "all" ? "ALL" : f.uppercased()).font(.system(size: 9, weight: .bold))
                                .foregroundColor(feedFilter == f ? .black : Theme.text)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(feedFilter == f ? Theme.accent : Theme.surface).cornerRadius(6)
                        }.buttonStyle(.plain)
                    }
                }
            }

            // Posts
            ForEach(filteredPosts) { post in
                FeedPostCard(post: post)
            }
        }
    }

    // MARK: - Job Board

    private var jobBoardContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("JOB BOARD").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.green)
            ForEach(mockFeedPosts.filter { $0.jobListing != nil }) { post in
                if let job = post.jobListing {
                    HStack(spacing: 10) {
                        Circle().fill(job.urgent ? Theme.red.opacity(0.15) : Theme.green.opacity(0.15)).frame(width: 40, height: 40)
                            .overlay(Text(String(job.company.prefix(2)).uppercased()).font(.system(size: 12, weight: .heavy)).foregroundColor(job.urgent ? Theme.red : Theme.green))
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(job.title).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                                if job.urgent { Text("URGENT").font(.system(size: 7, weight: .black)).foregroundColor(.black).padding(.horizontal, 5).padding(.vertical, 2).background(Theme.red).cornerRadius(3) }
                            }
                            Text("\(job.company) \u{2022} \(job.location)").font(.system(size: 9)).foregroundColor(Theme.muted)
                            HStack(spacing: 8) {
                                Text(job.payRate).font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.green)
                                Text(job.type.uppercased()).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.cyan)
                            }
                        }
                        Spacer()
                        Button { } label: {
                            Text("APPLY").font(.system(size: 9, weight: .bold)).foregroundColor(.black)
                                .padding(.horizontal, 12).padding(.vertical, 6).background(Theme.accent).cornerRadius(6)
                        }.buttonStyle(.plain)
                    }.padding(12).background(Theme.surface).cornerRadius(10)
                }
            }

            // Available workers
            Text("AVAILABLE WORKERS").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan).padding(.top, 8)
            ForEach(mockFeedPosts.filter { $0.postType == "available" }) { post in
                HStack(spacing: 10) {
                    Circle().fill(Theme.cyan.opacity(0.15)).frame(width: 36, height: 36)
                        .overlay(Text(post.authorInitials).font(.system(size: 11, weight: .heavy)).foregroundColor(Theme.cyan))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(post.authorName).font(.system(size: 11, weight: .bold)).foregroundColor(Theme.text)
                        Text("\(post.authorTitle) \u{2022} \(post.authorLocation)").font(.system(size: 9)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Text("AVAILABLE").font(.system(size: 8, weight: .black)).foregroundColor(Theme.green)
                }.padding(10).background(Theme.surface).cornerRadius(8)
            }
        }
    }

    // MARK: - Equipment Market

    private var equipmentMarketContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EQUIPMENT MARKETPLACE").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.gold)
            Text("Buy, sell, and rent between users").font(.system(size: 9)).foregroundColor(Theme.muted)

            ForEach(mockFeedPosts.filter { $0.equipmentListing != nil }) { post in
                if let listing = post.equipmentListing {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 8).fill(Theme.panel).frame(width: 60, height: 60)
                                .overlay(Image(systemName: "wrench.and.screwdriver").font(.system(size: 20)).foregroundColor(Theme.gold.opacity(0.5)))
                            VStack(alignment: .leading, spacing: 2) {
                                Text(listing.name).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                                Text("\(listing.condition) \u{2022} \(listing.hours)").font(.system(size: 9)).foregroundColor(Theme.muted)
                                Text(listing.location).font(.system(size: 9)).foregroundColor(Theme.muted)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(listing.price).font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.accent)
                                Text(listing.listingType == "rent" ? "FOR RENT" : "FOR SALE").font(.system(size: 8, weight: .black)).foregroundColor(listing.listingType == "rent" ? Theme.cyan : Theme.gold)
                            }
                        }
                        HStack(spacing: 4) {
                            Text("Listed by \(post.authorName)").font(.system(size: 9)).foregroundColor(Theme.muted)
                            if post.authorVerified { Image(systemName: "checkmark.seal.fill").font(.system(size: 8)).foregroundColor(Theme.cyan) }
                            Spacer()
                            Button { } label: { Text("CONTACT").font(.system(size: 9, weight: .bold)).foregroundColor(.black).padding(.horizontal, 10).padding(.vertical, 5).background(Theme.accent).cornerRadius(5) }.buttonStyle(.plain)
                            Button { } label: { Text("SAVE").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.cyan).padding(.horizontal, 10).padding(.vertical, 5).background(Theme.cyan.opacity(0.1)).cornerRadius(5) }.buttonStyle(.plain)
                        }
                    }.padding(12).background(Theme.surface).cornerRadius(10)
                }
            }
        }
    }

    // MARK: - DMs

    private var dmContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("MESSAGES").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.cyan)
                Spacer()
                let total = mockDMConversations.reduce(0) { $0 + $1.unreadCount }
                if total > 0 { Text("\(total) unread").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.red) }
            }

            ForEach(mockDMConversations) { convo in
                HStack(spacing: 12) {
                    ZStack(alignment: .bottomTrailing) {
                        Circle().fill(LinearGradient(colors: [Theme.accent, Theme.cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 44, height: 44)
                            .overlay(Text(convo.participantInitials).font(.system(size: 14, weight: .heavy)).foregroundColor(.white))
                        Circle().fill(Theme.green).frame(width: 10, height: 10).overlay(Circle().stroke(Theme.bg, lineWidth: 2))
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(convo.participantName).font(.system(size: 12, weight: .bold)).foregroundColor(convo.unreadCount > 0 ? Theme.text : Theme.muted)
                            Spacer()
                            Text(convo.lastActive).font(.system(size: 9)).foregroundColor(Theme.muted)
                        }
                        Text("\(convo.participantTitle) at \(convo.participantCompany)").font(.system(size: 9)).foregroundColor(Theme.muted)
                        if let last = convo.messages.last {
                            HStack(spacing: 4) {
                                if last.isRead && last.fromName != convo.participantName {
                                    Image(systemName: "checkmark").font(.system(size: 7)).foregroundColor(Theme.cyan)
                                    Image(systemName: "checkmark").font(.system(size: 7)).foregroundColor(Theme.cyan).offset(x: -6)
                                }
                                Text(last.content).font(.system(size: 10)).foregroundColor(convo.unreadCount > 0 ? Theme.text : Theme.muted).lineLimit(1)
                            }
                        }
                    }
                    if convo.unreadCount > 0 {
                        Text("\(convo.unreadCount)").font(.system(size: 9, weight: .heavy)).foregroundColor(.white)
                            .frame(width: 20, height: 20).background(Theme.accent).cornerRadius(10)
                    }
                }.padding(12).background(convo.unreadCount > 0 ? Theme.accent.opacity(0.04) : Theme.surface).cornerRadius(10)
            }
        }
    }

    // MARK: - Company Pages

    private var companyPagesContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COMPANY PAGES").font(.system(size: 10, weight: .bold)).tracking(2).foregroundColor(Theme.purple)

            ForEach(mockCompanyPages) { co in
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 10) {
                        Circle().fill(LinearGradient(colors: [Theme.accent, Theme.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 48, height: 48)
                            .overlay(Text(co.initials).font(.system(size: 16, weight: .heavy)).foregroundColor(.white))
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(co.name).font(.system(size: 13, weight: .bold)).foregroundColor(Theme.text)
                                if co.verified { Image(systemName: "checkmark.seal.fill").font(.system(size: 10)).foregroundColor(Theme.cyan) }
                            }
                            Text("\(co.trade) \u{2022} \(co.location)").font(.system(size: 9)).foregroundColor(Theme.muted)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack(spacing: 2) { Text(String(format: "%.1f", co.rating)).font(.system(size: 10, weight: .bold)).foregroundColor(Theme.gold); Image(systemName: "star.fill").font(.system(size: 8)).foregroundColor(Theme.gold) }
                            Text(co.revenue).font(.system(size: 9, weight: .heavy)).foregroundColor(Theme.accent)
                        }
                    }
                    Text(co.description).font(.system(size: 10)).foregroundColor(Theme.muted).lineLimit(2)
                    HStack(spacing: 12) {
                        VStack(spacing: 1) { Text("\(co.activeProjects)").font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.cyan); Text("Projects").font(.system(size: 7)).foregroundColor(Theme.muted) }
                        VStack(spacing: 1) { Text(co.employees).font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.green); Text("Team").font(.system(size: 7)).foregroundColor(Theme.muted) }
                        VStack(spacing: 1) { Text(co.bondingCapacity).font(.system(size: 10, weight: .heavy)).foregroundColor(Theme.gold); Text("Bonding").font(.system(size: 7)).foregroundColor(Theme.muted) }
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(co.specialties, id: \.self) { s in
                                Text(s).font(.system(size: 8, weight: .bold)).foregroundColor(Theme.purple)
                                    .padding(.horizontal, 6).padding(.vertical, 3).background(Theme.purple.opacity(0.08)).cornerRadius(4)
                            }
                        }
                    }
                    HStack(spacing: 6) {
                        Button { } label: { Text("FOLLOW").font(.system(size: 9, weight: .bold)).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 7).background(Theme.accent).cornerRadius(6) }.buttonStyle(.plain)
                        Button { } label: { Text("VIEW PROJECTS").font(.system(size: 9, weight: .bold)).foregroundColor(Theme.cyan).frame(maxWidth: .infinity).padding(.vertical, 7).background(Theme.cyan.opacity(0.1)).cornerRadius(6) }.buttonStyle(.plain)
                    }
                }.padding(14).background(Theme.surface).cornerRadius(12)
            }
        }
    }
}

// MARK: - Feed Post Card

struct FeedPostCard: View {
    let post: FeedPost

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Author header
            HStack(spacing: 10) {
                Circle().fill(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 40, height: 40)
                    .overlay(Text(post.authorInitials).font(.system(size: 13, weight: .heavy)).foregroundColor(.black))
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(post.authorName).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                        if post.authorVerified { Image(systemName: "checkmark.seal.fill").font(.system(size: 9)).foregroundColor(Theme.cyan) }
                    }
                    Text("\(post.authorTitle) at \(post.authorCompany)").font(.system(size: 9)).foregroundColor(Theme.muted)
                    Text("\(post.authorLocation) \u{2022} \(post.timeAgo)").font(.system(size: 8)).foregroundColor(Theme.muted)
                }
                Spacer()
                if post.postType != "update" {
                    Text(post.postType.uppercased()).font(.system(size: 7, weight: .black))
                        .foregroundColor(.black).padding(.horizontal, 6).padding(.vertical, 3)
                        .background(post.postType == "hiring" ? Theme.green : post.postType == "selling" ? Theme.gold : post.postType == "available" ? Theme.cyan : Theme.purple).cornerRadius(4)
                }
            }

            // Content
            if !post.content.isEmpty {
                Text(post.content).font(.system(size: 12)).foregroundColor(Theme.text)
            }

            // Job listing
            if let job = post.jobListing {
                VStack(alignment: .leading, spacing: 6) {
                    Text(job.title).font(.system(size: 14, weight: .bold)).foregroundColor(Theme.text)
                    HStack(spacing: 8) {
                        Text(job.payRate).font(.system(size: 12, weight: .heavy)).foregroundColor(Theme.green)
                        Text(job.location).font(.system(size: 10)).foregroundColor(Theme.muted)
                        if job.urgent { Text("URGENT").font(.system(size: 8, weight: .black)).foregroundColor(Theme.red) }
                    }
                    Button { } label: { Text("APPLY NOW").font(.system(size: 10, weight: .bold)).foregroundColor(.black).frame(maxWidth: .infinity).padding(.vertical, 8).background(Theme.green).cornerRadius(6) }.buttonStyle(.plain)
                }.padding(10).background(Theme.green.opacity(0.04)).cornerRadius(8)
            }

            // Equipment listing
            if let eq = post.equipmentListing {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(eq.name).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                        Text("\(eq.condition) \u{2022} \(eq.hours) \u{2022} \(eq.location)").font(.system(size: 9)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Text(eq.price).font(.system(size: 16, weight: .heavy)).foregroundColor(Theme.accent)
                }.padding(10).background(Theme.gold.opacity(0.04)).cornerRadius(8)
            }

            // Tags
            if !post.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(post.tags, id: \.self) { tag in
                            Text(tag).font(.system(size: 9, weight: .bold)).foregroundColor(Theme.accent)
                        }
                    }
                }
            }

            // Photos indicator
            if post.photoCount > 0 {
                RoundedRectangle(cornerRadius: 8).fill(Theme.panel).frame(height: 160)
                    .overlay(VStack(spacing: 4) {
                        Image(systemName: "photo.on.rectangle.angled").font(.system(size: 24)).foregroundColor(Theme.muted.opacity(0.4))
                        Text("\(post.photoCount) photos").font(.system(size: 9)).foregroundColor(Theme.muted)
                    })
            }

            // Action bar
            HStack(spacing: 0) {
                actionButton(icon: "heart", label: "\(post.likes)", color: Theme.red)
                actionButton(icon: "bubble.left", label: "\(post.comments)", color: Theme.cyan)
                actionButton(icon: "arrow.turn.up.right", label: "\(post.shares)", color: Theme.green)
                Spacer()
                Button { } label: { Image(systemName: "bookmark").font(.system(size: 12)).foregroundColor(Theme.muted) }.buttonStyle(.plain)
            }
        }
        .padding(14).background(Theme.surface).cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border.opacity(0.1), lineWidth: 1))
    }

    private func actionButton(icon: String, label: String, color: Color) -> some View {
        Button { } label: {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 12))
                Text(label).font(.system(size: 10, weight: .semibold))
            }.foregroundColor(Theme.muted).frame(maxWidth: .infinity)
        }.buttonStyle(.plain)
    }
}
