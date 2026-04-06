//
//  ready_player_8App.swift
//  ready player 8
//
//  Created by Beverly Hunter on 3/23/26.
//

import SwiftUI
import CoreData
#if canImport(UIKit) && canImport(CarPlay)
import UIKit
import CarPlay

final class CarPlaySceneDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private weak var interfaceController: CPInterfaceController?

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController
    ) {
        connect(interfaceController)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didConnect interfaceController: CPInterfaceController,
        to window: CPWindow
    ) {
        connect(interfaceController)
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnectInterfaceController interfaceController: CPInterfaceController
    ) {
        self.interfaceController = nil
    }

    func templateApplicationScene(
        _ templateApplicationScene: CPTemplateApplicationScene,
        didDisconnect interfaceController: CPInterfaceController,
        from window: CPWindow
    ) {
        self.interfaceController = nil
    }

    private func connect(_ interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        interfaceController.setRootTemplate(makeRootTemplate(), animated: true) { _, _ in }
    }

    private func makeRootTemplate() -> CPListTemplate {
        let projects = CPListItem(text: "Projects", detailText: "Live jobs, milestones, schedules")
        projects.handler = { [weak self] _, completion in
            self?.pushDetail(title: "Projects", detail: "Track current project status while on the road.")
            completion()
        }

        let crew = CPListItem(text: "Crew", detailText: "Availability and assignment snapshots")
        crew.handler = { [weak self] _, completion in
            self?.pushDetail(title: "Crew", detail: "Review active crews and labor readiness.")
            completion()
        }

        let messages = CPListItem(text: "Messages", detailText: "Unread team and subcontractor updates")
        messages.handler = { [weak self] _, completion in
            self?.pushDetail(title: "Messages", detail: "Check urgent field communication at a glance.")
            completion()
        }

        let budgets = CPListItem(text: "Budgets", detailText: "Cost health and budget guardrails")
        budgets.handler = { [weak self] _, completion in
            self?.pushDetail(title: "Budgets", detail: "Monitor project budgets and spend variance.")
            completion()
        }

        let section = CPListSection(items: [projects, crew, messages, budgets])
        return CPListTemplate(title: "Construction OS", sections: [section])
    }

    private func pushDetail(title: String, detail: String) {
        guard let interfaceController else { return }
        let detailItem = CPListItem(text: title, detailText: detail)
        let template = CPListTemplate(title: title, sections: [CPListSection(items: [detailItem])])
        interfaceController.pushTemplate(template, animated: true) { _, _ in }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if connectingSceneSession.role == .carTemplateApplication {
            let configuration = UISceneConfiguration(name: "CarPlay Configuration", sessionRole: connectingSceneSession.role)
            configuration.sceneClass = CPTemplateApplicationScene.self
            configuration.delegateClass = CarPlaySceneDelegate.self
            return configuration
        }

        return UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    }
}
#endif

@main
struct ready_player_8App: App {
#if canImport(UIKit) && canImport(CarPlay)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif

    @StateObject private var supabase = SupabaseService.shared
    @StateObject private var analytics = AnalyticsEngine.shared
    @StateObject private var crashReporter = CrashReporter.shared
    @StateObject private var persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(supabase)
                .environmentObject(analytics)
                .environmentObject(crashReporter)
                .environmentObject(persistence)
                .environment(ToastManager.shared)
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
