//
//  CategoryChipView.swift
//  SpendWise
//
//  Created by Ratnam's Mac on 23/04/26.
//

import SwiftUI

struct CategoryChipView: View {
    let category: Category
    let isSelected: Bool

    var color: Color {
        Color(hex: category.colorHex ?? "#888888")
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(isSelected ? color : color.opacity(0.12))
                    .frame(width: 50, height: 50)
                Image(systemName: category.icon ?? "tag")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? .white : color)
            }
            Text(category.name ?? "")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(isSelected ? color : .secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(isSelected ? color.opacity(0.08) : Color(.systemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? color : .clear, lineWidth: 1.5)
        )
        .animation(.spring(response: 0.3), value: isSelected)
    }
}
