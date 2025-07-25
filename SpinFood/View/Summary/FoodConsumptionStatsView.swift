//
//  FoodConsumptionStatsView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData
import Charts

enum DateRange: String, CaseIterable, Identifiable {
    case day = "D"
    case week = "W"
    case month = "M"
    case year = "Y"
    
    var id: String { self.rawValue }
    
    var title: String {
        switch self {
        case .day: return "Day"
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }
}

struct ChartData: Identifiable {
    let id = UUID()
    let date: Date
    let quantity: Double
    let name: String
}

struct FoodConsumptionStatsView: View {
    @Namespace private var namespace

    @Query var food: [FoodModel]
    @Query var consumptions: [FoodConsumptionModel]
    
    @State private var selectedRange: DateRange = .week
    @State private var referenceDate: Date = Date()
    @State private var processedChartData: [ChartData] = []
    @State private var selectedDataPoint: (date: Date, items: [ChartData])? = nil
    
    var consumedFood: [FoodModel] {
        food.filter { ($0.consumptions?.count ?? 0) > 0 || $0.eatenAt.count > 0 }
    }
    
    var dateInterval: (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: referenceDate)
        
        let start: Date
        switch selectedRange {
        case .day:
            // For day, we just use the current day from midnight to midnight
            start = end
        case .week:
            // For week, go back 6 days for a total of 7 days including today
            start = calendar.date(byAdding: .day, value: -6, to: end) ?? end
        case .month:
            // For month, go back to start of month and show complete month
            start = calendar.date(byAdding: .day, value: -29, to: end) ?? end
        case .year:
            // For year, go back 11 months for a total of 12 months
            start = calendar.date(byAdding: .month, value: -11, to: end) ?? end
        }
        
        return (start, end)
    }
    
    func prepareChartData() -> [ChartData] {
        let calendar = Calendar.current
        let interval = dateInterval
        
        let filteredConsumptions = filterConsumptionsByTimeRange(interval: interval, calendar: calendar)
        
        let groupedData = groupConsumptionsByDateAndFood(consumptions: filteredConsumptions, calendar: calendar)
        
        return createChartDataPoints(from: groupedData)
    }
    
    private func filterConsumptionsByTimeRange(interval: (start: Date, end: Date), calendar: Calendar) -> [FoodConsumptionModel] {
        return consumptions.filter { consumption in
            let consumptionDate = consumption.consumedAt
            let day = calendar.startOfDay(for: consumptionDate)
            
            switch selectedRange {
            case .day:
                return calendar.isDate(day, inSameDayAs: interval.start)
            default:
                return day >= interval.start && day <= interval.end
            }
        }
    }
    
    private func groupConsumptionsByDateAndFood(consumptions: [FoodConsumptionModel], calendar: Calendar) -> [Date: [String: Decimal]] {
        var groupedData: [Date: [String: Decimal]] = [:]
        
        // First, create empty entries for all possible dates in the range
        let interval = dateInterval
        var currentDate = interval.start
        
        while currentDate <= interval.end {
            let dateKey: Date
            
            switch selectedRange {
            case .day:
                let components = calendar.dateComponents([.year, .month, .day, .hour], from: currentDate)
                dateKey = calendar.date(from: components) ?? currentDate
                currentDate = calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
            case .week, .month:
                dateKey = calendar.startOfDay(for: currentDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case .year:
                let components = calendar.dateComponents([.year, .month], from: currentDate)
                dateKey = calendar.date(from: components) ?? currentDate
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            }
            
            groupedData[dateKey] = [:]
        }
        
        // Then fill in actual data
        for consumption in consumptions {
            let dateKey: Date
            
            switch selectedRange {
            case .day:
                let components = calendar.dateComponents([.year, .month, .day, .hour], from: consumption.consumedAt)
                dateKey = calendar.date(from: components) ?? consumption.consumedAt
            case .week, .month:
                dateKey = calendar.startOfDay(for: consumption.consumedAt)
            case .year:
                let components = calendar.dateComponents([.year, .month], from: consumption.consumedAt)
                dateKey = calendar.date(from: components) ?? consumption.consumedAt
            }
            
            let foodName = consumption.food?.name ?? "Unknown"
            let gramQuantity = consumption.unit.convertToGrams(consumption.quantity)
            
            // Safely check if the dateKey exists and create it if needed
            if groupedData[dateKey] == nil {
                groupedData[dateKey] = [:]
            }
            
            // Then safely update the food entry
            if groupedData[dateKey]?[foodName] == nil {
                groupedData[dateKey]?[foodName] = Decimal(0)
            }
            
            groupedData[dateKey]?[foodName]! += gramQuantity
        }
        
        return groupedData
    }
    
    private func createChartDataPoints(from groupedData: [Date: [String: Decimal]]) -> [ChartData] {
        var result: [ChartData] = []
        
        for (date, foodData) in groupedData {
            if foodData.isEmpty {
                // Add placeholder data with zero value to ensure date appears on axis
                result.append(ChartData(date: date, quantity: 0, name: "No Data"))
            } else {
                let sortedFoods = foodData.sorted { $0.value > $1.value }
                
                let topFoods = sortedFoods.prefix(3)
                
                for (foodName, quantity) in topFoods {
                    let doubleQuantity = NSDecimalNumber(decimal: quantity).doubleValue
                    result.append(ChartData(date: date, quantity: doubleQuantity, name: foodName))
                }
            }
        }
        
        return result.sorted { $0.date < $1.date }
    }
    
    var sortedFood: [FoodModel] {
        consumedFood.sorted { food1, food2 in
            food1.totalConsumedQuantityInGrams > food2.totalConsumedQuantityInGrams
        }
    }
    
    var dateRangeTitle: String {
        let formatter = DateFormatter()
        let interval = dateInterval
        
        switch selectedRange {
        case .day:
            formatter.dateStyle = .medium
            return formatter.string(from: interval.end)
        case .week, .month:
            formatter.dateFormat = "MMM d" // Short month and day
            return "\(formatter.string(from: interval.start)) - \(formatter.string(from: interval.end))"
        case .year:
            formatter.dateFormat = "MMM yyyy" // Short month and year
            return "\(formatter.string(from: interval.start)) - \(formatter.string(from: interval.end))"
        }
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    Text(dateRangeTitle)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Picker("Time Range", selection: $selectedRange) {
                        ForEach(DateRange.allCases) { range in
                            Text(range.rawValue)
                                .tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    
                    Chart {
                        ForEach(processedChartData) { item in
                            if item.name == "No Data" {
                                // For placeholder data, don't actually show a bar
                                // but include the date point so axis labels appear
                                RectangleMark(
                                    x: .value("Date", item.date),
                                    y: .value("Quantity", 0),
                                    width: 0,
                                    height: 0
                                )
                                .opacity(0)
                            } else {
                                BarMark(
                                    x: .value("Date", item.date),
                                    y: .value("Quantity", item.quantity)
                                )
                                .foregroundStyle(by: .value("Food", item.name))
                                .position(by: .value("Food", item.name))
                                .cornerRadius(16)
                            }
                        }
                    }
                    .frame(height: 250)
                    .chartYAxisLabel("Grams")
                    .chartLegend(position: .bottom)
                }
                .padding(.vertical)
                .onAppear {
                    processedChartData = prepareChartData()
                }
                .onChange(of: selectedRange) { _, _ in
                    processedChartData = prepareChartData()
                }
                .onChange(of: referenceDate) { _, _ in
                    processedChartData = prepareChartData()
                }
            }
            
            Section("Consumed Food") {
                ForEach(sortedFood) { food in
                    NavigationLink {
                        FoodConsumptionDetailView(food: food)
                    } label: {
                        HStack {
                            Text(food.name)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if let consumptions = food.consumptions, !consumptions.isEmpty {
                                let totalQuantity = consumptions.reduce(Decimal(0)) { $0 + $1.quantity }
                                Text("\(NSDecimalNumber(decimal: totalQuantity).doubleValue, specifier: "%.1f") \(food.unit.abbreviation)")
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("\(food.eatenAt.count) \(food.unit.abbreviation)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Food Statistics")
    }
}

struct FoodConsumptionDetailView: View {
    var food: FoodModel
    
    var sortedConsumptions: [FoodConsumptionModel] {
        (food.consumptions ?? []).sorted { $0.consumedAt > $1.consumedAt }
    }
    
    var body: some View {
        List {
            Section("Consumption History") {
                if let consumptions = food.consumptions, !consumptions.isEmpty {
                    ForEach(sortedConsumptions) { consumption in
                        HStack {
                            Text(formatDateTime(consumption.consumedAt))
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("\(NSDecimalNumber(decimal: consumption.quantity).doubleValue, specifier: "%.1f") \(consumption.unit.abbreviation)")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else if !food.eatenAt.isEmpty {
                    ForEach(food.eatenAt.sorted(by: >), id: \.self) { date in
                        Text(formatDateTime(date))
                    }
                } else {
                    Text("No consumption recorded")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(food.name)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    FoodConsumptionStatsView()
} 
