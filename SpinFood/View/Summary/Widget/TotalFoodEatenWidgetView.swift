//
//  TotalFoodEatenWidgetView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 24/07/25.
//

import SwiftData
import SwiftUI

struct TotalFoodEatenWidgetView: View {
    @Namespace private var namespace
    
    @Query var foods: [FoodModel]

    let foodConsumptionTransitionId: String = "foodConsumptionChart"

    var totalFoodEaten: Int

    var totalConsumedGrams: Double {
        foods.reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.totalConsumedQuantityInGrams).doubleValue }
    }

    var formattedTotal: String {
        if totalConsumedGrams >= 1000 {
            return String(format: "%.1f kg", totalConsumedGrams / 1000)
        } else {
            return String(format: "%.0f g", totalConsumedGrams)
        }
    }

    private func getMostConsumedFood() -> FoodModel? {
        foods
            .filter { NSDecimalNumber(decimal: $0.totalConsumedQuantityInGrams).doubleValue > 0 }
            .sorted { $0.totalConsumedQuantityInGrams > $1.totalConsumedQuantityInGrams }
            .first
    }

    var body: some View {
        if totalFoodEaten > 0 {
            NavigationLink {
                FoodConsumptionStatsView()
                    .navigationTransition(.zoom(sourceID: foodConsumptionTransitionId, in: namespace))
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Food eaten")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(formattedTotal)
                            .font(.system(size: 64, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)

                        Text("total eaten")
                            .font(.system(.subheadline, design: .rounded).weight(.medium))
                            .foregroundStyle(.white.opacity(0.75))
                    }

                    Spacer()

                    if let mostConsumed = getMostConsumedFood() {
                        HStack(spacing: 4) {
                            Image(systemName: "fork.knife")
                                .font(.caption)

                            Text("\(mostConsumed.name) · \(NSDecimalNumber(decimal: mostConsumed.totalConsumedQuantity).doubleValue, specifier: "%.1f") \(mostConsumed.unit.abbreviation)")
                                .font(.system(.caption, design: .rounded))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 260 : 220)
                .background(
                    LinearGradient(
                        colors: [.green, .teal.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(.rect(cornerRadius: 4))
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
                .rotationEffect(.degrees(1.0))
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .matchedTransitionSource(id: foodConsumptionTransitionId, in: namespace)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    TotalFoodEatenWidgetView(totalFoodEaten: 10)
}
