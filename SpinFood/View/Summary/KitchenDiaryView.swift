import SwiftUI
import SwiftData

/// Foo Pro's stats, written like a kitchen diary: one page per month with a short ledger of totals,
/// then what happened day by day ("Cooked Garden Salad", "Saved bread from the bin"), and the
/// detailed charts as chapters at the end.
struct KitchenDiaryView: View {
    let recipes: [RecipeModel]
    let consumptions: [FoodConsumptionModel]
    let refills: [FoodRefillModel]
    let wasteRecords: [FoodWasteModel]

    @State private var month: Date = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    /// Which way the month and the totals roll: down when going back in time, up when going forward.
    @State private var turnedBack = false

    private let calendar = Calendar.current

    private var monthInterval: DateInterval {
        calendar.dateInterval(of: .month, for: month) ?? DateInterval(start: month, duration: 0)
    }

    private var isCurrentMonth: Bool {
        calendar.isDate(month, equalTo: .now, toGranularity: .month)
    }

    private var firstMonth: Date {
        let dates = recipes.flatMap(\.cookedAt) + consumptions.map(\.consumedAt)
            + refills.map(\.refilledAt) + wasteRecords.map(\.wastedAt)
        let earliest = dates.min() ?? .now
        return calendar.dateInterval(of: .month, for: earliest)?.start ?? earliest
    }

    private var entries: [DiaryEntry] {
        DiaryEntry.build(
            in: monthInterval,
            recipes: recipes,
            consumptions: consumptions,
            refills: refills,
            wasteRecords: wasteRecords
        )
    }

    private var days: [(day: Date, entries: [DiaryEntry])] {
        Dictionary(grouping: entries) { calendar.startOfDay(for: $0.date) }
            .map { (day: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                monthHeader
                ledger
                    .padding(.top, 20)
                if let favourite {
                    Text("Most cooked: \(favourite.name), \(favourite.times)×")
                        .contentTransition(.numericText(countsDown: turnedBack))
                        .font(.system(.callout, design: .serif).italic())
                        .foregroundStyle(.secondary)
                        .padding(.top, 14)
                }

                pageRule.padding(.vertical, 28)

                if days.isEmpty {
                    Text("Nothing written this month yet.")
                        .font(.system(.body, design: .serif).italic())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 24)
                } else {
                    VStack(alignment: .leading, spacing: 26) {
                        ForEach(days, id: \.day) { day in
                            daySection(day.day, entries: day.entries)
                        }
                    }
                }

                pageRule.padding(.vertical, 28)
                chapters
                Spacer(minLength: 40)
            }
            .padding(.horizontal, 28)
            .padding(.top, 12)
        }
    }

    // MARK: - Month

    private var monthHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Button {
                turnedBack = true
                withMotion(.snappy) { month = calendar.date(byAdding: .month, value: -1, to: month) ?? month }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.weight(.semibold))
                    .padding(8)
            }
            .disabled(month <= firstMonth)
            .accessibilityLabel("Previous Month")

            Spacer()

            VStack(spacing: 2) {
                Text(month, format: .dateTime.month(.wide).year())
                    // Letters and digits roll into place, like a counter, in the direction you moved.
                    .contentTransition(.numericText(countsDown: turnedBack))
                    .font(.system(.title2, design: .serif).weight(.bold))
                    .accessibilityAddTraits(.isHeader)
                Text("Kitchen Diary")
                    .scaledFont(size: 10, weight: .semibold, design: .serif, relativeTo: .caption2)
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)

            Spacer()

            Button {
                turnedBack = false
                withMotion(.snappy) { month = calendar.date(byAdding: .month, value: 1, to: month) ?? month }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.weight(.semibold))
                    .padding(8)
            }
            .disabled(isCurrentMonth)
            .accessibilityLabel("Next Month")
        }
        .foregroundStyle(.primary)
    }

    // MARK: - Ledger

    private var cookedCount: Int { entries.filter { $0.kind == .cooked }.count }
    private var eatenCount: Int {
        consumptions.filter { !$0.rescued && monthInterval.contains($0.consumedAt) }.count
    }
    private var savedCount: Int {
        consumptions.filter { $0.rescued && monthInterval.contains($0.consumedAt) }.count
    }
    private var restockCount: Int { refills.filter { monthInterval.contains($0.refilledAt) }.count }
    private var wastedGrams: Double {
        wasteRecords.filter { monthInterval.contains($0.wastedAt) }.reduce(0) { $0 + $1.estimatedGrams }
    }

    private var favourite: (name: String, times: Int)? {
        let counts = recipes.map { recipe in
            (name: recipe.name, times: recipe.cookedAt.filter { monthInterval.contains($0) }.count)
        }
        guard let best = counts.max(by: { $0.times < $1.times }), best.times > 1 else { return nil }
        return best
    }

    private var ledger: some View {
        VStack(spacing: 12) {
            ledgerLine("Recipes cooked", value: "\(cookedCount)")
            ledgerLine("Foods eaten", value: "\(eatenCount)")
            ledgerLine("Saved from the bin", value: "\(savedCount)", tint: .green)
            ledgerLine("Restocks", value: "\(restockCount)")
            ledgerLine("Thrown away", value: wastedGrams > 0 ? wastedGrams.wasteWeightText : "0", tint: wastedGrams > 0 ? .orange : nil)
        }
    }

    /// "Recipes cooked ............ 6", like a table of contents.
    private func ledgerLine(_ label: LocalizedStringKey, value: String, tint: Color? = nil) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: 6) {
            Text(label)
                .font(.system(.body, design: .serif))
                .layoutPriority(1)
            DottedLeader()
                .accessibilityHidden(true)
            Text(verbatim: value)
                .contentTransition(.numericText(countsDown: turnedBack))
                .font(.system(.body, design: .serif).weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(tint ?? .primary)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Days

    private func daySection(_ day: Date, entries: [DiaryEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(day, format: .dateTime.weekday(.wide).day().month(.wide))
                .font(.system(.headline, design: .serif).italic())
                .accessibilityAddTraits(.isHeader)

            ForEach(entries) { entry in
                entryRow(entry)
            }
        }
    }

    private func entryRow(_ entry: DiaryEntry) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Image(systemName: entry.kind.symbol)
                .font(.subheadline)
                .foregroundStyle(entry.kind.tint)
                .frame(width: 22)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: entry.sentence)
                    .font(.system(.body, design: .serif))
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = entry.detail {
                    Text(verbatim: detail)
                        .font(.system(.footnote, design: .serif))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            Text(entry.date, format: .dateTime.hour().minute())
                .font(.system(.caption, design: .serif))
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: - Chapters

    private var chapters: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("In Detail")
                .scaledFont(size: 10, weight: .semibold, design: .serif, relativeTo: .caption2)
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
                .padding(.bottom, 6)

            chapter("I", "Recipes Cooked") { RecipeCookingStatsView() }
            chapter("II", "Food Consumption") { FoodConsumptionStatsView() }
            chapter("III", "Pantry Refills") { FoodRefillStatsView() }
            chapter("IV", "Food Waste") { FoodWasteStatsView() }
        }
    }

    private func chapter<Destination: View>(
        _ roman: String,
        _ title: LocalizedStringKey,
        @ViewBuilder destination: @escaping () -> Destination
    ) -> some View {
        NavigationLink {
            destination()
        } label: {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(verbatim: roman)
                    .font(.system(.footnote, design: .serif))
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .leading)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.primary)
                    .layoutPriority(1)
                DottedLeader()
                    .accessibilityHidden(true)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var pageRule: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Color.secondary.opacity(0.25)).frame(height: 1)
            Text(verbatim: "· · ·")
                .font(.system(.footnote, design: .serif))
                .foregroundStyle(.tertiary)
            Rectangle().fill(Color.secondary.opacity(0.25)).frame(height: 1)
        }
        .accessibilityHidden(true)
    }
}

/// The dotted line between a label and its number.
private struct DottedLeader: View {
    var body: some View {
        Line()
            .stroke(Color.secondary.opacity(0.45), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [0.1, 5]))
            .frame(height: 1.2)
            .frame(minWidth: 12)
            .alignmentGuide(.lastTextBaseline) { $0[.bottom] + 3 }
    }

    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            return path
        }
    }
}

// MARK: - Entries

struct DiaryEntry: Identifiable {
    enum Kind {
        case cooked, ate, saved, restocked, wasted

        var symbol: String {
            switch self {
            case .cooked: "frying.pan"
            case .ate: "fork.knife"
            case .saved: "leaf.fill"
            case .restocked: "cart"
            case .wasted: "trash"
            }
        }

        var tint: Color {
            switch self {
            case .cooked: .orange
            case .ate: .secondary
            case .saved: .green
            case .restocked: .blue
            case .wasted: .red
            }
        }
    }

    let id: String
    let date: Date
    let kind: Kind
    let sentence: String
    var detail: String? = nil

    /// Two things logged within this many seconds belong to one moment, like cooking a recipe
    /// and the ingredients it used, or a shopping trip's refills.
    private static let sameMoment: TimeInterval = 120

    static func build(
        in interval: DateInterval,
        recipes: [RecipeModel],
        consumptions: [FoodConsumptionModel],
        refills: [FoodRefillModel],
        wasteRecords: [FoodWasteModel]
    ) -> [DiaryEntry] {
        var result: [DiaryEntry] = []
        var usedConsumptions = Set<UUID>()

        // Cooking, with the ingredients it used folded in instead of listed one by one.
        let monthConsumptions = consumptions.filter { interval.contains($0.consumedAt) }
        for recipe in recipes {
            for date in recipe.cookedAt where interval.contains(date) {
                let used = monthConsumptions.filter {
                    !$0.rescued && !usedConsumptions.contains($0.id) && abs($0.consumedAt.timeIntervalSince(date)) < sameMoment
                }
                used.forEach { usedConsumptions.insert($0.id) }
                let names = used.compactMap { $0.food?.name }
                result.append(DiaryEntry(
                    id: "cook-\(recipe.id)-\(date.timeIntervalSince1970)",
                    date: date,
                    kind: .cooked,
                    sentence: String(localized: "Cooked \(recipe.name)"),
                    detail: names.isEmpty ? nil : String(localized: "With \(shortList(names))")
                ))
            }
        }

        // Food saved from the bin always gets its own line: it's the win worth noticing.
        for record in monthConsumptions where record.rescued {
            guard let name = record.food?.name else { continue }
            result.append(DiaryEntry(
                id: "saved-\(record.id)",
                date: record.consumedAt,
                kind: .saved,
                sentence: String(localized: "Saved \(name) from the bin")
            ))
        }

        // Everything else eaten, one line per moment.
        let eaten = monthConsumptions.filter { !$0.rescued && !usedConsumptions.contains($0.id) }
        for group in groupByMoment(eaten, date: \.consumedAt) {
            let names = group.compactMap { $0.food?.name }
            guard !names.isEmpty, let first = group.first else { continue }
            result.append(DiaryEntry(
                id: "ate-\(first.id)",
                date: first.consumedAt,
                kind: .ate,
                sentence: String(localized: "Ate \(shortList(names))")
            ))
        }

        for group in groupByMoment(refills.filter { interval.contains($0.refilledAt) }, date: \.refilledAt) {
            let names = group.compactMap { $0.food?.name }
            guard !names.isEmpty, let first = group.first else { continue }
            result.append(DiaryEntry(
                id: "restock-\(first.id)",
                date: first.refilledAt,
                kind: .restocked,
                sentence: String(localized: "Restocked \(shortList(names))")
            ))
        }

        for record in wasteRecords where interval.contains(record.wastedAt) {
            let name = record.foodName.isEmpty ? (record.food?.name ?? "") : record.foodName
            guard !name.isEmpty else { continue }
            result.append(DiaryEntry(
                id: "waste-\(record.id)",
                date: record.wastedAt,
                kind: .wasted,
                sentence: String(localized: "Threw away \(name)"),
                detail: record.estimatedGrams > 0 ? record.estimatedGrams.wasteWeightText : nil
            ))
        }

        return result
    }

    /// Records sorted by time, split wherever two are more than a couple of minutes apart.
    private static func groupByMoment<T>(_ items: [T], date: KeyPath<T, Date>) -> [[T]] {
        var groups: [[T]] = []
        for item in items.sorted(by: { $0[keyPath: date] < $1[keyPath: date] }) {
            if let last = groups.last?.last, item[keyPath: date].timeIntervalSince(last[keyPath: date]) < sameMoment {
                groups[groups.count - 1].append(item)
            } else {
                groups.append([item])
            }
        }
        return groups
    }

    /// "Milk, Bread and Eggs", or "Milk, Bread, Eggs and 3 more".
    private static func shortList(_ names: [String]) -> String {
        let unique = names.reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
        guard unique.count > 4 else { return unique.formatted(.list(type: .and)) }
        return String(localized: "\(unique.prefix(3).joined(separator: ", ")) and \(unique.count - 3) more")
    }
}
