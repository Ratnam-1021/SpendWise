//
//  DashboardView.swift
//  SpendWise
//
//  Created by Ratnam's Mac on 23/04/26.
//

import SwiftUI

struct DashboardView: View {
    @ObservedObject var vm: ExpenseViewModel
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(sortDescriptors: [SortDescriptor(\.date, order: .reverse)])
    private var expenses: FetchedResults<Expense>

    @State private var showAddExpense = false
    @State private var showImportPicker = false
    @State private var searchText = ""

    private var filteredExpenses: [Expense] {
        if searchText.isEmpty {
            return Array(expenses)
        } else {
            return expenses.filter { 
                $0.title?.localizedCaseInsensitiveContains(searchText) ?? false ||
                $0.category?.name?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    summaryCard
                    recentExpenses
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("SpendWise")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search expenses")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showImportPicker = true
                    } label: {
                        Label("Import", systemImage: "doc.badge.plus")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.indigo)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddExpense = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.indigo)
                    }
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(vm: vm)
            }
            .sheet(isPresented: $showImportPicker) {
                DocumentPicker { url in
                    guard let document = PDFDocument(url: url), let text = document.string else { return }
                    
                    if text.contains("PhonePe") {
                        let transactions = PhonePeParser.shared.parsePDF(at: url)
                        vm.importTransactions(transactions)
                    } else if text.contains("Google Pay") || text.contains("GPay") {
                        let transactions = GPayParser.shared.parsePDF(at: url)
                        vm.importTransactions(transactions)
                    }
                }
            }
            .onAppear {
                vm.seedCategoriesIfNeeded()
            }
        }
    }

    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This month")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("₹\(vm.totalThisMonth(from: expenses), specifier: "%.0f")")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)

            Divider()

            HStack {
                Label("\(expenses.count) expenses", systemImage: "list.bullet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Label("Synced", systemImage: "icloud.and.arrow.up")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 10, y: 4)
    }

    // MARK: - Recent Expenses List
    private var recentExpenses: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(searchText.isEmpty ? "Recent" : "Search Results")
                .font(.headline)
                .padding(.horizontal, 4)

            if filteredExpenses.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 2) {
                    ForEach(filteredExpenses.prefix(20)) { expense in
                        ExpenseRowView(expense: expense)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    vm.deleteExpense(expense)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .background(.background)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)
            Text("No expenses yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Tap + to add your first one")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}
