//
//  SpendWiseApp.swift
//  SpendWise
//
//  Created by Ratnam's Mac on 23/04/26.
//

import SwiftUI
import CoreData

@main
struct SpendWiseApp: App {
    let persistence = PersistenceController.shared
    let vm = ExpenseViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView(vm: vm)
                .environment(\.managedObjectContext,
                             persistence.container.viewContext)
        }
    }
}
