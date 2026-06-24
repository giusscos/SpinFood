//
//  TotalFoodRefilledWidgetView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 24/07/25.
//

import SwiftData
import SwiftUI

struct TotalFoodRefilledWidgetView: View {
    @Namespace var namespace

    @Query var foods: [FoodModel]

    let foodRefillTransitionId: String = "foodRefillChart"

    var totalFoodRefilled: Int

    var totalRefilledGrams: Double {
        foods.reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.totalRefilledQuantityInGrams).doubleValue }
    }

    var formattedTotal: String {
        if totalRefilledGrams >= 1000 {
            return String(format: "%.1f kg", totalRefilledGrams / 1000)
        } else {
            return String(format: "%.0f g", totalRefilledGrams)
        }
    }

    private func getMostRefilledFood() -> FoodModel? {
        foods
            .filter { NSDecimalNumber(decimal: $0.totalRefilledQuantityInGrams).doubleValue > 0 }
            .sorted { $0.totalRefilledQuantityInGrams > $1.totalRefilledQuantityInGrams }
            .first
    }

    private let postItColor = Color(red: 0.72, green: 0.89, blue: 1.0)

    var body: some View {
        if totalFoodRefilled > 0 {
            NavigationLink {
                FoodRefillStatsView()
                    .navigationTransition(.zoom(sourceID: foodRefillTransitionId, in: namespace))
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Food refilled")
                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                        .foregroundStyle(.black.opacity(0.55))

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(formattedTotal)
                            .font(.system(size: 64, weight: .bold, design: .serif))
                            .foregroundStyle(.black.opacity(0.82))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)

                        Text("total refilled")
                            .font(.system(.subheadline, design: .serif).weight(.medium))
                            .foregroundStyle(.black.opacity(0.45))
                    }

                    Spacer()

                    if let mostRefilled = getMostRefilledFood() {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.caption)

                            Text("\(mostRefilled.name) · \(NSDecimalNumber(decimal: mostRefilled.totalRefilledQuantity).doubleValue, specifier: "%.1f") \(mostRefilled.unit.abbreviation)")
                                .font(.system(.caption, design: .serif))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.black.opacity(0.38))
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 260 : 220)
                .background {
                    ZStack(alignment: .top) {
                        postItColor
                        VStack(spacing: 22) {
                            ForEach(0..<8, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.black.opacity(0.055))
                                    .frame(height: 1)
                            }
                        }
                        .padding(.top, 48)
                    }
                }
                .clipShape(.rect(cornerRadius: 3))
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.6))
                        .frame(width: 56, height: 16)
                        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
                        .offset(y: -8)
                }
                .rotationEffect(.degrees(-0.8))
                .padding(.vertical, 28)
                .padding(.horizontal, 20)
                .matchedTransitionSource(id: foodRefillTransitionId, in: namespace)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    TotalFoodRefilledWidgetView(totalFoodRefilled: 10)
}
