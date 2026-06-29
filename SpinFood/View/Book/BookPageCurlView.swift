import SwiftUI
import UIKit

// MARK: - AppNavigator

@Observable
final class AppNavigator {
    var selectedTab: AppTab = .recipes
    var requestedBookPage: Int? = nil
    var currentBookPage: Int = 0
    var checkedShoppingItemsCount: Int = 0
    var triggerShoppingRefill: Bool = false
}

// MARK: - SwiftUI Representable

struct BookPageCurlView: UIViewControllerRepresentable {
    let recipes: [RecipeModel]
    let requestedPage: Int?
    var onAdd: () -> Void
    var onEdit: (RecipeModel) -> Void
    var onNavigated: (Int) -> Void
    var onDeleteRecipe: (RecipeModel) -> Void = { _ in }
    var onMoveRecipes: (IndexSet, Int) -> Void = { _, _ in }

    func makeCoordinator() -> BookPageCoordinator {
        BookPageCoordinator()
    }

    func makeUIViewController(context: Context) -> BookPageViewController {
        let vc = BookPageViewController()
        context.coordinator.hostVC = vc
        vc.coordinator = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: BookPageViewController, context: Context) {
        let newIDs = recipes.map { $0.id }
        if newIDs != vc.lastRecipeIDs || vc.pages.isEmpty {
            vc.rebuild(
                recipes: recipes,
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

    static let pageBackgroundColor = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? .systemBackground
            : UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1)
    }

    init() {
        super.init(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [.spineLocation: UIPageViewController.SpineLocation.min.rawValue]
        )
        view.backgroundColor = Self.pageBackgroundColor
    }

    required init?(coder: NSCoder) { fatalError() }

    func rebuild(
        recipes: [RecipeModel],
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
            newPages.append(makeHostingVC(BookRecipePage(
                recipe: recipe,
                pageNumber: i + 1,
                onEdit: { onEdit(recipe) },
                onBack: onBack,
                onDelete: { onDelete(recipe) }
            )))
        }

        newPages.append(makeHostingVC(BookEndPage(onBack: onBack)))

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
        if let vc = pages[safeIndex: target] {
            setViewControllers([vc], direction: .forward, animated: false)
        }
    }

    func navigateTo(page: Int) {
        guard page >= 0, page < pages.count, page != currentPage else { return }
        let direction: NavigationDirection = page > currentPage ? .forward : .reverse
        currentPage = page
        setViewControllers([pages[page]], direction: direction, animated: true)
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
