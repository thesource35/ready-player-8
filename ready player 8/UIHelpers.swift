import Combine
import EventKit
import Foundation
import PhotosUI
import SwiftUI
import UserNotifications
#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif


// MARK: - ========== Loading & Error States ==========

struct LoadingOverlay: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            ProgressView().tint(Theme.accent)
            Text(message).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.muted)
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Theme.surface.opacity(0.95))
        .cornerRadius(10)
        .premiumGlow(cornerRadius: 10, color: Theme.accent)
    }
}

struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(Theme.red)
            Text(message).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.text).lineLimit(2)
            Spacer()
            Button(action: onDismiss) {
                Image(systemName: "xmark").font(.system(size: 10, weight: .bold)).foregroundColor(Theme.muted)
            }.buttonStyle(.plain)
        }
        .padding(12)
        .background(Theme.red.opacity(0.1))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.red.opacity(0.3), lineWidth: 1))
        .cornerRadius(8)
    }
}

struct SuccessBanner: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(Theme.green)
            Text(message).font(.system(size: 11, weight: .semibold)).foregroundColor(Theme.green)
        }
        .padding(10)
        .background(Theme.green.opacity(0.08))
        .cornerRadius(8)
    }
}

// MARK: - ========== Input Validation ==========

struct ValidationResult {
    let isValid: Bool
    let message: String?
    static let valid = ValidationResult(isValid: true, message: nil)
    static func invalid(_ msg: String) -> ValidationResult { .init(isValid: false, message: msg) }
}

struct InputValidator {
    static func email(_ value: String) -> ValidationResult {
        let trimmed = value.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .invalid("Email is required") }
        guard trimmed.contains("@"), trimmed.contains(".") else { return .invalid("Invalid email format") }
        return .valid
    }

    static func required(_ value: String, field: String = "Field") -> ValidationResult {
        value.trimmingCharacters(in: .whitespaces).isEmpty ? .invalid("\(field) is required") : .valid
    }

    static func numeric(_ value: String, field: String = "Value") -> ValidationResult {
        guard !value.isEmpty else { return .invalid("\(field) is required") }
        guard Double(value.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "$", with: "")) != nil else {
            return .invalid("\(field) must be a number")
        }
        return .valid
    }

    static func minLength(_ value: String, min: Int, field: String = "Field") -> ValidationResult {
        value.count >= min ? .valid : .invalid("\(field) must be at least \(min) characters")
    }

    static func password(_ value: String) -> ValidationResult {
        guard value.count >= 8 else { return .invalid("Password must be at least 8 characters") }
        return .valid
    }
}

struct ValidatedTextField: View {
    let label: String
    @Binding var text: String
    let validator: (String) -> ValidationResult
    @State private var validationMessage: String?
    @State private var hasEdited = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(label, text: $text)
                .font(.system(size: 12)).foregroundColor(Theme.text)
                .padding(10).background(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                    validationMessage != nil && hasEdited ? Theme.red.opacity(0.6) : Theme.border, lineWidth: 1))
                .cornerRadius(8)
                .onChange(of: text) { _, _ in
                    hasEdited = true
                    let result = validator(text)
                    validationMessage = result.isValid ? nil : result.message
                }
            if let msg = validationMessage, hasEdited {
                Text(msg).font(.system(size: 9, weight: .semibold)).foregroundColor(Theme.red)
            }
        }
    }
}

// MARK: - ========== Global Search ==========

struct GlobalSearchView: View {
    @Binding var isPresented: Bool
    @State private var query = ""
    @State private var results: [(category: String, title: String, detail: String, icon: String)] = []

    private func search(_ q: String) {
        guard q.count >= 2 else { results = []; return }
        let lq = q.lowercased()
        var hits: [(category: String, title: String, detail: String, icon: String)] = []

        for p in mockProjects where p.name.lowercased().contains(lq) || p.client.lowercased().contains(lq) {
            hits.append(("Projects", p.name, p.client, "\u{1F3D7}"))
        }
        for c in mockContracts where c.title.lowercased().contains(lq) || c.client.lowercased().contains(lq) {
            hits.append(("Contracts", c.title, c.client, "\u{1F4CB}"))
        }
        results = hits
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundColor(Theme.muted)
                TextField("Search projects, contracts, crew...", text: $query)
                    .font(.system(size: 14)).foregroundColor(Theme.text)
                    .onChange(of: query) { _, newVal in search(newVal) }
                if !query.isEmpty {
                    Button { query = ""; results = [] } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(Theme.muted)
                    }.buttonStyle(.plain)
                }
                Button("Done") { isPresented = false }
                    .font(.system(size: 12, weight: .bold)).foregroundColor(Theme.accent)
            }
            .padding(14).background(Theme.surface)
            .border(width: 1, edges: [.bottom], color: Theme.border)

            if results.isEmpty && !query.isEmpty {
                VStack(spacing: 8) {
                    Text("No results for \"\(query)\"")
                        .font(.system(size: 13, weight: .semibold)).foregroundColor(Theme.muted)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(results.indices, id: \.self) { i in
                            let r = results[i]
                            HStack(spacing: 10) {
                                Text(r.icon).font(.system(size: 18))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.title).font(.system(size: 12, weight: .bold)).foregroundColor(Theme.text)
                                    Text("\(r.category) \u{2022} \(r.detail)").font(.system(size: 10)).foregroundColor(Theme.muted)
                                }
                                Spacer()
                            }
                            .padding(10).background(Theme.surface).cornerRadius(8)
                        }
                    }.padding(14)
                }
            }
        }
        .background(Theme.bg)
    }
}

// MARK: - ========== Onboarding Flow ==========

struct OnboardingView: View {
    @Binding var isComplete: Bool
    @State private var currentStep = 0

    private let steps: [(icon: String, title: String, detail: String)] = [
        ("\u{1F3D7}", "Welcome to ConstructionOS", "Your all-in-one command center for construction project management, field operations, and business intelligence."),
        ("\u{2699}\u{FE0F}", "Configure Your Backend", "Connect to Supabase in the Integration Hub to enable cloud sync, real-time data, and team collaboration."),
        ("\u{1F4CB}", "Track Projects & Contracts", "Manage active jobs, bid pipelines, change orders, and subcontractor scorecards from a single dashboard."),
        ("\u{1F48E}", "Wealth Intelligence Suite", "Access the Money Lens, Psychology Decoder, Power Thinking, Leverage System, and Opportunity Filter."),
        ("\u{1F680}", "You\u{2019}re Ready", "Explore the tabs, customize your role preset, and start building your construction command center."),
    ]

    var body: some View {
        ZStack {
            PremiumBackgroundView()
            VStack(spacing: 24) {
                Spacer()
                Text(steps[currentStep].icon).font(.system(size: 56))
                Text(steps[currentStep].title)
                    .font(.system(size: 22, weight: .heavy)).foregroundColor(Theme.text).multilineTextAlignment(.center)
                Text(steps[currentStep].detail)
                    .font(.system(size: 14)).foregroundColor(Theme.muted).multilineTextAlignment(.center)
                    .frame(maxWidth: 360)

                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Circle().fill(i == currentStep ? Theme.accent : Theme.border)
                            .frame(width: 8, height: 8)
                    }
                }

                Spacer()
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button("Back") { withAnimation { currentStep -= 1 } }
                            .font(.system(size: 14, weight: .semibold)).foregroundColor(Theme.muted)
                    }
                    Spacer()
                    Button(currentStep == steps.count - 1 ? "Get Started" : "Next") {
                        if currentStep == steps.count - 1 {
                            UserDefaults.standard.set(true, forKey: "ConstructOS.OnboardingComplete")
                            withAnimation { isComplete = true }
                        } else {
                            withAnimation { currentStep += 1 }
                        }
                    }
                    .font(.system(size: 14, weight: .bold)).foregroundColor(.black)
                    .padding(.horizontal, 24).padding(.vertical, 12)
                    .background(LinearGradient(colors: [Theme.accent, Theme.gold], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
                }
                .padding(.horizontal, 40).padding(.bottom, 40)
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - ========== Accessibility Helpers ==========

extension View {
    func accessibleLabel(_ label: String) -> some View {
        self.accessibilityLabel(label)
    }

    func accessibleHint(_ hint: String) -> some View {
        self.accessibilityHint(hint)
    }

    func accessibleAction(_ name: String, action: @escaping () -> Void) -> some View {
        self.accessibilityAction(named: name, action)
    }

    /// Apply standard construction app accessibility to a panel
    func constructionAccessible(label: String, hint: String = "") -> some View {
        self.accessibilityElement(children: .contain)
            .accessibilityLabel(label)
            .accessibilityHint(hint.isEmpty ? "Double tap to interact" : hint)
    }

    /// Make a stat card announce its value
    func statAccessible(value: String, label: String) -> some View {
        self.accessibilityElement(children: .ignore)
            .accessibilityLabel("\(label): \(value)")
            .accessibilityAddTraits(.isStaticText)
    }
}

/// Modifier that adds Dynamic Type support
struct DynamicTypeModifier: ViewModifier {
    @Environment(\.dynamicTypeSize) var typeSize

    func body(content: Content) -> some View {
        content
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
    }
}

extension View {
    func supportsDynamicType() -> some View {
        self.modifier(DynamicTypeModifier())
    }
}

// MARK: - Photo Picker Helper

struct PhotoPickerButton: View {
    let label: String
    @Binding var selectedData: Data?
    @State private var photoItem: PhotosPickerItem?
    let maxBytes: Int

    var body: some View {
        HStack(spacing: 8) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label(label, systemImage: selectedData != nil ? "checkmark.circle.fill" : "camera.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(selectedData != nil ? Theme.green : Theme.cyan)
            }
            if selectedData != nil {
                Button {
                    selectedData = nil
                    photoItem = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 10)).foregroundColor(Theme.red)
                }.buttonStyle(.plain)
                let size = ByteCountFormatter.string(fromByteCount: Int64(selectedData?.count ?? 0), countStyle: .file)
                Text(size).font(.system(size: 8)).foregroundColor(Theme.muted)
            }
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                guard let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                await MainActor.run {
                    if data.count <= maxBytes {
                        selectedData = data
                    } else {
                        selectedData = nil
                        self.photoItem = nil
                    }
                }
            }
        }
    }
}

// MARK: - ========== Notification Manager ==========

import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    @Published var isAuthorized = false

    func requestAuthorization() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    func scheduleInspectionReminder(site: String, type: String, dueDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Inspection Due"
        content.body = "\(type) at \(site) is due"
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour], from: dueDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func scheduleBidDeadline(contract: String, deadline: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Bid Deadline"
        content.body = "\(contract) bid is due"
        content.sound = .default

        let alertDate = Calendar.current.date(byAdding: .day, value: -1, to: deadline) ?? deadline
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour], from: alertDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - ========== Document Attachment Manager ==========

struct DocumentAttachment: Identifiable, Codable {
    var id = UUID()
    let name: String
    let type: String  // "photo", "pdf", "document"
    let dataSize: Int
    let createdAt: Date
    var projectRef: String?
}

@MainActor
final class DocumentStore: ObservableObject {
    static let shared = DocumentStore()
    @Published var attachments: [DocumentAttachment] = []

    private let storageKey = "ConstructOS.Documents.Attachments"

    init() { load() }

    func add(name: String, type: String, data: Data, projectRef: String? = nil) {
        // Save data to app documents directory
        let fileName = "\(UUID().uuidString)_\(name)"
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = docsDir.appendingPathComponent(fileName)
        try? data.write(to: fileURL)

        let attachment = DocumentAttachment(
            name: name, type: type, dataSize: data.count,
            createdAt: Date(), projectRef: projectRef
        )
        attachments.insert(attachment, at: 0)
        save()
    }

    func remove(_ attachment: DocumentAttachment) {
        attachments.removeAll { $0.id == attachment.id }
        save()
    }

    private func load() {
        attachments = loadJSON(storageKey, default: [DocumentAttachment]())
    }

    private func save() {
        saveJSON(storageKey, value: attachments)
    }
}

// MARK: - ========== PDF Export ==========

struct PDFExporter {
    static func generateReport(title: String, sections: [(heading: String, content: String)]) -> Data? {
        let pageWidth: CGFloat = 612
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

#if os(iOS)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight))
        return renderer.pdfData { context in
            context.beginPage()
            var yPos: CGFloat = margin

            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .bold),
                .foregroundColor: UIColor.black
            ]
            NSAttributedString(string: title, attributes: titleAttrs)
                .draw(in: CGRect(x: margin, y: yPos, width: contentWidth, height: 40))
            yPos += 50

            let dateFormatter = DateFormatter(); dateFormatter.dateStyle = .long
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12), .foregroundColor: UIColor.gray
            ]
            NSAttributedString(string: dateFormatter.string(from: Date()), attributes: dateAttrs)
                .draw(in: CGRect(x: margin, y: yPos, width: contentWidth, height: 20))
            yPos += 30

            for section in sections {
                if yPos > pageHeight - margin - 100 { context.beginPage(); yPos = margin }
                let headAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: UIColor.black
                ]
                NSAttributedString(string: section.heading, attributes: headAttrs)
                    .draw(in: CGRect(x: margin, y: yPos, width: contentWidth, height: 24))
                yPos += 28
                let bodyAttrs: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 11), .foregroundColor: UIColor.darkGray
                ]
                let bodyStr = NSAttributedString(string: section.content, attributes: bodyAttrs)
                bodyStr.draw(in: CGRect(x: margin, y: yPos, width: contentWidth, height: pageHeight - yPos - margin))
                let rect = bodyStr.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin], context: nil)
                yPos += rect.height + 16
            }
            let footAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8), .foregroundColor: UIColor.lightGray
            ]
            NSAttributedString(string: "Generated by ConstructionOS", attributes: footAttrs)
                .draw(in: CGRect(x: margin, y: pageHeight - 30, width: contentWidth, height: 12))
        }
#elseif os(macOS)
        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let cgContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return nil }

        cgContext.beginPDFPage(nil)
        var yPos: CGFloat = margin

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: NSColor.black
        ]
        let titleStr = NSAttributedString(string: title, attributes: titleAttrs)
        // macOS CoreGraphics has flipped Y; draw using NSStringDrawing
        let titleRect = CGRect(x: margin, y: pageHeight - yPos - 40, width: contentWidth, height: 40)
        titleStr.draw(in: titleRect)
        yPos += 50

        let dateFormatter = DateFormatter(); dateFormatter.dateStyle = .long
        let dateAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.gray
        ]
        NSAttributedString(string: dateFormatter.string(from: Date()), attributes: dateAttrs)
            .draw(in: CGRect(x: margin, y: pageHeight - yPos - 20, width: contentWidth, height: 20))
        yPos += 30

        for section in sections {
            if yPos > pageHeight - margin - 100 {
                cgContext.endPDFPage(); cgContext.beginPDFPage(nil); yPos = margin
            }
            let headAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 16, weight: .semibold), .foregroundColor: NSColor.black
            ]
            NSAttributedString(string: section.heading, attributes: headAttrs)
                .draw(in: CGRect(x: margin, y: pageHeight - yPos - 24, width: contentWidth, height: 24))
            yPos += 28
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.darkGray
            ]
            let bodyStr = NSAttributedString(string: section.content, attributes: bodyAttrs)
            let remaining = pageHeight - yPos - margin
            bodyStr.draw(in: CGRect(x: margin, y: pageHeight - yPos - remaining, width: contentWidth, height: remaining))
            let rect = bodyStr.boundingRect(with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude), options: [.usesLineFragmentOrigin])
            yPos += rect.height + 16
        }
        let footAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 8), .foregroundColor: NSColor.lightGray
        ]
        NSAttributedString(string: "Generated by ConstructionOS", attributes: footAttrs)
            .draw(in: CGRect(x: margin, y: 18, width: contentWidth, height: 12))

        cgContext.endPDFPage()
        cgContext.closePDF()
        return pdfData as Data
#else
        return nil
#endif
    }
}

// MARK: - ========== Calendar Integration ==========

import EventKit

@MainActor
final class CalendarManager: ObservableObject {
    static let shared = CalendarManager()
    private let store = EKEventStore()
    @Published var isAuthorized = false

    func requestAccess() async {
        if #available(iOS 17.0, macOS 14.0, *) {
            isAuthorized = (try? await store.requestFullAccessToEvents()) ?? false
        } else {
            isAuthorized = await withCheckedContinuation { cont in
                store.requestAccess(to: .event) { granted, _ in cont.resume(returning: granted) }
            }
        }
    }

    func addEvent(title: String, startDate: Date, endDate: Date, notes: String? = nil) throws {
        guard isAuthorized else { return }
        let event = EKEvent(eventStore: store)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.calendar = store.defaultCalendarForNewEvents
        event.addAlarm(EKAlarm(relativeOffset: -3600)) // 1 hour before
        try store.save(event, span: .thisEvent)
    }

    func addInspectionToCalendar(site: String, type: String, date: Date) {
        try? addEvent(
            title: "[Inspection] \(type) — \(site)",
            startDate: date,
            endDate: Calendar.current.date(byAdding: .hour, value: 2, to: date) ?? date,
            notes: "ConstructionOS inspection reminder"
        )
    }

    func addBidDeadlineToCalendar(contract: String, deadline: Date) {
        try? addEvent(
            title: "[Bid Due] \(contract)",
            startDate: deadline,
            endDate: Calendar.current.date(byAdding: .hour, value: 1, to: deadline) ?? deadline,
            notes: "ConstructionOS bid deadline"
        )
    }
}

// MARK: - ========== Haptic Feedback ==========

#if os(iOS)
struct HapticEngine {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }
    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
    /// Call on save/submit success
    static func success() { notification(.success) }
    /// Call on errors
    static func error() { notification(.error) }
    /// Call on tab changes
    static func tap() { impact(.light) }
    /// Call on important actions (delete, send, publish)
    static func heavy() { impact(.heavy) }
}
#else
struct HapticEngine {
    static func impact(_ style: Any? = nil) {}
    static func notification(_ type: Any? = nil) {}
    static func selection() {}
    static func success() {}
    static func error() {}
    static func tap() {}
    static func heavy() {}
}
#endif

// MARK: - ========== Deep Linking URL Scheme ==========

/// Handles constructionos:// URL scheme for deep linking
/// Register "constructionos" as URL scheme in Xcode target > URL Types
struct DeepLinkHandler {
    static func handleURL(_ url: URL) -> ContentView.NavTab? {
        guard url.scheme == "constructionos" else { return nil }
        let host = url.host ?? ""
        switch host {
        case "projects": return .projects
        case "contracts": return .contracts
        case "market": return .market
        case "maps": return .maps
        case "ops": return .ops
        case "hub": return .hub
        case "security": return .security
        case "angelic", "ai": return .angelic
        case "wealth": return .wealth
        case "rentals": return .rentals
        case "electrical": return .electrical
        case "tax": return .tax
        case "field": return .field
        case "finance": return .finance
        case "compliance": return .compliance
        case "clients": return .clientPortal
        case "analytics": return .analytics
        case "schedule": return .schedule
        case "training": return .training
        case "scanner": return .scanner
        case "settings": return .settings
        default: return .home
        }
    }
}

// MARK: - ========== Spotlight Search Indexing ==========

import CoreSpotlight
import UniformTypeIdentifiers

@MainActor
final class SpotlightIndexer {
    static let shared = SpotlightIndexer()

    func indexProjects(_ projects: [Project]) {
        var items: [CSSearchableItem] = []
        for project in projects {
            let attrs = CSSearchableItemAttributeSet(contentType: .text)
            attrs.title = project.name
            attrs.contentDescription = "\(project.client) \u{2022} \(project.type) \u{2022} \(project.status) \u{2022} Budget: \(project.budget)"
            attrs.keywords = ["project", project.name, project.client, project.type]

            let item = CSSearchableItem(
                uniqueIdentifier: "project-\(project.id)",
                domainIdentifier: "com.constructionos.projects",
                attributeSet: attrs
            )
            items.append(item)
        }
        CSSearchableIndex.default().indexSearchableItems(items)
    }

    func indexContracts(_ contracts: [SupabaseContract]) {
        var items: [CSSearchableItem] = []
        for contract in contracts {
            let attrs = CSSearchableItemAttributeSet(contentType: .text)
            attrs.title = contract.title
            attrs.contentDescription = "\(contract.client) \u{2022} \(contract.stage) \u{2022} Budget: \(contract.budget)"
            attrs.keywords = ["contract", "bid", contract.title, contract.client]

            let item = CSSearchableItem(
                uniqueIdentifier: "contract-\(contract.id ?? UUID().uuidString)",
                domainIdentifier: "com.constructionos.contracts",
                attributeSet: attrs
            )
            items.append(item)
        }
        CSSearchableIndex.default().indexSearchableItems(items)
    }

    func indexRentalItems(_ items: [RentalItem]) {
        var searchItems: [CSSearchableItem] = []
        for rental in items {
            let attrs = CSSearchableItemAttributeSet(contentType: .text)
            attrs.title = rental.name
            attrs.contentDescription = "\(rental.category.rawValue) \u{2022} \(rental.dailyRate)/day \u{2022} \(rental.provider.rawValue)"
            attrs.keywords = ["rental", "equipment", rental.name, rental.category.rawValue]

            let item = CSSearchableItem(
                uniqueIdentifier: "rental-\(rental.id)",
                domainIdentifier: "com.constructionos.rentals",
                attributeSet: attrs
            )
            searchItems.append(item)
        }
        CSSearchableIndex.default().indexSearchableItems(searchItems)
    }

    func deleteAllIndexes() {
        CSSearchableIndex.default().deleteAllSearchableItems()
    }
}

