import SwiftUI
import StoreKit

struct BookEndPage: View {
    var onBack: () -> Void

    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    @State private var showPaywall = false
    @State private var isRestoring = false
    @State private var restoreError: String?

    private var pageBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .systemBackground
                : UIColor(red: 0.96, green: 0.93, blue: 0.87, alpha: 1)
        })
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                pageBackground.ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        headerSection
                        sectionHeader("PREMIUM")
                        premiumSection
                        sectionHeader("GENERAL")
                        generalSection
                        sectionHeader("LEGAL")
                        legalSection
                        divider
                        creditsSection
                        Spacer().frame(height: 48)
                    }
                }

                Text("· · ·")
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(.tertiary)
                    .padding(.bottom, 12)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBack) {
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Index")
                                .font(.system(.subheadline, design: .serif))
                        }
                    }
                }
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Restore Failed", isPresented: Binding(
                get: { restoreError != nil },
                set: { if !$0 { restoreError = nil } }
            )) {
                Button("OK", role: .cancel) { restoreError = nil }
            } message: {
                if let msg = restoreError { Text(msg) }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(.orange)
                .padding(.top, 48)

            VStack(spacing: 6) {
                Text("SpinFood")
                    .font(.system(size: 30, weight: .bold, design: .serif))

                Text("Your personal recipe book")
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 28)
        .padding(.horizontal, 32)
    }

    // MARK: - Section Header

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 10, weight: .semibold, design: .serif))
            .foregroundStyle(.secondary)
            .tracking(1.5)
            .padding(.horizontal, 32)
            .padding(.top, 20)
            .padding(.bottom, 6)
    }

    // MARK: - Premium

    private var premiumSection: some View {
        VStack(spacing: 0) {
            dividerLine
            actionRow(icon: "crown", label: "Upgrade to Pro") {
                showPaywall = true
            }
            dividerLine
            Button {
                Task { await restorePurchases() }
            } label: {
                HStack(spacing: 14) {
                    Group {
                        if isRestoring {
                            ProgressView()
                                .frame(width: 24)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                                .frame(width: 24)
                        }
                    }

                    Text("Restore Purchases")
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(.quaternary)
                }
                .padding(.vertical, 14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(isRestoring)
            .padding(.horizontal, 32)
            dividerLine
        }
    }

    // MARK: - General

    private var generalSection: some View {
        VStack(spacing: 0) {
            dividerLine
            actionRow(icon: "star", label: "Rate SpinFood") {
                requestReview()
            }
            dividerLine
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        VStack(spacing: 0) {
            dividerLine
            actionRow(icon: "lock.shield", label: "Privacy Policy", isExternal: true) {
                openURL(URL(string: "https://giusscos.it/privacy")!)
            }
            dividerLine
            actionRow(icon: "doc.text", label: "Terms of Use", isExternal: true) {
                openURL(URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            }
            dividerLine
        }
    }

    // MARK: - Credits

    private var creditsSection: some View {
        VStack(spacing: 8) {
            Text("Made with ♥ by Giuseppe Cosenza")
                .font(.system(.callout, design: .serif))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text("Version \(appVersion)")
                .font(.system(.caption, design: .serif))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
    }

    // MARK: - Helpers

    private func actionRow(icon: String, label: String, isExternal: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
                    .frame(width: 24)

                Text(label)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: isExternal ? "arrow.up.right" : "chevron.right")
                    .font(.system(size: isExternal ? 12 : 11, weight: .light))
                    .foregroundStyle(.quaternary)
            }
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 32)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.18))
            .frame(height: 1)
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
    }

    private var dividerLine: some View {
        Rectangle()
            .fill(Color.secondary.opacity(0.12))
            .frame(height: 1)
            .padding(.leading, 72)
            .padding(.trailing, 32)
    }

    private func restorePurchases() async {
        isRestoring = true
        defer { isRestoring = false }
        do {
            try await AppStore.sync()
        } catch {
            restoreError = error.localizedDescription
        }
    }
}
