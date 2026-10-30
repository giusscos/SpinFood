import SwiftUI

struct TotalFoodWastedWidgetView: View {
    @Namespace private var namespace

    var records: [FoodWasteModel]

    private let transitionId: String = "foodWasteChart"
    private let postItColor = Color(red: 1.0, green: 0.8, blue: 0.76)

    private var lastThirtyDays: DateInterval {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let end = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let start = calendar.date(byAdding: .day, value: -29, to: today) ?? today
        return DateInterval(start: start, end: end)
    }

    private var thirtyDaysBefore: DateInterval {
        let start = Calendar.current.date(byAdding: .day, value: -30, to: lastThirtyDays.start) ?? lastThirtyDays.start
        return DateInterval(start: start, end: lastThirtyDays.start)
    }

    private var wastedGrams: Double {
        records.estimatedGrams(in: lastThirtyDays)
    }

    var body: some View {
        if !records.isEmpty {
            NavigationLink {
                FoodWasteStatsView()
                    .navigationTransition(.zoom(sourceID: transitionId, in: namespace))
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Food wasted")
                        .font(.system(.subheadline, design: .serif).weight(.semibold))
                        .foregroundStyle(.black.opacity(0.55))

                    Spacer()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(wastedGrams.wasteWeightText)
                            .font(.system(size: 64, weight: .bold, design: .serif))
                            .foregroundStyle(.black.opacity(0.82))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)

                        Text("in the last 30 days")
                            .font(.system(.subheadline, design: .serif).weight(.medium))
                            .foregroundStyle(.black.opacity(0.45))
                    }

                    Spacer()

                    WasteTrendLabel(
                        current: wastedGrams,
                        previous: records.estimatedGrams(in: thirtyDaysBefore),
                        usesColor: false
                    )
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(.black.opacity(0.5))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: UIDevice.current.userInterfaceIdiom == .pad ? 260 : 220)
                .background {
                    ZStack(alignment: .top) {
                        postItColor
                        VStack(spacing: 22) {
                            ForEach(0..<8, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.black.opacity(0.055))
                                    .frame(height: 1)
                            }
                        }
                        .padding(.top, 48)
                    }
                }
                .clipShape(.rect(cornerRadius: 3))
                .shadow(color: .black.opacity(0.18), radius: 10, x: 0, y: 4)
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.white.opacity(0.6))
                        .frame(width: 56, height: 16)
                        .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)
                        .offset(y: -8)
                }
                .rotationEffect(.degrees(-0.8))
                .padding(.vertical, 28)
                .padding(.horizontal, 20)
                .matchedTransitionSource(id: transitionId, in: namespace)
            }
            .buttonStyle(.plain)
        }
    }
}

#Preview {
    TotalFoodWastedWidgetView(records: [])
}
