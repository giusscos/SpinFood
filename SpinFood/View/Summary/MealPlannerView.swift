import SwiftUI
import SwiftData

// MARK: - Color helpers (view-only, not in model)

extension MealSlot {
    var color: Color {
        switch self {
        case .breakfast: return .yellow
        case .lunch:     return .green
        case .dinner:    return .indigo
        case .snack:     return .orange
        }
    }
}

// MARK: - Main View

struct MealPlannerView: View {
    @Environment(\.modelContext) private var modelContext

    @Query var allEntries: [MealPlanEntry]
    @Query(sort: \RecipeModel.name) var recipes: [RecipeModel]

    @State private var weekOffset: Int = 0
    @State private var addingFor: (date: Date, slot: MealSlot)? = nil

    private var cal: Calendar { Calendar.current }

    private var weekStart: Date {
        let today = cal.startOfDay(for: .now)
        var comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        comps.weekday = 2 // Monday
        let monday = cal.date(from: comps) ?? today
        return cal.date(byAdding: .weekOfYear, value: weekOffset, to: monday) ?? monday
    }

    private var weekDays: [Date] {
        (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private var weekLabel: String {
        guard let end = cal.date(byAdding: .day, value: 6, to: weekStart) else { return "" }
        let startFmt = DateFormatter()
        startFmt.dateFormat = "MMM d"
        let endFmt = DateFormatter()
        endFmt.dateFormat = cal.component(.month, from: weekStart) == cal.component(.month, from: end)
            ? "d" : "MMM d"
        return "\(startFmt.string(from: weekStart)) – \(endFmt.string(from: end))"
    }

    private var paperBackground: Color {
        Color(UIColor { t in
            t.userInterfaceStyle == .dark
                ? .secondarySystemBackground
                : UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 1)
        })
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                weekNavigation
                    .padding(.vertical, 14)

                VStack(spacing: 14) {
                    ForEach(weekDays, id: \.self) { day in
                        DayPlanCard(
                            day: day,
                            allEntries: allEntries,
                            onAdd: { slot in addingFor = (day, slot) },
                            onRemove: { entry in modelContext.delete(entry) }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .background(paperBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Planner")
                    .font(.system(.title3, design: .serif).weight(.semibold))
            }
        }
        .sheet(isPresented: Binding(
            get: { addingFor != nil },
            set: { if !$0 { addingFor = nil } }
        )) {
            if let (date, slot) = addingFor {
                MealRecipePickerSheet(date: date, slot: slot, recipes: recipes) { recipe in
                    let entry = MealPlanEntry(date: date, slot: slot, recipe: recipe)
                    modelContext.insert(entry)
                    addingFor = nil
                }
            }
        }
    }

    private var weekNavigation: some View {
        HStack(spacing: 24) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { weekOffset -= 1 }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
            }

            Text(weekLabel)
                .font(.system(.callout, design: .serif).weight(.medium))
                .frame(minWidth: 160)
                .multilineTextAlignment(.center)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { weekOffset += 1 }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .foregroundStyle(.primary)
    }
}

// MARK: - Day Card

private struct DayPlanCard: View {
    let day: Date
    let allEntries: [MealPlanEntry]
    let onAdd: (MealSlot) -> Void
    let onRemove: (MealPlanEntry) -> Void

    private var cal: Calendar { Calendar.current }

    private var isToday: Bool { cal.isDateInToday(day) }

    private var dayLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: day)
    }

    private func entries(for slot: MealSlot) -> [MealPlanEntry] {
        let dayStart = cal.startOfDay(for: day)
        return allEntries.filter {
            cal.startOfDay(for: $0.date) == dayStart && $0.slot == slot
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(dayLabel)
                    .font(.system(.subheadline, design: .serif).weight(.semibold))
                    .foregroundStyle(isToday ? Color.accentColor : .primary)

                if isToday {
                    Text("Today")
                        .font(.system(size: 10, design: .rounded).weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(.capsule)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)

            Rectangle()
                .fill(Color.secondary.opacity(0.15))
                .frame(height: 0.5)

            ForEach(MealSlot.allCases, id: \.self) { slot in
                slotSection(slot)
                if slot.sortOrder < MealSlot.allCases.count - 1 {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.08))
                        .frame(height: 0.5)
                        .padding(.leading, 14)
                }
            }
        }
        .background(.regularMaterial, in: .rect(cornerRadius: 14))
    }

    @ViewBuilder
    private func slotSection(_ slot: MealSlot) -> some View {
        let slotEntries = entries(for: slot)

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: slot.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(slot.color)
                    .frame(width: 16)

                Text(slot.localizedName)
                    .font(.system(.caption, design: .serif).weight(.semibold))
                    .foregroundStyle(slot.color)

                Spacer()

                Button { onAdd(slot) } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, slotEntries.isEmpty ? 10 : 6)

            ForEach(slotEntries) { entry in
                if let recipe = entry.recipe {
                    recipeRow(recipe: recipe, entry: entry)
                }
            }

            if slotEntries.isEmpty {
                Text("Nothing planned")
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
            }
        }
    }

    private func recipeRow(recipe: RecipeModel, entry: MealPlanEntry) -> some View {
        HStack(spacing: 10) {
            if let data = recipe.image, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 34)
                    .clipShape(.rect(cornerRadius: 5))
            } else {
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color.secondary.opacity(0.1))
                    .frame(width: 34, height: 34)
                    .overlay {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary.opacity(0.4))
                    }
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(recipe.name)
                    .font(.system(.callout, design: .serif))
                    .lineLimit(1)
                if recipe.duration > 0 {
                    Text(recipe.duration.formatted)
                        .font(.system(.caption2, design: .serif))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Button { onRemove(entry) } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .padding(.bottom, 5)
    }
}

// MARK: - Recipe Picker Sheet

private struct MealRecipePickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let date: Date
    let slot: MealSlot
    let recipes: [RecipeModel]
    let onSelect: (RecipeModel) -> Void

    private var slotLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE, MMM d"
        return "\(slot.localizedName) · \(fmt.string(from: date))"
    }

    var body: some View {
        NavigationStack {
            Group {
                if recipes.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 44))
                            .foregroundStyle(.secondary.opacity(0.4))
                        Text("No recipes yet")
                            .font(.system(.title3, design: .serif))
                        Text("Add recipes to start planning meals")
                            .font(.system(.subheadline, design: .serif))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(recipes) { recipe in
                            Button {
                                onSelect(recipe)
                            } label: {
                                HStack(spacing: 12) {
                                    if let data = recipe.image, let img = UIImage(data: data) {
                                        Image(uiImage: img)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 44, height: 44)
                                            .clipShape(.rect(cornerRadius: 6))
                                    } else {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.secondary.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                            .overlay {
                                                Image(systemName: "fork.knife")
                                                    .font(.system(size: 16))
                                                    .foregroundStyle(.secondary.opacity(0.4))
                                            }
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(recipe.name)
                                            .font(.system(.body, design: .serif))
                                            .foregroundStyle(.primary)
                                        HStack(spacing: 8) {
                                            if recipe.duration > 0 {
                                                Text(recipe.duration.formatted)
                                                    .font(.system(.caption, design: .serif))
                                                    .foregroundStyle(.secondary)
                                            }
                                            if let d = recipe.difficulty {
                                                Label(d.localizedName, systemImage: d.icon)
                                                    .font(.system(.caption, design: .serif))
                                                    .foregroundStyle(.secondary)
                                            }
                                        }
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle(slotLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
