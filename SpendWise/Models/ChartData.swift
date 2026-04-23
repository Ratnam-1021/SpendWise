//
//  ChartData.swift
//  SpendWise
//
//  Created by Ratnam's Mac on 23/04/26.
//

import Foundation

struct DailySpend: Identifiable {
    let id = UUID()
    let day: String        // "Mon", "Tue" etc
    let date: Date
    let amount: Double
}

struct CategorySpend: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let colorHex: String
    let amount: Double
    let percentage: Double
}
