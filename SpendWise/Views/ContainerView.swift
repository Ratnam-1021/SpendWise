//
//  ContainerView.swift
//  SpendWise
//
//  Created by Ratnam's Mac on 23/04/26.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var vm: ExpenseViewModel

    var body: some View {
        TabView {
            DashboardView(vm: vm)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            AnalyticsView(vm: vm)
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }
        }
        .tint(.indigo)
    }
}
