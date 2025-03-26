import SwiftUI
import SwiftData
import Charts

struct RecipeCookingStatsView: View {
    @Namespace private var namespace
    
    @Query var recipes: [RecipeModel]
    @State private var selectedRange: DateRange = .week
    @State private var referenceDate: Date = Date()
    @State private var selectedDataPoint: (date: Date, count: Int)? = nil
    
    var cookedRecipes: [RecipeModel] {
        recipes.filter { $0.cookedAt.count > 0 }
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
    
    var chartDataPoints: [(date: Date, count: Int)] {
        let calendar = Calendar.current
        let interval = dateInterval
        
        // Step 1: Filter cooking dates within the selected interval
        let filteredDates = cookedRecipes.flatMap { recipe in
            recipe.cookedAt.filter { date in
                let day = calendar.startOfDay(for: date)
                return day >= interval.start && day <= interval.end
            }
        }
        
        // Step 2: Group dates based on the selected range
        var groupedData: [Date: Int] = [:]
        
        // Create all possible dates in the range to ensure even distribution
        var currentDate = interval.start
        while currentDate <= interval.end {
            groupedData[currentDate] = 0
            
            switch selectedRange {
            case .day:
                // For day view, group by hour
                currentDate = calendar.date(byAdding: .hour, value: 1, to: currentDate) ?? currentDate
            case .week:
                // For week view, group by day
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case .month:
                // For month view, group by day
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            case .year:
                // For year view, group by month
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            }
        }
        
        // Count items in each group
        for date in filteredDates {
            let groupKey: Date
            
            switch selectedRange {
            case .day:
                // For day, group by hour
                let components = calendar.dateComponents([.year, .month, .day, .hour], from: date)
                groupKey = calendar.date(from: components) ?? date
            case .week, .month:
                // For week and month, group by day
                groupKey = calendar.startOfDay(for: date)
            case .year:
                // For year, group by month
                let components = calendar.dateComponents([.year, .month], from: date)
                groupKey = calendar.date(from: components) ?? date
            }
            
            // Safely increment count
            groupedData[groupKey] = (groupedData[groupKey] ?? 0) + 1
        }
        
        return groupedData.map { (date: $0.key, count: $0.value) }
            .sorted { $0.date < $1.date }
    }
    
    var sortedRecipes: [RecipeModel] {
        cookedRecipes.sorted { $0.cookedAt.count > $1.cookedAt.count }
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
    
    func moveDate(forward: Bool) {
        let calendar = Calendar.current
        
        switch selectedRange {
        case .day:
            referenceDate = calendar.date(byAdding: .day, value: forward ? 1 : -1, to: referenceDate) ?? referenceDate
        case .week:
            referenceDate = calendar.date(byAdding: .day, value: forward ? 7 : -7, to: referenceDate) ?? referenceDate
        case .month:
            referenceDate = calendar.date(byAdding: .month, value: forward ? 1 : -1, to: referenceDate) ?? referenceDate
        case .year:
            referenceDate = calendar.date(byAdding: .year, value: forward ? 1 : -1, to: referenceDate) ?? referenceDate
        }
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Cooking History")
                            .font(.headline)
                        Spacer()
                        Text(dateRangeTitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Picker("Time Range", selection: $selectedRange) {
                        ForEach(DateRange.allCases) { range in
                            Text(range.rawValue)
                                .tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    
                    Chart(chartDataPoints, id: \.date) { item in
                        BarMark(
                            x: .value("Date", item.date),
                            y: .value("Recipes", item.count)
                        )
                        .foregroundStyle(.indigo.gradient)
                        .cornerRadius(4)
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        switch selectedRange {
                        case .day:
                            AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel(formatHourOnly(date))
                                }
                                AxisTick()
                            }
                        case .week:
                            AxisMarks(values: .stride(by: .day)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel(formatDayOnly(date))
                                }
                                AxisTick()
                            }
                        case .month:
                            AxisMarks(values: .stride(by: .day, count: 7)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel(formatDayMonth(date))
                                }
                                AxisTick()
                            }
                        case .year:
                            AxisMarks(values: .stride(by: .month)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel(formatMonthOnly(date))
                                }
                                AxisTick()
                            }
                        }
                    }
                    .overlay {
                        if let selectedPoint = selectedDataPoint {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(formatChartDate(selectedPoint.date))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("\(selectedPoint.count) recipe\(selectedPoint.count == 1 ? "" : "s") cooked")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .cornerRadius(8)
                            .padding(8)
                            .transition(.opacity)
                        }
                    }
                    .chartOverlay { proxy in
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(Color.clear)
                                .contentShape(Rectangle())
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            let location = value.location
                                            
                                            // Find the X value at the tap position
                                            guard let date: Date = proxy.value(atX: location.x) else { return }
                                            
                                            // Find the closest data point
                                            let closestPoint = chartDataPoints.min(by: {
                                                abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date))
                                            })
                                            
                                            if let point = closestPoint {
                                                selectedDataPoint = point
                                            }
                                        }
                                        .onEnded { _ in
                                            // Keep the selection visible
                                        }
                                )
                                .onTapGesture {
                                    // Clear selection when tapping elsewhere on the chart
                                    selectedDataPoint = nil
                                }
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                // Clear any selection first
                                selectedDataPoint = nil
                                
                                // Determine direction based on final velocity rather than distance
                                if value.translation.width > 0 {
                                    // Swiped right - go to previous period
                                    withAnimation(.spring()) {
                                        moveDate(forward: false)
                                    }
                                } else if value.translation.width < 0 {
                                    // Swiped left - go to next period
                                    withAnimation(.spring()) {
                                        moveDate(forward: true)
                                    }
                                }
                            }
                    )
                }
                .padding(.vertical)
            }
            
            Section("Recipes Cooked") {
                ForEach(sortedRecipes) { recipe in
                    NavigationLink {
                        RecipeCookingDetailView(recipe: recipe)
                    } label: {
                        HStack {
                            Text(recipe.name)
                            Spacer()
                            Text("\(recipe.cookedAt.count) times")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Cooking Statistics")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDayOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // First three letters of weekday
        return formatter.string(from: date)
    }
    
    private func formatDayMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd" // Day of month as two digits
        return formatter.string(from: date)
    }
    
    private func formatMonthOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM" // First letter of month
        return String(formatter.string(from: date).prefix(1))
    }
    
    private func formatHourOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH" // 24-hour format, no minutes
        return formatter.string(from: date)
    }
    
    // Format date for chart overlay based on selected range
    private func formatChartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        
        switch selectedRange {
        case .day:
            formatter.dateFormat = "h a"  // Hour with AM/PM
            return formatter.string(from: date)
        case .week:
            formatter.dateFormat = "EEE, MMM d"  // Weekday, Month Day
            return formatter.string(from: date)
        case .month:
            formatter.dateFormat = "MMM d"  // Month Day
            return formatter.string(from: date)
        case .year:
            formatter.dateFormat = "MMMM yyyy"  // Full Month Year
            return formatter.string(from: date)
        }
    }
}

struct RecipeCookingDetailView: View {
    var recipe: RecipeModel
    
    var sortedCookingDates: [Date] {
        recipe.cookedAt.sorted(by: >)
    }
    
    var body: some View {
        List {
            Section("Cooking History") {
                if !sortedCookingDates.isEmpty {
                    ForEach(sortedCookingDates, id: \.self) { date in
                        HStack {
                            Text(formatDateTime(date))
                            Spacer()
                            if Calendar.current.isDateInToday(date) {
                                Text("Today")
                                    .foregroundStyle(.blue)
                            } else if Calendar.current.isDateInYesterday(date) {
                                Text("Yesterday")
                                    .foregroundStyle(.indigo)
                            }
                        }
                    }
                } else {
                    Text("No cooking recorded")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(recipe.name)
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    RecipeCookingStatsView()
} 
