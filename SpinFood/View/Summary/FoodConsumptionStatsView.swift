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

// Aggiungi questa struct per contenere i dati del grafico
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
    
    // Sostituisci la proprietà chartDataPoints con questa funzione
    func prepareChartData() -> [ChartData] {
        let calendar = Calendar.current
        let interval = dateInterval
        
        // Step 1: Filtra i consumi in base all'intervallo di tempo
        let filteredConsumptions = filterConsumptionsByTimeRange(interval: interval, calendar: calendar)
        
        // Step 2: Raggruppa per data e cibo
        let groupedData = groupConsumptionsByDateAndFood(consumptions: filteredConsumptions, calendar: calendar)
        
        // Step 3: Seleziona i top 3 cibi per data e crea i dati per il grafico
        return createChartDataPoints(from: groupedData)
    }
    
    // Funzione per filtrare i consumi in base all'intervallo di tempo
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
    
    // Funzione per raggruppare i consumi per data e cibo
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
    
    // Funzione per creare i dati del grafico dai dati raggruppati
    private func createChartDataPoints(from groupedData: [Date: [String: Decimal]]) -> [ChartData] {
        var result: [ChartData] = []
        
        for (date, foodData) in groupedData {
            if foodData.isEmpty {
                // Add placeholder data with zero value to ensure date appears on axis
                result.append(ChartData(date: date, quantity: 0, name: "No Data"))
            } else {
                // Ordina i cibi per quantità
                let sortedFoods = foodData.sorted { $0.value > $1.value }
                
                // Prendi i primi 3 cibi
                let topFoods = sortedFoods.prefix(3)
                
                // Aggiungi i dati per i cibi principali
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
    
    func moveDateByPercentage(forward: Bool, percentage: Double) {
        let calendar = Calendar.current
        
        // Calculate units to move based on percentage and range
        // For small movements (< 0.2), move 1 unit
        // For large movements (> 0.75), move full range
        // Otherwise scale proportionally
        
        let factor: Int
        
        if percentage < 0.2 {
            factor = 1 // Minimal movement
        } else if percentage > 0.75 {
            // Full range movement
            switch selectedRange {
            case .day:
                factor = 24 // Move by a full day in hours
            case .week:
                factor = 7
            case .month:
                factor = 30
            case .year:
                factor = 12
            }
        } else {
            // Proportional movement
            switch selectedRange {
            case .day:
                factor = max(1, Int(24 * percentage)) // Hours in a day, more responsive
            case .week:
                factor = max(1, Int(7 * percentage))  // Days in a week
            case .month:
                factor = max(1, Int(30 * percentage)) // Approx days in a month
            case .year:
                factor = max(1, Int(12 * percentage)) // Months in a year
            }
        }
        
        // Apply movement without animation
        switch selectedRange {
        case .day:
            referenceDate = calendar.date(byAdding: .hour, value: forward ? factor : -factor, to: referenceDate) ?? referenceDate
        case .week:
            referenceDate = calendar.date(byAdding: .day, value: forward ? factor : -factor, to: referenceDate) ?? referenceDate
        case .month:
            if factor >= 30 {
                referenceDate = calendar.date(byAdding: .month, value: forward ? 1 : -1, to: referenceDate) ?? referenceDate
            } else {
                referenceDate = calendar.date(byAdding: .day, value: forward ? factor : -factor, to: referenceDate) ?? referenceDate
            }
        case .year:
            referenceDate = calendar.date(byAdding: .month, value: forward ? factor : -factor, to: referenceDate) ?? referenceDate
        }
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Consumption History")
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
                    
                    renderChart()
                        .frame(height: 250)
                        .chartXAxis {
                            renderChartXAxis()
                        }
                        .chartYAxis {
                            AxisMarks { value in
                                if let quantity = value.as(Double.self) {
                                    AxisValueLabel {
                                        Text("\(Int(quantity))g")
                                    }
                                    AxisTick()
                                }
                            }
                        }
                        .chartYAxisLabel("Amount (grams)")
                        .chartLegend(position: .bottom, alignment: .center)
                        .overlay {
                            if let selectedPoint = selectedDataPoint, 
                               !selectedPoint.items.isEmpty,
                               selectedPoint.items.contains(where: { $0.name != "No Data" && $0.quantity > 0 }) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(formatChartDate(selectedPoint.date))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    ForEach(selectedPoint.items) { item in
                                        if item.name != "No Data" && item.quantity > 0 {
                                            HStack {
                                                Circle()
                                                    .fill(Color.accentColor)
                                                    .frame(width: 8, height: 8)
                                                Text(item.name)
                                                    .font(.subheadline)
                                                Spacer()
                                                Text("\(Int(item.quantity))g")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                .padding(10)
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
                                                // Only handle taps and small movements as selections
                                                if abs(value.translation.width) < 20 {
                                                    let location = value.location
                                                    
                                                    // Find the X value at the tap position
                                                    guard let date: Date = proxy.value(atX: location.x) else { return }
                                                    
                                                    // Group all data points for this date
                                                    let pointsForDate = processedChartData.filter { 
                                                        let sameDate: Bool
                                                        
                                                        switch selectedRange {
                                                        case .day:
                                                            // Match by hour
                                                            let calendar = Calendar.current
                                                            sameDate = calendar.isDate($0.date, equalTo: date, toGranularity: .hour)
                                                        case .week, .month:
                                                            // Match by day
                                                            let calendar = Calendar.current
                                                            sameDate = calendar.isDate($0.date, equalTo: date, toGranularity: .day)
                                                        case .year:
                                                            // Match by month
                                                            let calendar = Calendar.current
                                                            sameDate = calendar.isDate($0.date, equalTo: date, toGranularity: .month)
                                                        }
                                                        
                                                        return sameDate
                                                    }
                                                    
                                                    if !pointsForDate.isEmpty {
                                                        // Use the first point's date as reference
                                                        selectedDataPoint = (date: pointsForDate[0].date, items: pointsForDate)
                                                    }
                                                }
                                            }
                                    )
                                    .simultaneousGesture(
                                        DragGesture(minimumDistance: 20)
                                            .onEnded { value in
                                                // Clear any selection first
                                                selectedDataPoint = nil
                                                
                                                // Calculate movement based on drag distance relative to chart width
                                                let chartWidth = geometry.size.width
                                                let dragPercentage = abs(value.translation.width) / chartWidth
                                                
                                                // Determine direction and amount of movement
                                                if value.translation.width > 0 {
                                                    // Swiped right - go to previous period
                                                    moveDateByPercentage(forward: false, percentage: dragPercentage)
                                                } else if value.translation.width < 0 {
                                                    // Swiped left - go to next period
                                                    moveDateByPercentage(forward: true, percentage: dragPercentage)
                                                }
                                            }
                                    )
                                    .onTapGesture {
                                        // Clear selection when tapping elsewhere on the chart
                                        selectedDataPoint = nil
                                    }
                            }
                        }
                }
                .padding(.vertical)
                .onAppear {
                    // Aggiorna i dati del grafico quando la vista appare
                    processedChartData = prepareChartData()
                }
                .onChange(of: selectedRange) { _, _ in
                    // Aggiorna i dati quando cambia l'intervallo selezionato
                    processedChartData = prepareChartData()
                }
                .onChange(of: referenceDate) { _, _ in
                    // Aggiorna i dati quando cambia la data di riferimento
                    processedChartData = prepareChartData()
                }
            }
            
            Section("Most Consumed Food") {
                ForEach(sortedFood) { food in
                    NavigationLink {
                        FoodConsumptionDetailView(food: food)
                    } label: {
                        HStack {
                            Text(food.name)
                            Spacer()
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
    
    // Funzione per renderizzare il grafico
    private func renderChart() -> some View {
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
                }
            }
        }
    }
    
    // Funzione per renderizzare l'asse X del grafico
    private func renderChartXAxis() -> some AxisContent {
        switch selectedRange {
        case .day:
            return AxisMarks(values: .stride(by: .hour, count: 6)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel(formatHourOnly(date))
                }
                AxisTick()
            }
        case .week:
            return AxisMarks(values: .stride(by: .day)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel(formatDayOnly(date))
                }
                AxisTick()
            }
        case .month:
            return AxisMarks(values: .stride(by: .day, count: 7)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel(formatDayMonth(date))
                }
                AxisTick()
            }
        case .year:
            return AxisMarks(values: .stride(by: .month)) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel(formatMonthOnly(date))
                }
                AxisTick()
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatHourOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH" // 24-hour format, no minutes
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
                            VStack(alignment: .leading) {
                                Text(formatDateTime(consumption.consumedAt))
                                    .font(.headline)
                            }
                            
                            Spacer()
                            
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
