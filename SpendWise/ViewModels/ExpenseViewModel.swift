//
//  ExpenseViewModel.swift
//  SpendWise
//
//  Created by Ratnam's Mac on 23/04/26.
//

import CoreData
import SwiftUI
import Combine

class ExpenseViewModel: ObservableObject {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    // MARK: - Add Expense
    func addExpense(title: String, amount: Double, date: Date, note: String, category: Category?) {
        let expense = Expense(context: context)
        expense.id = UUID()
        expense.title = title
        expense.amount = amount
        expense.date = date
        expense.note = note
        expense.createdAt = Date()
        expense.category = category
        save()
    }

    // MARK: - Import Transactions
    func importTransactions(_ imported: [PhonePeTransaction]) {
        // Get all categories for automatic matching
        let categoryRequest = Category.fetchRequest()
        let categories = (try? context.fetch(categoryRequest)) ?? []
        
        for tx in imported {
            // 1. Skip if not a debit (we only track expenses for now)
            guard tx.isDebit else { continue }
            
            // 2. Skip if already exists
            let request = Expense.fetchRequest()
            request.predicate = NSPredicate(format: "transactionID == %@", tx.transactionID)
            let count = (try? context.count(for: request)) ?? 0
            guard count == 0 else { continue }
            
            // 3. Create new expense
            let expense = Expense(context: context)
            expense.id = UUID()
            expense.transactionID = tx.transactionID
            expense.title = tx.title
            expense.amount = tx.amount
            expense.date = tx.date
            expense.createdAt = Date()
            
            // 4. Auto-match category
            let lowerTitle = tx.title.lowercased()
            if lowerTitle.contains("food") || lowerTitle.contains("restaurant") || lowerTitle.contains("canteen") {
                expense.category = categories.first { $0.name == "Food" }
            } else if lowerTitle.contains("movie") || lowerTitle.contains("game") || lowerTitle.contains("entertainment") {
                expense.category = categories.first { $0.name == "Entertainment" }
            } else if lowerTitle.contains("hospital") || lowerTitle.contains("medical") || lowerTitle.contains("health") {
                expense.category = categories.first { $0.name == "Health" }
            } else if lowerTitle.contains("bill") || lowerTitle.contains("recharge") || lowerTitle.contains("electricity") {
                expense.category = categories.first { $0.name == "Bills" }
            } else if lowerTitle.contains("travel") || lowerTitle.contains("uber") || lowerTitle.contains("ola") || lowerTitle.contains("transport") {
                expense.category = categories.first { $0.name == "Transport" }
            }
            
            // Default to first category if no match
            if expense.category == nil {
                expense.category = categories.first
            }
        }
        save()
    }

    // MARK: - Import Transactions (GPay)
    func importTransactions(_ imported: [GPayTransaction]) {
        let categoryRequest = Category.fetchRequest()
        let categories = (try? context.fetch(categoryRequest)) ?? []
        
        for tx in imported {
            guard tx.isDebit else { continue }
            
            let request = Expense.fetchRequest()
            request.predicate = NSPredicate(format: "transactionID == %@", tx.transactionID)
            let count = (try? context.count(for: request)) ?? 0
            guard count == 0 else { continue }
            
            let expense = Expense(context: context)
            expense.id = UUID()
            expense.transactionID = tx.transactionID
            expense.title = tx.title
            expense.amount = tx.amount
            expense.date = tx.date
            expense.createdAt = Date()
            
            autoMatchCategory(for: expense, categories: categories)
        }
        save()
    }

    // MARK: - Auto-match Category
    private func autoMatchCategory(for expense: Expense, categories: [Category]) {
        guard let title = expense.title?.lowercased() else { return }
        
        if title.contains("food") || title.contains("restaurant") || title.contains("canteen") || title.contains("zomato") || title.contains("swiggy") {
            expense.category = categories.first { $0.name == "Food" }
        } else if title.contains("movie") || title.contains("game") || title.contains("entertainment") || title.contains("netflix") {
            expense.category = categories.first { $0.name == "Entertainment" }
        } else if title.contains("hospital") || title.contains("medical") || title.contains("health") || title.contains("pharmacy") {
            expense.category = categories.first { $0.name == "Health" }
        } else if title.contains("bill") || title.contains("recharge") || title.contains("electricity") {
            expense.category = categories.first { $0.name == "Bills" }
        } else if title.contains("travel") || title.contains("uber") || title.contains("ola") || title.contains("transport") || title.contains("petrol") {
            expense.category = categories.first { $0.name == "Transport" }
        } else if title.contains("zepto") || title.contains("blinkit") || title.contains("groceries") || title.contains("shopping") {
            expense.category = categories.first { $0.name == "Shopping" }
        }
        
        if expense.category == nil {
            expense.category = categories.first
        }
    }

    // MARK: - Delete Expense
    func deleteExpense(_ expense: Expense) {
        context.delete(expense)
        save()
    }

    // MARK: - Add Default Categories (run once on first launch)
    func seedCategoriesIfNeeded() {
        let request = Category.fetchRequest()
        let count = (try? context.count(for: request)) ?? 0
        guard count == 0 else { return }

        let defaults: [(String, String, String)] = [
            ("Food", "fork.knife", "#FF6B6B"),
            ("Transport", "car.fill", "#4ECDC4"),
            ("Shopping", "bag.fill", "#45B7D1"),
            ("Entertainment", "gamecontroller.fill", "#96CEB4"),
            ("Health", "heart.fill", "#FFEAA7"),
            ("Bills", "doc.text.fill", "#A29BFE")
        ]

        for (name, icon, color) in defaults {
            let cat = Category(context: context)
            cat.id = UUID()
            cat.name = name
            cat.icon = icon
            cat.colorHex = color
            cat.createdAt = Date()
        }
        save()
    }

    // MARK: - Total this month
    func totalThisMonth(from expenses: FetchedResults<Expense>) -> Double {
        let now = Date()
        let calendar = Calendar.current
        return expenses
            .filter { calendar.isDate($0.date ?? now, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Save
    private func save() {
        do {
            try context.save()
        } catch {
            print("Save error: \(error)")
        }
    }
    
    // MARK: - Daily spending (last 7 days)
    func weeklyData(from expenses: FetchedResults<Expense>) -> [DailySpend] {
        let calendar = Calendar.current
        let today = Date()

        return (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let dayExpenses = expenses.filter {
                calendar.isDate($0.date ?? Date(), inSameDayAs: date)
            }
            let total = dayExpenses.reduce(0) { $0 + $1.amount }
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE"
            return DailySpend(day: formatter.string(from: date), date: date, amount: total)
        }
    }

    // MARK: - Category breakdown (this month)
    func categoryData(from expenses: FetchedResults<Expense>) -> [CategorySpend] {
        let calendar = Calendar.current
        let now = Date()

        let monthExpenses = expenses.filter {
            calendar.isDate($0.date ?? now, equalTo: now, toGranularity: .month)
        }

        let total = monthExpenses.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return [] }

        var grouped: [String: (Double, Category)] = [:]
        for exp in monthExpenses {
            guard let cat = exp.category, let name = cat.name else { continue }
            grouped[name, default: (0, cat)].0 += exp.amount
        }

        return grouped
            .map { name, value in
                CategorySpend(
                    name: name,
                    icon: value.1.icon ?? "tag",
                    colorHex: value.1.colorHex ?? "#888888",
                    amount: value.0,
                    percentage: (value.0 / total) * 100
                )
            }
            .sorted { $0.amount > $1.amount }
    }

    // MARK: - This month vs last month
    func monthComparison(from expenses: FetchedResults<Expense>) -> (thisMonth: Double, lastMonth: Double) {
        let calendar = Calendar.current
        let now = Date()
        let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: now)!

        let thisMonth = expenses
            .filter { calendar.isDate($0.date ?? now, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }

        let lastMonth = expenses
            .filter { calendar.isDate($0.date ?? now, equalTo: lastMonthDate, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }

        return (thisMonth, lastMonth)
    }
}
