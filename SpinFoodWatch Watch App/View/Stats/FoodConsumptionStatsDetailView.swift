//
//  FoodConsumptionStatsDetailView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Food Consumption Details
struct FoodConsumptionStatsDetailView: View {
    @Query var food: [FoodModel]
    @Query var consumptions: [FoodConsumptionModel]
    @State private var selectedDate: Date = Date()
    
    var foodWithConsumptions: [FoodModel] {
        food.filter { ($0.consumptions?.count ?? 0) > 0 }
            .sorted {
                ($0.consumptions?.reduce(Decimal(0)) { $0 + $1.quantity } ?? 0) >
                ($1.consumptions?.reduce(Decimal(0)) { $0 + $1.quantity } ?? 0)
            }
    }
    
    var weekDateInterval: (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: selectedDate)
        // Get start of week (6 days back to include today)
        let start = calendar.date(byAdding: .day, value: -6, to: end) ?? end
        return (start, end)
    }
    
    var chartData: [DailyConsumptionData] {
        // Get the week interval
        let interval = weekDateInterval
        let calendar = Calendar.current
        
        // Create array of dates for the week
        var dates: [Date] = []
        var currentDate = interval.start
        
        while currentDate <= interval.end {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        // Filter consumptions within date range
        let filteredConsumptions = consumptions.filter { consumption in
            let consumptionDate = consumption.date
            return consumptionDate >= interval.start && consumptionDate <= Calendar.current.date(byAdding: .day, value: 1, to: interval.end)!
        }
        
        // Create chart data summing quantities per day
        return dates.map { date in
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            // Sum consumption quantities for this day
            let totalQuantity = filteredConsumptions
                .filter { $0.date >= dayStart && $0.date < dayEnd }
                .reduce(Decimal(0)) { total, consumption in
                    // Convert all measurements to grams for consistent comparison
                    return total + consumption.unit.convertToGrams(consumption.quantity)
                }
            
            return DailyConsumptionData(
                date: date,
                totalQuantity: NSDecimalNumber(decimal: totalQuantity).doubleValue
            )
        }
    }
    
    var topFoodsInPeriod: [FoodConsumptionData] {
        let interval = weekDateInterval
        
        // Group consumptions by food within the selected period
        let filteredConsumptions = consumptions.filter { consumption in
            let consumptionDate = consumption.date
            return consumptionDate >= interval.start && consumptionDate <= Calendar.current.date(byAdding: .day, value: 1, to: interval.end)!
        }
        
        // Group by food
        var foodConsumptions: [UUID: (food: FoodModel, quantity: Decimal, dates: [Date])] = [:]
        
        for consumption in filteredConsumptions {
            guard let foodItem = consumption.food else { continue }
            
            if var existing = foodConsumptions[foodItem.id] {
                // Add to existing entry
                existing.quantity += consumption.unit.convertToGrams(consumption.quantity)
                existing.dates.append(consumption.date)
                foodConsumptions[foodItem.id] = existing
            } else {
                // Create new entry
                foodConsumptions[foodItem.id] = (
                    food: foodItem,
                    quantity: consumption.unit.convertToGrams(consumption.quantity),
                    dates: [consumption.date]
                )
            }
        }
        
        // Convert to array and sort
        return foodConsumptions.map { _, value in
            FoodConsumptionData(
                food: value.food,
                quantity: value.quantity,
                dates: value.dates.sorted(by: >)
            )
        }
        .sorted { $0.quantity > $1.quantity }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Chart Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Consumption")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if chartData.isEmpty || chartData.allSatisfy({ $0.totalQuantity == 0 }) {
                        Text("No consumption this week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        Chart {
                            ForEach(chartData) { data in
                                BarMark(
                                    x: .value("Day", data.date, unit: .day),
                                    y: .value("Quantity", data.totalQuantity)
                                )
                                .foregroundStyle(Color.purple.gradient)
                                .cornerRadius(4)
                            }
                        }
                        .frame(height: 150)
                        .padding(.horizontal)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(formatDayShort(date))
                                    }
                                }
                            }
                        }
//                        .chartYAxis {
//                            AxisMarks {
//                                AxisValueLabel {
//                                    Text("g")
//                                        .font(.caption2)
//                                        .foregroundStyle(.secondary)
//                                }
//                            }
//                        }
                    }
                    
                    // Date navigation
                    VStack {
                        Text(formatDateRange(weekDateInterval))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding()
                        
                        HStack {
                            Button {
                                // Go back one week
                                if let newDate = Calendar.current.date(byAdding: .day, value: -7, to: selectedDate) {
                                    selectedDate = newDate
                                }
                            } label: {
                                Label("Back", systemImage: "chevron.left")
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button {
                                // Go forward one week (but not beyond today)
                                if let newDate = Calendar.current.date(byAdding: .day, value: 7, to: selectedDate) {
                                    selectedDate = min(newDate, Date())
                                }
                            } label: {
                                Label("Next", systemImage: "chevron.right")
                                    .font(.caption)
                            }
                            .disabled(Calendar.current.isDateInToday(selectedDate) || Calendar.current.isDate(selectedDate, inSameDayAs: Date()))
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color.purple.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Top consumed foods this period
                VStack(alignment: .leading, spacing: 12) {
                    Text("Most Consumed This Week")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if topFoodsInPeriod.isEmpty {
                        Text("No food consumed this week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(topFoodsInPeriod.prefix(5)) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.food.name)
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Text("\(formatDateShort(item.dates.first ?? Date()))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(NSDecimalNumber(decimal: item.quantity).doubleValue, specifier: "%.1f")g")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.purple)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.purple.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                }
                
                // All consumed foods section
                VStack(alignment: .leading, spacing: 12) {
                    Text("All Consumed Food")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(foodWithConsumptions) { foodItem in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(foodItem.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                if let consumptions = foodItem.consumptions, let lastConsumption = consumptions.max(by: { $0.date < $1.date }) {
                                    Text("Last: \(formatDateShort(lastConsumption.date))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            let totalQuantity = (foodItem.consumptions ?? []).reduce(Decimal(0)) { $0 + $1.quantity }
                            Text("\(NSDecimalNumber(decimal: totalQuantity).doubleValue, specifier: "%.1f") \(foodItem.unit.abbreviation)")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundStyle(.purple)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.05))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Food Consumed")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formatDayShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDateRange(_ interval: (start: Date, end: Date)) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: interval.start)) - \(formatter.string(from: interval.end))"
    }
}

#Preview {
    FoodConsumptionStatsDetailView()
        .modelContainer(for: [RecipeModel.self, FoodModel.self, FoodConsumptionModel.self], inMemory: true)
} 
