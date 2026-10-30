import SwiftUI
import SwiftData
import Charts

/// Compares this period's waste with the one before it, which is what shows whether it's going down.
struct WasteTrendLabel: View {
    let current: Double
    let previous: Double
    /// Off on the Summary post-it, where green and red would be hard to read.
    var usesColor: Bool = true

    private var difference: Double { current - previous }

    var body: some View {
        if current > 0 || previous > 0 {
            Group {
                if abs(difference) < 1 {
                    Label("Same as the previous period", systemImage: "equal")
                } else if difference < 0 {
                    Label("\(abs(difference).wasteWeightText) less than the previous period", systemImage: "arrow.down.right")
                        .foregroundStyle(usesColor ? AnyShapeStyle(.green) : AnyShapeStyle(.primary))
                } else {
                    Label("\(difference.wasteWeightText) more than the previous period", systemImage: "arrow.up.right")
                        .foregroundStyle(usesColor ? AnyShapeStyle(.red) : AnyShapeStyle(.primary))
                }
            }
        }
    }
}

struct FoodWasteStatsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \FoodWasteModel.wastedAt, order: .reverse) private var records: [FoodWasteModel]
    @Query private var consumptions: [FoodConsumptionModel]
    @Query(filter: #Predicate<FoodConsumptionModel> { $0.rescued }) private var savedRecords: [FoodConsumptionModel]

    @State private var selectedRange: DateRange = .month

    private let ranges: [DateRange] = [.week, .month, .year]

    private var paperBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .systemBackground
                : UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1)
        })
    }

    private var chartUnit: Calendar.Component {
        selectedRange == .year ? .month : .day
    }

    private func interval(periodsAgo: Int) -> DateInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let currentStart: Date
        let previousStart: Date
        switch selectedRange {
        case .year:
            let thisMonth = calendar.dateInterval(of: .month, for: today)?.start ?? today
            currentStart = calendar.date(byAdding: .month, value: -11, to: thisMonth) ?? today
            previousStart = calendar.date(byAdding: .month, value: -12, to: currentStart) ?? today
        case .month:
            currentStart = calendar.date(byAdding: .day, value: -29, to: today) ?? today
            previousStart = calendar.date(byAdding: .day, value: -30, to: currentStart) ?? today
        case .week, .day:
            currentStart = calendar.date(byAdding: .day, value: -6, to: today) ?? today
            previousStart = calendar.date(byAdding: .day, value: -7, to: currentStart) ?? today
        }
        return periodsAgo == 0
            ? DateInterval(start: currentStart, end: end)
            : DateInterval(start: previousStart, end: currentStart)
    }

    private var period: DateInterval { interval(periodsAgo: 0) }

    private var periodRecords: [FoodWasteModel] {
        records.filter { period.contains($0.wastedAt) }
    }

    private var wastedGrams: Double {
        records.estimatedGrams(in: period)
    }

    /// Share of tracked food that was thrown away rather than eaten.
    private var wastePercent: Int? {
        let eaten = consumptions
            .filter { period.contains($0.consumedAt) }
            .reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.unit.convertToGrams($1.quantity)).doubleValue }
        // Without eaten food to compare against, this would read a misleading 100%.
        guard eaten > 0, wastedGrams > 0 else { return nil }
        return max(1, Int((wastedGrams / (eaten + wastedGrams) * 100).rounded()))
    }

    private var chartData: [(date: Date, grams: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: periodRecords) {
            calendar.dateInterval(of: chartUnit, for: $0.wastedAt)?.start ?? $0.wastedAt
        }
        return grouped
            .map { (date: $0.key, grams: $0.value.reduce(0) { $0 + $1.estimatedGrams }) }
            .sorted { $0.date < $1.date }
    }

    private var mostWasted: [(name: String, emoji: String, grams: Double, times: Int)] {
        Dictionary(grouping: periodRecords, by: \.foodName)
            .map { name, entries in
                (name: name,
                 emoji: entries.first?.foodEmoji ?? "",
                 grams: entries.reduce(0) { $0 + $1.estimatedGrams },
                 times: entries.count)
            }
            .sorted { $0.grams > $1.grams }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    Picker("Time Range", selection: $selectedRange.animation()) {
                        ForEach(ranges) { range in
                            Text(range.title).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(wastedGrams.wasteWeightText)
                            .font(.system(size: 44, weight: .bold, design: .serif))
                            .contentTransition(.numericText())

                        Text("thrown away")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(.secondary)

                        WasteTrendLabel(current: wastedGrams, previous: records.estimatedGrams(in: interval(periodsAgo: 1)))
                            .font(.system(.footnote, design: .serif).weight(.medium))
                            .padding(.top, 4)

                        Text("Foods saved: \(savedRecords.filter { period.contains($0.consumedAt) }.count)")
                            .font(.system(.footnote, design: .serif).weight(.medium))
                            .foregroundStyle(.green)

                        if let wastePercent {
                            Text("\(wastePercent)% of the food you tracked")
                                .font(.system(.footnote, design: .serif))
                                .foregroundStyle(.secondary)
                        }
                    }

                    if periodRecords.isEmpty {
                        Text("Nothing thrown away in this period")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 120)
                    } else {
                        Chart(chartData, id: \.date) { item in
                            BarMark(
                                x: .value("Date", item.date, unit: chartUnit),
                                y: .value("Grams", item.grams)
                            )
                            .foregroundStyle(.red.opacity(0.75))
                            .cornerRadius(4)
                        }
                        .chartXScale(domain: period.start...period.end)
                        .chartYAxisLabel("Grams")
                        .frame(height: 200)
                    }
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if !mostWasted.isEmpty {
                Section {
                    ForEach(mostWasted, id: \.name) { item in
                        HStack(spacing: 10) {
                            Text(item.emoji)
                            Text(item.name)
                                .font(.system(.body, design: .serif))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            VStack(alignment: .trailing, spacing: 1) {
                                Text(item.grams.wasteWeightText)
                                    .font(.system(.subheadline, design: .serif))
                                Text("^[\(item.times) time](inflect: true)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                } header: {
                    sectionHeader("Most wasted")
                }
            }

            if !periodRecords.isEmpty {
                Section {
                    ForEach(periodRecords) { record in
                        HStack(spacing: 10) {
                            Text(record.foodEmoji)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(record.foodName)
                                    .font(.system(.body, design: .serif))
                                Text(record.wastedAt, format: .dateTime.day().month().year())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(record.quantity.formatted()) \(record.unit.abbreviation)")
                                .font(.system(.subheadline, design: .serif))
                                .foregroundStyle(.secondary)
                        }
                        .listRowBackground(Color.clear)
                    }
                    .onDelete { offsets in
                        let entries = periodRecords
                        for offset in offsets {
                            modelContext.delete(entries[offset])
                        }
                        modelContext.saveConfirmedChanges()
                    }
                } header: {
                    sectionHeader("History")
                } footer: {
                    Text("Weights are estimates: one piece counts as 100 g.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(paperBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Food Waste")
                    .font(.system(.title3, design: .serif).weight(.semibold))
            }
        }
    }

    private func sectionHeader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.system(.caption, design: .serif).weight(.semibold))
            .textCase(.uppercase)
            .tracking(1)
    }
}

#Preview {
    FoodWasteStatsView()
}
