//
//  RecipeCookingStatsDetailView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI
import SwiftData
import Charts

struct RecipeCookingStatsDetailView: View {
    @Query var recipes: [RecipeModel]
    @State private var selectedDate: Date = Date()
    
    var cookedRecipes: [RecipeModel] {
        recipes.filter { $0.cookedAt.count > 0 }
            .sorted { $0.cookedAt.count > $1.cookedAt.count }
    }
    
    var weekDateInterval: (start: Date, end: Date) {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: selectedDate)
        // Get start of week (6 days back to include today)
        let start = calendar.date(byAdding: .day, value: -6, to: end) ?? end
        return (start, end)
    }
    
    var chartData: [ChartData] {
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
        
        // Create chart data counting cooking events per day
        return dates.map { date in
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            // Count cooking events on this day
            let count = cookedRecipes.reduce(0) { total, recipe in
                let cookingsOnDay = recipe.cookedAt.filter { 
                    $0 >= dayStart && $0 < dayEnd
                }.count
                return total + cookingsOnDay
            }
            
            return ChartData(date: date, count: count)
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
                                y: .value("Count", data.count)
                            )
                            .foregroundStyle(Color.indigo.gradient)
                            .cornerRadius(16)
                        }
                    }
                    .frame(height: 127)
                    .padding()
                    
                    HStack {
                        Button {
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
                            Image(systemName: "chevron.right")
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.circle)
                        .disabled(Calendar.current.isDateInToday(selectedDate) || Calendar.current.isDate(selectedDate, inSameDayAs: Date()))
                    }
                }
            }
            
            Section(cookedRecipes.count == 1 ? "Cooked recipe" : "Cooked recipes") {
                ForEach(cookedRecipes) { recipe in
                    HStack {
                        VStack(alignment: .leading) {
                            if recipe.cookedAt.count > 0, let lastDate = recipe.cookedAt.last {
                                Text("\(formatDateShort(lastDate))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(recipe.name)
                                .font(.headline)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("x\(recipe.cookedAt.count)")
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.indigo)
                    }
                }
            }
        }
        .navigationTitle("Cooked Recipes")
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
    RecipeCookingStatsDetailView()
        .modelContainer(for: [RecipeModel.self, FoodModel.self], inMemory: true)
} 
