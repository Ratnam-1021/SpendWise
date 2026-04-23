//
//  ExpenseRowView.swift
//  SpendWise
//
//  Created by Ratnam's Mac on 23/04/26.
//

import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense

    var body: some View {
        HStack(spacing: 14) {
            // Category icon bubble
            ZStack {
                Circle()
                    .fill(Color(hex: expense.category?.colorHex ?? "#888888").opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: expense.category?.icon ?? "questionmark")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: expense.category?.colorHex ?? "#888888"))
            }

            // Title + date
            VStack(alignment: .leading, spacing: 3) {
                Text(expense.title ?? "Untitled")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(expense.date?.formatted(date: .abbreviated, time: .omitted) ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Amount
            Text("₹\(expense.amount, specifier: "%.0f")")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
