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
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                        Text(dateRangeTitle)
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    
                    Picker("Time Range", selection: $selectedRange.animation()) {
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
                        .cornerRadius(12)
                    }
                    .frame(height: 250)
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
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
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
                        Text(formatDateTime(date))
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
