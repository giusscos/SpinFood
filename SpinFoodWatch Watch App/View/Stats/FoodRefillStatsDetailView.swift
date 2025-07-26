//
//  FoodRefillStatsDetailView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI
import SwiftData
import Charts

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
        
    var body: some View {
        List {
            Section {
                VStack {
                    
                    Text(formatDateRange(weekDateInterval))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Chart {
                        ForEach(chartData) { data in
                            BarMark(
                                x: .value("Day", data.date, unit: .day),
                                y: .value("Quantity", data.totalQuantity)
                            )
                            .foregroundStyle(Color.green.gradient)
                            .cornerRadius(16)
                        }
                    }
                    .frame(height: 127)
                    .padding()
                    
                    HStack {
                        Button {
                            // Go back one week
                            if let newDate = Calendar.current.date(byAdding: .day, value: -7, to: selectedDate) {
                                withAnimation {
                                    selectedDate = newDate
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.circle)
                        
                        Button {
                            // Go forward one week (but not beyond today)
                            if let newDate = Calendar.current.date(byAdding: .day, value: 7, to: selectedDate) {
                                withAnimation {
                                    selectedDate = min(newDate, Date())
                                }
                            }
                        } label: {
                            Image(systemName: "chevron.rigth")
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.circle)
                        .disabled(Calendar.current.isDateInToday(selectedDate) || Calendar.current.isDate(selectedDate, inSameDayAs: Date()))
                    }
                }
            }
            
            Section("Refilled Food") {
                ForEach(foodWithRefills) { foodItem in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(foodItem.name)
                                .font(.headline)
                                .lineLimit(1)
                            
                            if let refills = foodItem.refills, let lastRefill = refills.last {
                                Text("\(formatDateShort(lastRefill.refilledAt))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        let totalQuantity = (foodItem.refills ?? []).reduce(Decimal(0)) { $0 + $1.quantity }
                        Text("\(NSDecimalNumber(decimal: totalQuantity).doubleValue, specifier: "%.1f") \(foodItem.unit.abbreviation)")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
        .navigationTitle("Food Refilled")
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
