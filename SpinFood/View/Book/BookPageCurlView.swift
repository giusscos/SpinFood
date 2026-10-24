import SwiftUI
import UIKit

// MARK: - AppNavigator

@Observable
final class AppNavigator {
    var selectedTab: AppTab = .recipes
    var requestedBookPage: Int? = nil
    var requestedCookRecipeID: UUID? = nil
    var currentBookPage: Int = 0
    var checkedShoppingItemsCount: Int = 0
    var triggerShoppingRefill: Bool = false
}

// MARK: - SwiftUI Representable

struct BookPageCurlView: UIViewControllerRepresentable {
    let recipes: [RecipeModel]
    let requestedPage: Int?
    let store: Store
    let navigator: AppNavigator
    var onAdd: () -> Void
    var onEdit: (RecipeModel) -> Void
    var onNavigated: (Int) -> Void
    var onDeleteRecipe: (RecipeModel) -> Void = { _ in }
    var onMoveRecipes: (IndexSet, Int) -> Void = { _, _ in }
    /// Two facing pages with the spine in the middle (iPhone Duo inner display, iPad).
    var isSpread: Bool = false

    func makeCoordinator() -> BookPageCoordinator {
        BookPageCoordinator()
    }

    func makeUIViewController(context: Context) -> BookPageViewController {
        let vc = BookPageViewController(isSpread: isSpread)
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
        guard let pages = hostVC?.pages,
              let index = pages.firstIndex(of: viewController),
              index > 0 else { return nil }
        return pages[index - 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard let pages = hostVC?.pages,
              let index = pages.firstIndex(of: viewController),
              index < pages.count - 1 else { return nil }
        return pages[index + 1]
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let current = pageViewController.viewControllers?.first,
              let index = hostVC?.pages.firstIndex(of: current) else { return }
        hostVC?.currentPage = index
    }
}

// MARK: - UIPageViewController

final class BookPageViewController: UIPageViewController {
    var pages: [UIViewController] = []
    var currentPage: Int = 0
    var lastRecipeIDs: [UUID] = []
    weak var coordinator: BookPageCoordinator?
    private var indexHostingVC: UIHostingController<BookIndexPage>?
    let isSpread: Bool

    static let pageBackgroundColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? .systemBackground
            : UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1)
    }

    init(isSpread: Bool = false) {
        self.isSpread = isSpread
        let spine: UIPageViewController.SpineLocation = isSpread ? .mid : .min
        super.init(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [.spineLocation: spine.rawValue]
        )
        // Facing pages turn together, like a real book.
        isDoubleSided = isSpread
        view.backgroundColor = Self.pageBackgroundColor
    }

    required init?(coder: NSCoder) { fatalError() }

    func rebuild(
        recipes: [RecipeModel],
        store: Store,
        navigator: AppNavigator,
        onAdd: @escaping () -> Void,
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

        newPages.append(makeHostingVC(
            BookEndPage(onBack: onBack)
                .environment(store)
        ))

        // A spread always shows two pages, so pad an odd book with a blank last page.
        if isSpread && !newPages.count.isMultiple(of: 2) {
            newPages.insert(makeHostingVC(Color.clear), at: newPages.count - 1)
        }

        pages = newPages
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
            setViewControllers(shown, direction: .forward, animated: false)
        }
    }

    func navigateTo(page: Int) {
        guard page >= 0, page < pages.count else { return }
        let target = spreadStart(for: page)
        guard target != currentPage, let shown = viewControllers(showing: target) else { return }
        let direction: NavigationDirection = target > currentPage ? .forward : .reverse
        currentPage = target
        setViewControllers(shown, direction: direction, animated: true)
    }

    /// In a spread, pages pair up as (0, 1), (2, 3)…; the left page identifies the spread.
    private func spreadStart(for page: Int) -> Int {
        isSpread ? page - page % 2 : page
    }

    private func viewControllers(showing page: Int) -> [UIViewController]? {
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
