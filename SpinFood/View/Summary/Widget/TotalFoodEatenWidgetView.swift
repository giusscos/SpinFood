//
//  TotalFoodEatenWidgetView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 24/07/25.
//

import Charts
import SwiftData
import SwiftUI

struct TotalFoodEatenWidgetView: View {
    @Namespace private var namespace
    
    @Query var foods: [FoodModel]
    @Query var consumptions: [FoodConsumptionModel]

    let foodConsumptionTransitionId: String = "foodConsumptionChart"

    var totalFoodEaten: Int
    
    private func getMostConsumedFood() -> FoodModel? {
        let foodWithQuantities = foods.map { food in
            (
                food: food,
                totalGrams: food.totalConsumedQuantityInGrams
            )
        }
        
        return foodWithQuantities
            .filter { $0.totalGrams > 0 }
            .sorted { $0.totalGrams > $1.totalGrams }
            .first?.food
    }
    
    private func getTotalQuantity(for food: FoodModel) -> Decimal {
        (food.consumptions ?? []).reduce(Decimal(0)) { $0 + $1.quantity }
    }
    
    var body: some View {
        if totalFoodEaten > 0 {
            Section {
                NavigationLink {
                    FoodConsumptionStatsView()
                        .navigationTransition(.zoom(sourceID: foodConsumptionTransitionId, in: namespace))
                } label: {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading) {
                            Text("Food eaten")
                                .font(.headline)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            
                            VStack(alignment: .leading) {
                                if let mostConsumed = getMostConsumedFood() {
                                    Text("\(NSDecimalNumber(decimal: getTotalQuantity(for: mostConsumed)).doubleValue, specifier: "%.1f") \(mostConsumed.unit.abbreviation)")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("\(mostConsumed.name)")
                                        .font(.title3)
                                        .fontWeight(.semibold)
                                        .lineLimit(1)
                                }
                            }
                        }
                        .padding(.vertical)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Chart {
                            ForEach(consumptions) { consumption in
                                if let foodName = consumption.food?.name {
                                    BarMark(
                                        x: .value("Food", foodName),
                                        y: .value("Amount", NSDecimalNumber(decimal: consumption.unit.convertToGrams(consumption.quantity)).doubleValue)
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
                    .matchedTransitionSource(id: foodConsumptionTransitionId, in: namespace)
                }
            }
            .listRowInsets(.init(top: 16, leading: 16, bottom: 0, trailing: 16))
        }    }
}

#Preview {
    TotalFoodEatenWidgetView(totalFoodEaten: 10)
}
