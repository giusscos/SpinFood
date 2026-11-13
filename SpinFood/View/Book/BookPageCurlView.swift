import SwiftUI
import UIKit

// MARK: - AppNavigator

/// Opens Recipe Ideas, optionally on one recipe.
struct RecipeIdeasRequest: Identifiable {
    let id = UUID()
    var recipeID: String? = nil
}

@Observable
final class AppNavigator {
    var selectedTab: AppTab = .recipes
    var requestedBookPage: Int? = nil
    var requestedCookRecipeID: UUID? = nil
    /// A recipe to show in the book. `BookContainer` turns it into a page once the recipe has loaded.
    var requestedOpenRecipeID: UUID? = nil
    var recipeIdeasRequest: RecipeIdeasRequest? = nil
    var requestedQuickAdd: Bool = false
    /// Names of food that was just saved from expiring, for the banner that celebrates it.
    var savedFoodNames: String? = nil
    var currentBookPage: Int = 0
    var checkedShoppingItemsCount: Int = 0
    var triggerShoppingRefill: Bool = false
}

enum BookLayout {
    static let twoPagesKey = "book_two_pages"
}

// MARK: - SwiftUI Representable

struct BookPageCurlView: UIViewControllerRepresentable {
    let recipes: [RecipeModel]
    let requestedPage: Int?
    let store: Store
    let navigator: AppNavigator
    var onAdd: () -> Void
    var onShowIdeas: () -> Void = {}
    var onShowIdea: (String) -> Void = { _ in }
    var onEdit: (RecipeModel) -> Void
    var onNavigated: (Int) -> Void
    var onDeleteRecipe: (RecipeModel) -> Void = { _ in }
    var onMoveRecipes: (IndexSet, Int) -> Void = { _, _ in }
    /// Two facing pages with the spine in the middle (iPhone Duo inner display, iPad).
    var isSpread: Bool = false
    /// Fixed for the life of the controller; `BookContainer` recreates it when the setting changes.
    var turnStyle: PageTurnStyle = .curl

    func makeCoordinator() -> BookPageCoordinator {
        BookPageCoordinator()
    }

    func makeUIViewController(context: Context) -> BookPageViewController {
        let vc = BookPageViewController(isSpread: isSpread, turnStyle: turnStyle)
        vc.navigator = navigator
        vc.currentPage = navigator.currentBookPage
        context.coordinator.hostVC = vc
        vc.coordinator = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: BookPageViewController, context: Context) {
        let newIDs = recipes.map { $0.id }
        if newIDs != vc.lastRecipeIDs || vc.pages.isEmpty {
            vc.rebuild(
                recipes: recipes,
                store: store,
                navigator: navigator,
                onAdd: onAdd,
                onShowIdeas: onShowIdeas,
                onShowIdea: onShowIdea,
                onSelectRecipe: { [weak vc] recipe in
                    guard let vc,
                          let index = recipes.firstIndex(where: { $0.id == recipe.id }) else { return }
                    vc.navigateTo(page: index + 1)
                },
                onEdit: onEdit,
                onDelete: onDeleteRecipe,
                onMove: onMoveRecipes,
                onBack: { [weak vc] in
                    vc?.navigateTo(page: 0)
                },
                onSettings: { [weak vc] in
                    guard let vc else { return }
                    vc.navigateTo(page: vc.pages.count - 1)
                }
            )
        }

        if let page = requestedPage {
            vc.navigateTo(page: page)
            Task { @MainActor in onNavigated(page) }
        }
    }
}

// MARK: - Coordinator

final class BookPageCoordinator: NSObject,
    UIPageViewControllerDataSource,
    UIPageViewControllerDelegate
{
    weak var hostVC: BookPageViewController?

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        hostVC?.neighbour(of: viewController, by: -1)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        hostVC?.neighbour(of: viewController, by: 1)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let current = pageViewController.viewControllers?.first,
              let index = hostVC?.page(of: current) else { return }
        hostVC?.currentPage = index
        UIAccessibility.announcePageChange()
    }
}

// MARK: - UIPageViewController

final class BookPageViewController: BookPagesController {
    /// One controller per page: the index, each recipe, Settings, and blank pages that pad a spread.
    var pages: [UIViewController] = []
    /// What the page controller turns through: the pages, or for a sliding spread, pairs of them.
    private var units: [UIViewController] = []
    /// Mirrored to the navigator so a rebuilt book can reopen where it was.
    var currentPage: Int = 0 {
        didSet { navigator?.currentBookPage = currentPage }
    }
    var lastRecipeIDs: [UUID] = []
    weak var coordinator: BookPageCoordinator?
    weak var navigator: AppNavigator?
    private var indexHostingVC: UIHostingController<BookIndexPage>?
    let isSpread: Bool

    static let pageBackgroundColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? .systemBackground
            : UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1)
    }

    init(isSpread: Bool = false, turnStyle: PageTurnStyle = .curl) {
        self.isSpread = isSpread
        super.init(turnStyle: turnStyle, spineLocation: isSpread ? .mid : .min)
        // Facing pages turn together, like a real book.
        if turnStyle == .curl { isDoubleSided = isSpread }
        view.backgroundColor = Self.pageBackgroundColor
        onEdgeBack = { [weak self] in self?.navigateTo(page: 0) }
    }

    /// A sliding page controller shows one controller at a time, so a spread slides as a pair.
    private var slidesInPairs: Bool { isSpread && turnStyle != .curl }

    required init?(coder: NSCoder) { fatalError() }

    func rebuild(
        recipes: [RecipeModel],
        store: Store,
        navigator: AppNavigator,
        onAdd: @escaping () -> Void,
        onShowIdeas: @escaping () -> Void,
        onShowIdea: @escaping (String) -> Void,
        onSelectRecipe: @escaping (RecipeModel) -> Void,
        onEdit: @escaping (RecipeModel) -> Void,
        onDelete: @escaping (RecipeModel) -> Void,
        onMove: @escaping (IndexSet, Int) -> Void,
        onBack: @escaping () -> Void,
        onSettings: @escaping () -> Void
    ) {
        let previousIDs = lastRecipeIDs
        lastRecipeIDs = recipes.map { $0.id }
        let newIDSet = Set(lastRecipeIDs)

        var newPages: [UIViewController] = []

        let indexPage = BookIndexPage(
            recipes: recipes,
            onSelectRecipe: onSelectRecipe,
            onAdd: onAdd,
            onShowIdeas: onShowIdeas,
            onShowIdea: onShowIdea,
            onSettings: onSettings,
            onEdit: onEdit,
            onDelete: onDelete,
            onMove: onMove
        )
        if let existing = indexHostingVC {
            existing.rootView = indexPage
            newPages.append(existing)
        } else {
            let vc = UIHostingController(rootView: indexPage)
            vc.view.backgroundColor = Self.pageBackgroundColor
            indexHostingVC = vc
            newPages.append(vc)
        }

        for (i, recipe) in recipes.enumerated() {
            newPages.append(makeHostingVC(
                BookRecipePage(
                    recipe: recipe,
                    pageNumber: i + 1,
                    onEdit: { onEdit(recipe) },
                    onBack: onBack,
                    onDelete: { onDelete(recipe) },
                    // Recipe i sits on page i + 1; in a spread only the left (even) page gets "Index".
                    showsBackButton: !isSpread || (i + 1).isMultiple(of: 2)
                )
                .environment(navigator)
            ))
        }

        let hasFacingRecipe = !recipes.isEmpty && recipes.count.isMultiple(of: 2)
        newPages.append(makeHostingVC(
            // In a spread, a recipe on the facing page already has the "Index" button.
            BookEndPage(onBack: onBack, showsBackButton: !isSpread || !hasFacingRecipe)
                .environment(store)
        ))

        // An empty book shouldn't open with Settings facing the index.
        if isSpread && recipes.isEmpty {
            newPages.insert(contentsOf: [makeHostingVC(Color.clear), makeHostingVC(Color.clear)], at: 1)
        }

        // A spread always shows two pages, so pad an odd book with a blank last page.
        if isSpread && !newPages.count.isMultiple(of: 2) {
            newPages.insert(makeHostingVC(Color.clear), at: newPages.count - 1)
        }

        pages = newPages
        if slidesInPairs {
            units = stride(from: 0, to: newPages.count - 1, by: 2).map {
                SpreadPairController(left: newPages[$0], right: newPages[$0 + 1], background: Self.pageBackgroundColor)
            }
        } else {
            units = newPages
        }
        dataSource = coordinator
        delegate = coordinator

        var target = max(0, min(currentPage, pages.count - 1))
        // If the page we were on was a recipe that got deleted, go back to index
        if currentPage > 0 && currentPage <= previousIDs.count {
            let previousRecipeID = previousIDs[currentPage - 1]
            if !newIDSet.contains(previousRecipeID) {
                target = 0
            }
        }
        target = spreadStart(for: target)
        if let shown = viewControllers(showing: target) {
            currentPage = target
            display(shown)
        }
    }

    func navigateTo(page: Int) {
        guard page >= 0, page < pages.count else { return }
        let target = spreadStart(for: page)
        // Compare with the page on screen, not only the one remembered, so "Index" always works.
        let from = isJumping ? currentPage : (viewControllers?.first.flatMap(self.page(of:)) ?? currentPage)
        guard target != from, let shown = viewControllers(showing: target) else {
            currentPage = target
            return
        }
        currentPage = target
        jump(to: shown, direction: target > from ? .forward : .reverse)
    }

    /// The page before or after `controller`, for swiping.
    func neighbour(of controller: UIViewController, by offset: Int) -> UIViewController? {
        guard allowsSwiping, let index = units.firstIndex(of: controller) else { return nil }
        return units[safeIndex: index + offset]
    }

    /// The page number `controller` shows (the left page, for a pair).
    func page(of controller: UIViewController) -> Int? {
        guard let index = units.firstIndex(of: controller) else { return nil }
        return slidesInPairs ? index * 2 : index
    }

    /// In a spread, pages pair up as (0, 1), (2, 3)…; the left page identifies the spread.
    private func spreadStart(for page: Int) -> Int {
        isSpread ? page - page % 2 : page
    }

    private func viewControllers(showing page: Int) -> [UIViewController]? {
        if slidesInPairs { return units[safeIndex: page / 2].map { [$0] } }
        guard let first = pages[safeIndex: page] else { return nil }
        guard isSpread else { return [first] }
        guard let second = pages[safeIndex: page + 1] else { return nil }
        return [first, second]
    }

    private func makeHostingVC<V: View>(_ rootView: V) -> UIHostingController<V> {
        let vc = UIHostingController(rootView: rootView)
        vc.view.backgroundColor = Self.pageBackgroundColor
        return vc
    }
}

// MARK: - Helpers

extension Array {
    subscript(safeIndex index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
