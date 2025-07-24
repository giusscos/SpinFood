//
//  TotalFoodRefilledWidgetView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 24/07/25.
//

import Charts
import SwiftData
import SwiftUI

struct TotalFoodRefilledWidgetView: View {
    @Namespace var namespace
    
    @Query var foods: [FoodModel]
    @Query var refills: [FoodRefillModel]
    
    let foodRefillTransitionId: String = "foodRefillChart"

    var totalFoodRefilled: Int
    
    private func getMostRefilledFood() -> FoodModel? {
        let foodWithQuantities = foods.map { food in
            (
                food: food,
                totalGrams: food.totalRefilledQuantityInGrams
            )
        }
        
        return foodWithQuantities
            .filter { $0.totalGrams > 0 }
            .sorted { $0.totalGrams > $1.totalGrams }
            .first?.food
    }
    
    private func getTotalRefilledQuantity(for food: FoodModel) -> Decimal {
        (food.refills ?? []).reduce(Decimal(0)) { $0 + $1.quantity }
    }

    var body: some View {
        if totalFoodRefilled > 0 {
            Section {
                NavigationLink {
                    FoodRefillStatsView()
                        .navigationTransition(.zoom(sourceID: foodRefillTransitionId, in: namespace))
                } label: {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading) {
                            Text("Food refilled")
                                .font(.headline)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            
                            VStack(alignment: .leading) {
                                if let mostRefilled = getMostRefilledFood() {
                                    Text("\(NSDecimalNumber(decimal: getTotalRefilledQuantity(for: mostRefilled)).doubleValue, specifier: "%.1f") \(mostRefilled.unit.abbreviation)")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("\(mostRefilled.name)")
                                        .font(.title3)
                                        .lineLimit(1)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                        .padding(.vertical)
                        
                        Chart {
                            ForEach(refills) { refill in
                                if let foodName = refill.food?.name {
                                    BarMark(
                                        x: .value("Food", foodName),
                                        y: .value("Amount", NSDecimalNumber(decimal: refill.unit.convertToGrams(refill.quantity)).doubleValue),
                                    )
                                    .foregroundStyle(by: .value("Food", foodName))
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .chartLegend(.hidden)
                        .chartYAxis(.hidden)
                        .chartXAxis(.hidden)
                        .padding(.top, 32)
                    }
                    .matchedTransitionSource(id: foodRefillTransitionId, in: namespace)
                }
            }
            .listRowInsets(.init(top: 16, leading: 16, bottom: 0, trailing: 16))
        }
    }
}

#Preview {
    TotalFoodRefilledWidgetView(totalFoodRefilled: 10)
}
