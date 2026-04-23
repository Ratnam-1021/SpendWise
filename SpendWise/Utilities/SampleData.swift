//
//  SampleData.swift
//  SpendWise
//
//  Created by Ratnam's Mac on 23/04/26.
//

import CoreData

struct SampleData {
    static func populate(context: NSManagedObjectContext) {
        let categories: [(String, String, String)] = [
            ("Food", "fork.knife", "#FF6B6B"),
            ("Transport", "car.fill", "#4ECDC4"),
            ("Shopping", "bag.fill", "#45B7D1"),
            ("Entertainment", "gamecontroller.fill", "#96CEB4"),
            ("Health", "heart.fill", "#FFEAA7"),
            ("Bills", "doc.text.fill", "#DDA0DD")
        ]

        var categoryObjects: [Category] = []

        for (name, icon, color) in categories {
            let cat = Category(context: context)
            cat.id = UUID()
            cat.name = name
            cat.icon = icon
            cat.colorHex = color
            cat.createdAt = Date()
            categoryObjects.append(cat)
        }

        // Add sample expenses
        let sampleExpenses: [(String, Double, String)] = [
            ("Lunch at Café", 280, "Food"),
            ("Metro card recharge", 500, "Transport"),
            ("Netflix", 649, "Entertainment"),
            ("Grocery shopping", 1200, "Food"),
            ("Uber to college", 180, "Transport"),
            ("Protein powder", 2200, "Health")
        ]

        for (title, amount, catName) in sampleExpenses {
            let exp = Expense(context: context)
            exp.id = UUID()
            exp.title = title
            exp.amount = amount
            exp.date = Date().addingTimeInterval(-Double.random(in: 0...604800))
            exp.createdAt = Date()
            exp.category = categoryObjects.first { $0.name == catName }
        }

        try? context.save()
    }
}
