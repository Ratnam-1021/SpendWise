//
//  AddExpenseView.swift
//  SpendWise
//
//  Created by Ratnam's Mac on 23/04/26.
//

import SwiftUI

struct AddExpenseView: View {
    @ObservedObject var vm: ExpenseViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(sortDescriptors: [SortDescriptor(\.name)])
    private var categories: FetchedResults<Category>

    @State private var title = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var selectedCategory: Category?

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(amount) != nil &&
        Double(amount)! > 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    amountField
                    detailsCard
                    categoryPicker
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(isValid ? .indigo : .secondary)
                    .disabled(!isValid)
                }
            }
        }
    }

    // MARK: - Big amount input
    private var amountField: some View {
        VStack(spacing: 6) {
            Text("Amount")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("₹")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
                TextField("0", text: $amount)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 8)
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Details card
    private var detailsCard: some View {
        VStack(spacing: 0) {
            // Title
            HStack {
                Image(systemName: "pencil")
                    .foregroundStyle(.indigo)
                    .frame(width: 24)
                TextField("What did you spend on?", text: $title)
            }
            .padding()

            Divider().padding(.leading, 52)

            // Date
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(.indigo)
                    .frame(width: 24)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                Spacer()
            }
            .padding()

            Divider().padding(.leading, 52)

            // Note
            HStack(alignment: .top) {
                Image(systemName: "note.text")
                    .foregroundStyle(.indigo)
                    .frame(width: 24)
                    .padding(.top, 2)
                TextField("Add a note (optional)", text: $note, axis: .vertical)
                    .lineLimit(3)
            }
            .padding()
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Category picker
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 3), spacing: 12) {
                ForEach(categories) { cat in
                    CategoryChipView(
                        category: cat,
                        isSelected: selectedCategory?.id == cat.id
                    )
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = cat
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Save
    private func saveExpense() {
        guard let amountDouble = Double(amount) else { return }
        vm.addExpense(
            title: title.trimmingCharacters(in: .whitespaces),
            amount: amountDouble,
            date: date,
            note: note,
            category: selectedCategory
        )
        dismiss()
    }
}
