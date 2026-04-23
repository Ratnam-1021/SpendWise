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

    // Changed from NSPersistentCloudKitContainer to NSPersistentContainer
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SpendWise")

        if inMemory {
            container.persistentStoreDescriptions.first!.url =
                URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("CoreData failed to load: \(error), \(error.userInfo)")
            }
        }

        // Standard setup for local container
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
