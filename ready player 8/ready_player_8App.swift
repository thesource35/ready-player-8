//
//  ready_player_8App.swift
//  ready player 8
//
//  Created by Beverly Hunter on 3/23/26.
//

import SwiftUI
import CoreData

@main
struct ready_player_8App: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
