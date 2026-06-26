import SwiftUI

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let subtitle: String
    var symbolColor: Color = .secondary

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 48))
                .foregroundStyle(symbolColor)

            VStack(spacing: 4) {
                Text(title)
                    .font(.system(.title3, design: .serif).weight(.semibold))

                Text(subtitle)
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}
