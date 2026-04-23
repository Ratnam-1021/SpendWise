//
//  Persistence.swift
//  SpendWise
//
//  Created by Ratnam's Mac on 23/04/26.
//


import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    // Preview instance for SwiftUI canvas
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        // Add sample data for previews
        let ctx = controller.container.viewContext
        SampleData.populate(context: ctx)
        return controller
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "SpendWise")

        if inMemory {
            container.persistentStoreDescriptions.first!.url =
                URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData failed to load: \(error)")
            }
        }

        // Auto-merge changes from iCloud
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
