//
//  AnalyticsView.swift
//  SpendWise
//
//  Created by Ratnam's Mac on 23/04/26.
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @ObservedObject var vm: ExpenseViewModel

    @FetchRequest(sortDescriptors: [SortDescriptor(\.date, order: .reverse)])
    private var expenses: FetchedResults<Expense>

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                monthComparisonCard
                weeklyBarChart
                categoryDonutChart
            }
            .padding(.horizontal)
            .padding(.top, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Month comparison card
    private var monthComparisonCard: some View {
        let comparison = vm.monthComparison(from: expenses)
        let diff = comparison.thisMonth - comparison.lastMonth
        let isUp = diff >= 0

        return VStack(alignment: .leading, spacing: 16) {
            Text("Month overview")
                .font(.headline)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("₹\(comparison.thisMonth, specifier: "%.0f")")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Last month")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("₹\(comparison.lastMonth, specifier: "%.0f")")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }

            // Difference badge
            HStack(spacing: 4) {
                Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                Text("\(abs(diff), specifier: "%.0f") \(isUp ? "more" : "less") than last month")
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(isUp ? .red : .green)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background((isUp ? Color.red : Color.green).opacity(0.1))
            .clipShape(Capsule())
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Weekly bar chart
    private var weeklyBarChart: some View {
        let data = vm.weeklyData(from: expenses)
        let maxAmount = data.map(\.amount).max() ?? 1

        return VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("This week")
                    .font(.headline)
                Text("Daily spending")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Chart(data) { item in
                BarMark(
                    x: .value("Day", item.day),
                    y: .value("Amount", item.amount)
                )
                .foregroundStyle(
                    item.amount == maxAmount
                    ? Color.indigo
                    : Color.indigo.opacity(0.3)
                )
                .cornerRadius(6)
                .annotation(position: .top) {
                    if item.amount > 0 {
                        Text("₹\(item.amount, specifier: "%.0f")")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartYAxis(.hidden)
            .frame(height: 180)
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Category donut chart
    private var categoryDonutChart: some View {
        let data = vm.categoryData(from: expenses)

        return VStack(alignment: .leading, spacing: 16) {
            Text("By category")
                .font(.headline)

            if data.isEmpty {
                Text("No data for this month")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
            } else {
                HStack(spacing: 20) {
                    // Donut chart
                    Chart(data) { item in
                        SectorMark(
                            angle: .value("Amount", item.amount),
                            innerRadius: .ratio(0.55),
                            angularInset: 2
                        )
                        .foregroundStyle(Color(hex: item.colorHex))
                        .cornerRadius(4)
                    }
                    .frame(width: 140, height: 140)

                    // Legend
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(data.prefix(5)) { item in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(Color(hex: item.colorHex))
                                    .frame(width: 8, height: 8)
                                Text(item.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(item.percentage, specifier: "%.0f")%")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }

                // Category breakdown list
                VStack(spacing: 2) {
                    ForEach(data) { item in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: item.colorHex).opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: item.icon)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color(hex: item.colorHex))
                            }
                            Text(item.name)
                                .font(.subheadline)
                            Spacer()
                            Text("₹\(item.amount, specifier: "%.0f")")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 8)

                        if item.id != data.last?.id {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
