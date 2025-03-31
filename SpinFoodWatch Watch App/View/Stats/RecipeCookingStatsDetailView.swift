//
//  RecipeCookingStatsDetailView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI
import SwiftData
import Charts

// MARK: - Recipes Cooked Details
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
    
    var topRecipesInPeriod: [RecipeCookingData] {
        let interval = weekDateInterval
        
        let recipesInPeriod = cookedRecipes.map { recipe -> RecipeCookingData in
            let datesCookedInPeriod = recipe.cookedAt.filter { 
                $0 >= interval.start && $0 <= interval.end
            }.sorted(by: >)
            
            return RecipeCookingData(
                recipe: recipe,
                dates: datesCookedInPeriod
            )
        }.filter { !$0.dates.isEmpty }
        .sorted { $0.dates.count > $1.dates.count }
        
        return recipesInPeriod
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Chart Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Cooking Activity")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if chartData.isEmpty || chartData.allSatisfy({ $0.count == 0 }) {
                        Text("No cooking activity this week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        Chart {
                            ForEach(chartData) { data in
                                BarMark(
                                    x: .value("Day", data.date, unit: .day),
                                    y: .value("Count", data.count)
                                )
                                .foregroundStyle(Color.indigo.gradient)
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
                .background(Color.indigo.opacity(0.05))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Most cooked recipes this period
                VStack(alignment: .leading, spacing: 12) {
                    Text("Most Cooked This Week")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if topRecipesInPeriod.isEmpty {
                        Text("No recipes cooked this week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                    } else {
                        ForEach(topRecipesInPeriod.prefix(5)) { item in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(item.recipe.name)
                                        .font(.headline)
                                        .lineLimit(1)
                                    
                                    Text("\(formatDateShort(item.dates.first ?? Date()))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("\(item.dates.count)×")
                                    .font(.callout)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.indigo)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.indigo.opacity(0.05))
                            .cornerRadius(8)
                            .padding(.horizontal)
                        }
                    }
                }
                
                // All cooked recipes section
                VStack(alignment: .leading, spacing: 12) {
                    Text("All Cooked Recipes")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(cookedRecipes) { recipe in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(recipe.name)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                if recipe.cookedAt.count > 0 {
                                    Text("Last: \(formatDateShort(recipe.cookedAt.max() ?? Date()))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Text("\(recipe.cookedAt.count)×")
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundStyle(.indigo)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.indigo.opacity(0.05))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Cooked Recipes")
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
    RecipeCookingStatsDetailView()
        .modelContainer(for: [RecipeModel.self, FoodModel.self], inMemory: true)
} 
