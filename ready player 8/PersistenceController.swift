// PersistenceController.swift — Core Data + CloudKit persistence stack
// ConstructionOS

import CoreData
import SwiftUI
import Combine

@MainActor
final class PersistenceController: ObservableObject {
    /// Backward-compat singleton — prefer @EnvironmentObject injection in views
    static let shared = PersistenceController()

    /// Preview instance with in-memory store for SwiftUI previews
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.container.viewContext
        // Seed preview data
        let project = CDProject(context: ctx)
        project.id = UUID()
        project.name = "Preview Project"
        project.client = "Preview Client"
        project.status = "Active"
        project.progress = 65
        project.budget = "$1.2M"
        project.createdAt = Date()
        try? ctx.save()
        return controller
    }()

    let container: NSPersistentCloudKitContainer

    @Published var lastSaveError: String?

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ready_player_8")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // Configure for CloudKit sync
        guard let description = container.persistentStoreDescriptions.first else {
            CrashReporter.shared.reportError(
                "PersistenceController.init: No persistent store descriptions found — using in-memory fallback"
            )
            let memDesc = NSPersistentStoreDescription()
            memDesc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [memDesc]
            // Continue with in-memory store — data won't persist but app won't crash
            container.loadPersistentStores { _, error in
                if let error {
                    CrashReporter.shared.reportError(
                        "PersistenceController.init.inMemoryFallback: \(error.localizedDescription)"
                    )
                }
            }
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            return
        }
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        container.loadPersistentStores { _, error in
            if let error {
                CrashReporter.shared.reportError(
                    "PersistenceController.loadPersistentStores: \(error.localizedDescription)"
                )
                #if DEBUG
                assertionFailure("Core Data load failed: \(error)")
                #endif
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    /// Save context with error handling
    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
            lastSaveError = nil
        } catch {
            lastSaveError = error.localizedDescription
            #if DEBUG
            print("Core Data save error: \(error)")
            #endif
            CrashReporter.shared.reportError("Core Data save error: \(error.localizedDescription)")
        }
    }

    /// Background context for heavy operations
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }

    // MARK: - Migration Helpers (JSON → Core Data)

    /// Migrate projects from Supabase DTOs to Core Data
    func migrateProjects(_ dtos: [SupabaseProject]) {
        let context = container.viewContext
        for dto in dtos {
            let entity = CDProject(context: context)
            entity.id = UUID(uuidString: dto.id ?? "") ?? UUID()
            entity.name = dto.name
            entity.client = dto.client
            entity.type = dto.type
            entity.status = dto.status
            entity.progress = Int32(dto.progress)
            entity.budget = dto.budget
            entity.score = dto.score
            entity.team = dto.team
            entity.createdAt = Date()
            entity.syncedAt = Date()
        }
        save()
    }

    /// Migrate contracts from Supabase DTOs to Core Data
    func migrateContracts(_ dtos: [SupabaseContract]) {
        let context = container.viewContext
        for dto in dtos {
            let entity = CDContract(context: context)
            entity.id = UUID(uuidString: dto.id ?? "") ?? UUID()
            entity.title = dto.title
            entity.client = dto.client
            entity.location = dto.location
            entity.sector = dto.sector
            entity.stage = dto.stage
            entity.package = dto.package
            entity.budget = dto.budget
            entity.bidDue = dto.bidDue
            entity.liveFeedStatus = dto.liveFeedStatus
            entity.bidders = Int32(dto.bidders)
            entity.score = Int32(dto.score)
            entity.watchCount = Int32(dto.watchCount)
            entity.createdAt = Date()
            entity.syncedAt = Date()
        }
        save()
    }

    /// Fetch all projects from Core Data
    func fetchProjects() -> [CDProject] {
        let request: NSFetchRequest<CDProject> = CDProject.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDProject.createdAt, ascending: false)]
        return (try? viewContext.fetch(request)) ?? []
    }

    /// Fetch all contracts from Core Data
    func fetchContracts() -> [CDContract] {
        let request: NSFetchRequest<CDContract> = CDContract.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDContract.createdAt, ascending: false)]
        return (try? viewContext.fetch(request)) ?? []
    }
}
