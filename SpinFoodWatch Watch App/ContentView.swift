//
//  ContentView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasPaid") var hasPaid: Bool = false
    
    @State private var watchStore = WatchStore()
    
    var body: some View {
        if !watchStore.purchasedProductIDs.isEmpty || hasPaid {
            TabView {
                StatsView()
                RecipeListView()
                FoodListView()
            }
            .onAppear() {
                hasPaid = true
            }
        } else {
            Text("Subscribe or buy lifetime access on the iPhone app")
                .padding()
                .multilineTextAlignment(.center)
                .onAppear() {
                    hasPaid = false
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [RecipeModel.self], inMemory: true)
}
