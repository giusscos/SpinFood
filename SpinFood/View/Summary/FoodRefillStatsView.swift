//
//  FoodRefillStatsView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData
import Charts

struct FoodRefillStatsView: View {
    @Namespace private var namespace
    
    @Query var food: [FoodModel]
    @Query var refills: [FoodRefillModel]
    @State private var selectedRange: DateRange = .week
    @State private var referenceDate: Date = Date()
    @State private var processedChartData: [ChartData] = []
    @State private var selectedDataPoint: (date: Date, items: [ChartData])? = nil
    
    var foodWithRefills: [FoodModel] {
        food.filter { ($0.refills?.count ?? 0) > 0 }
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
        
        // Step 1: Filter the refills based on time range
        let filteredRefills = filterRefillsByTimeRange(interval: interval, calendar: calendar)
        
        // Step 2: Group by date and food
        let groupedData = groupRefillsByDateAndFood(refills: filteredRefills, calendar: calendar)
        
        // Step 3: Create chart data points
        return createChartDataPoints(from: groupedData)
    }
    
    // Function to filter refills by time range
    private func filterRefillsByTimeRange(interval: (start: Date, end: Date), calendar: Calendar) -> [FoodRefillModel] {
        return refills.filter { refill in
            let refillDate = refill.refilledAt
            let day = calendar.startOfDay(for: refillDate)
            
            switch selectedRange {
            case .day:
                return calendar.isDate(day, inSameDayAs: interval.start)
            default:
                return day >= interval.start && day <= interval.end
            }
        }
    }
    
    // Function to group refills by date and food
    private func groupRefillsByDateAndFood(refills: [FoodRefillModel], calendar: Calendar) -> [Date: [String: Decimal]] {
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
        for refill in refills {
            let dateKey: Date
            
            switch selectedRange {
            case .day:
                let components = calendar.dateComponents([.year, .month, .day, .hour], from: refill.refilledAt)
                dateKey = calendar.date(from: components) ?? refill.refilledAt
            case .week, .month:
                dateKey = calendar.startOfDay(for: refill.refilledAt)
            case .year:
                let components = calendar.dateComponents([.year, .month], from: refill.refilledAt)
                dateKey = calendar.date(from: components) ?? refill.refilledAt
            }
            
            let foodName = refill.food?.name ?? "Unknown"
            let gramQuantity = refill.unit.convertToGrams(refill.quantity)
            
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
    
    // Function to create chart data points
    private func createChartDataPoints(from groupedData: [Date: [String: Decimal]]) -> [ChartData] {
        var result: [ChartData] = []
        
        for (date, foodData) in groupedData {
            if foodData.isEmpty {
                // Add placeholder data with zero value to ensure date appears on axis
                result.append(ChartData(date: date, quantity: 0, name: "No Data"))
            } else {
                // Sort foods by quantity
                let sortedFoods = foodData.sorted { $0.value > $1.value }
                
                // Take top 3 foods
                let topFoods = sortedFoods.prefix(3)
                
                // Add data for main foods
                for (foodName, quantity) in topFoods {
                    let doubleQuantity = NSDecimalNumber(decimal: quantity).doubleValue
                    result.append(ChartData(date: date, quantity: doubleQuantity, name: foodName))
                }
            }
        }
        
        return result.sorted { $0.date < $1.date }
    }
    
    var sortedFood: [FoodModel] {
        foodWithRefills.sorted { food1, food2 in
            food1.totalRefilledQuantityInGrams > food2.totalRefilledQuantityInGrams
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
                    // Update chart data when view appears
                    processedChartData = prepareChartData()
                }
                .onChange(of: selectedRange) { _, _ in
                    // Update data when selected range changes
                    processedChartData = prepareChartData()
                }
                .onChange(of: referenceDate) { _, _ in
                    // Update data when reference date changes
                    processedChartData = prepareChartData()
                }
            }
            
            Section("Refilled Food") {
                ForEach(sortedFood) { food in
                    NavigationLink {
                        FoodRefillDetailView(food: food)
                    } label: {
                        HStack {
                            Text(food.name)
                            Spacer()
                            if let refills = food.refills, !refills.isEmpty {
                                let totalQuantity = refills.reduce(Decimal(0)) { $0 + $1.quantity }
                                Text("\(NSDecimalNumber(decimal: totalQuantity).doubleValue, specifier: "%.1f") \(food.unit.abbreviation)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Refill Statistics")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct FoodRefillDetailView: View {
    var food: FoodModel
    
    var sortedRefills: [FoodRefillModel] {
        (food.refills ?? []).sorted { $0.refilledAt > $1.refilledAt }
    }
    
    var body: some View {
        List {
            Section("Refill History") {
                if let refills = food.refills, !refills.isEmpty {
                    ForEach(sortedRefills) { refill in
                        HStack {
                            Text(formatDateTime(refill.refilledAt))
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            
                            Text("\(NSDecimalNumber(decimal: refill.quantity).doubleValue, specifier: "%.1f") \(refill.unit.abbreviation)")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("No refills recorded")
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
    FoodRefillStatsView()
} 
