import SwiftUI
import UIKit

/// Asked once, at the first start after onboarding (or after updating): should pages fold like a book,
/// or slide? A small book on top lets people try the highlighted style before they pick it.
struct PageTurnChoiceView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(PageTurnStyle.storageKey) private var storedTurnStyle = ""

    /// Called with the pick. The caller saves it once the sheet is gone: saving rebuilds the book,
    /// and doing that under a closing sheet made SwiftUI drop the dismissal.
    var onChoose: (PageTurnStyle) -> Void

    @State private var selection: PageTurnStyle = .curl

    private let paper = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? .secondarySystemBackground
            : UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1)
    })

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("How should pages turn?")
                        .font(.system(.title2, design: .serif).weight(.bold))
                    Text("You can change this anytime in Settings, on the last page of your book.")
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.top, 32)

                VStack(spacing: 8) {
                    PageTurnPreview(style: selection)
                        .id(selection)
                        .frame(width: 200, height: 240)
                        .clipShape(.rect(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                        .accessibilityHidden(true)
                    Text(selection == .single ? LocalizedStringKey("Tap a dish to open it.") : LocalizedStringKey("Swipe the page to try it."))
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }

                VStack(spacing: 10) {
                    ForEach(PageTurnStyle.allCases) { style in
                        option(style)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom) {
            Button {
                onChoose(selection)
            } label: {
                Text("Continue")
                    .font(.system(.body, design: .serif).weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(paper)
        }
        .background(paper.ignoresSafeArea())
        .onAppear {
            selection = PageTurnStyle.resolved(stored: storedTurnStyle, reduceMotion: reduceMotion)
        }
        // One tap answers it; swiping the sheet away would leave the question open for next time.
        .interactiveDismissDisabled()
    }

    private func option(_ style: PageTurnStyle) -> some View {
        let isSelected = selection == style
        return Button {
            selection = style
        } label: {
            HStack(spacing: 14) {
                Image(systemName: style.systemImage)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 36)

                VStack(alignment: .leading, spacing: 3) {
                    Text(style.title)
                        .font(.system(.body, design: .serif).weight(.semibold))
                    Text(style.summary)
                        .font(.system(.subheadline, design: .serif))
                        .foregroundStyle(.secondary)
                    if style == .slide && reduceMotion {
                        Text("Suggested while Reduce Motion is on.")
                            .font(.system(.caption, design: .serif))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                .multilineTextAlignment(.leading)

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.5))
            }
            .padding(14)
            .background(Color.secondary.opacity(isSelected ? 0.10 : 0.05), in: .rect(cornerRadius: 14))
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? Color.accentColor.opacity(0.6) : .clear, lineWidth: 1.5)
            }
            .contentShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Preview book

/// A tiny book that turns the way `style` does, using the same controller as the real books.
/// "One at a Time" starts on a small index: tap a dish to open it, then go back.
private struct PageTurnPreview: UIViewControllerRepresentable {
    let style: PageTurnStyle

    private static let dishes = ["🍝", "🥗", "🍰"]

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIViewController(context: Context) -> BookPagesController {
        let controller = BookPagesController(turnStyle: style)
        let coordinator = context.coordinator
        coordinator.controller = controller
        controller.view.backgroundColor = StepBookPageViewController.pageBackground

        func host(_ view: some View) -> UIViewController {
            let host = UIHostingController(rootView: view)
            host.view.backgroundColor = StepBookPageViewController.pageBackground
            return host
        }

        var pages: [UIViewController] = []
        if style == .single {
            pages.append(host(PreviewIndexPage(dishes: Self.dishes) { [weak coordinator] i in coordinator?.open(i + 1) }))
        }
        for (i, dish) in Self.dishes.enumerated() {
            let onBack: (() -> Void)? = style == .single ? { [weak coordinator] in coordinator?.open(0) } : nil
            pages.append(host(PreviewPage(dish: dish, number: i + 1, onBack: onBack)))
        }
        coordinator.pages = pages
        controller.onEdgeBack = { [weak coordinator] in coordinator?.open(0) }
        controller.dataSource = coordinator
        if let first = pages.first {
            controller.display([first])
        }
        return controller
    }

    func updateUIViewController(_ controller: BookPagesController, context: Context) {}

    final class Coordinator: NSObject, UIPageViewControllerDataSource {
        var pages: [UIViewController] = []
        weak var controller: BookPagesController?

        func open(_ page: Int) {
            guard let controller, let target = pages[safeIndex: page],
                  let current = controller.viewControllers?.first,
                  let from = pages.firstIndex(of: current), from != page else { return }
            controller.jump(to: [target], direction: page > from ? .forward : .reverse)
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard controller?.allowsSwiping ?? true else { return nil }
            return pages.firstIndex(of: viewController).flatMap { pages[safeIndex: $0 - 1] }
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard controller?.allowsSwiping ?? true else { return nil }
            return pages.firstIndex(of: viewController).flatMap { pages[safeIndex: $0 + 1] }
        }
    }
}

private struct PreviewIndexPage: View {
    let dishes: [String]
    var onOpen: (Int) -> Void

    var body: some View {
        ZStack {
            DottedPaperBackground()
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(dishes.enumerated()), id: \.offset) { i, dish in
                    Button { onOpen(i) } label: {
                        HStack(spacing: 10) {
                            Text(verbatim: "\(i + 1)")
                                .font(.system(.caption, design: .serif))
                                .foregroundStyle(.secondary)
                                .frame(width: 14)
                            Text(dish).font(.system(size: 30))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if i < dishes.count - 1 {
                        Divider().padding(.leading, 40)
                    }
                }
            }
        }
    }
}

private struct PreviewPage: View {
    let dish: String
    let number: Int
    var onBack: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            DottedPaperBackground()
            Text(dish)
                .font(.system(size: 64))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(verbatim: "\(number)")
                .font(.system(.caption, design: .serif))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 10)
        }
        .overlay(alignment: .topLeading) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                        .padding(12)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        PageTurnChoiceView(onChoose: { _ in })
    }
}
