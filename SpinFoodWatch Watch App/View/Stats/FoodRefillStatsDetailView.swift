//
//  FoodRefillStatsDetailView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Food Refill Details
struct FoodRefillStatsDetailView: View {
    @Query var food: [FoodModel]
    @Query var refills: [FoodRefillModel]
    @State private var selectedDate: Date = Date()
    
    var foodWithRefills: [FoodModel] {
        food.filter { ($0.refills?.count ?? 0) > 0 }
            .sorted {
                ($0.refills?.reduce(Decimal(0)) { $0 + $1.quantity } ?? 0) >
                ($1.refills?.reduce(Decimal(0)) { $0 + $1.quantity } ?? 0)
            }
    }
    
    var weekDateInterval: (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: selectedDate)
        // Get start of week (6 days back to include today)
        let start = calendar.date(byAdding: .day, value: -6, to: end) ?? end
        return (start, end)
    }
    
    var chartData: [DailyRefillData] {
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
        
        // Filter refills within date range
        let filteredRefills = refills.filter { refill in
            let refillDate = refill.refilledAt
            return refillDate >= interval.start && refillDate <= Calendar.current.date(byAdding: .day, value: 1, to: interval.end)!
        }
        
        // Create chart data summing quantities per day
        return dates.map { date in
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            // Sum refill quantities for this day
            let totalQuantity = filteredRefills
                .filter { $0.refilledAt >= dayStart && $0.refilledAt < dayEnd }
                .reduce(Decimal(0)) { total, refill in
                    // Convert all measurements to grams for consistent comparison
                    return total + refill.unit.convertToGrams(refill.quantity)
                }
            
            return DailyRefillData(
                date: date,
                totalQuantity: NSDecimalNumber(decimal: totalQuantity).doubleValue
            )
        }
    }
    
    var topFoodsInPeriod: [FoodRefillData] {
        let interval = weekDateInterval
        
        // Group refills by food within the selected period
        let filteredRefills = refills.filter { refill in
            let refillDate = refill.refilledAt
            return refillDate >= interval.start && refillDate <= Calendar.current.date(byAdding: .day, value: 1, to: interval.end)!
        }
        
        // Group by food
        var foodRefills: [UUID: (food: FoodModel, quantity: Decimal, dates: [Date])] = [:]
        
        for refill in filteredRefills {
            guard let foodItem = refill.food else { continue }
            
            if var existing = foodRefills[foodItem.id] {
                // Add to existing entry
                existing.quantity += refill.unit.convertToGrams(refill.quantity)
                existing.dates.append(refill.refilledAt)
                foodRefills[foodItem.id] = existing
            } else {
                // Create new entry
                foodRefills[foodItem.id] = (
                    food: foodItem,
                    quantity: refill.unit.convertToGrams(refill.quantity),
                    dates: [refill.refilledAt]
                )
            }
        }
        
        // Convert to array and sort
        return foodRefills.map { _, value in
            FoodRefillData(
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
                    Text("Weekly Refills")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if chartData.isEmpty || chartData.allSatisfy({ $0.totalQuantity == 0 }) {
                        Text("No refills this week")
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
                                .foregroundStyle(Color.green.gradient)
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
                .background(Color.green.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Top refilled foods this period
                VStack(alignment: .leading, spacing: 12) {
                    Text("Most Refilled This Week")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if topFoodsInPeriod.isEmpty {
                        Text("No food refilled this week")
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
                                    .foregroundStyle(.green)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                }
                
                // All refilled foods section
                VStack(alignment: .leading, spacing: 12) {
                    Text("All Refilled Food")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(foodWithRefills) { foodItem in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(foodItem.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                if let refills = foodItem.refills, let lastRefill = refills.max(by: { $0.refilledAt < $1.refilledAt }) {
                                    Text("Last: \(formatDateShort(lastRefill.refilledAt))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            let totalQuantity = (foodItem.refills ?? []).reduce(Decimal(0)) { $0 + $1.quantity }
                            Text("\(NSDecimalNumber(decimal: totalQuantity).doubleValue, specifier: "%.1f") \(foodItem.unit.abbreviation)")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundStyle(.green)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.green.opacity(0.05))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Food Refilled")
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
    FoodRefillStatsDetailView()
        .modelContainer(for: [RecipeModel.self, FoodModel.self, FoodRefillModel.self], inMemory: true)
} 
