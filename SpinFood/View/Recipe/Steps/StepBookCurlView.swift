import SwiftUI
import UIKit
import SwiftData

// MARK: - Mode

enum StepBookMode: Equatable {
    case edit
    case cook
    case view
}

// MARK: - SwiftUI Representable

struct StepBookCurlView: UIViewControllerRepresentable {
    @Environment(\.modelContext) private var modelContext

    var steps: [StepRecipe]
    var ingredients: [RecipeFoodModel]
    var mode: StepBookMode
    var startPage: Int = 0
    var onPageChange: ((Int) -> Void)? = nil
    var onDismiss: (() -> Void)? = nil
    var onAddStep: (() -> Void)? = nil
    var onDeleteStep: ((StepRecipe) -> Void)? = nil
    var onMoveSteps: ((IndexSet, Int) -> Void)? = nil
    var onFinishCooking: (() -> Void)? = nil

    func makeCoordinator() -> StepBookCoordinator { StepBookCoordinator() }

    func makeUIViewController(context: Context) -> StepBookPageViewController {
        let vc = StepBookPageViewController(modelContext: modelContext, startPage: startPage)
        context.coordinator.hostVC = vc
        vc.coordinator = context.coordinator
        return vc
    }

    func updateUIViewController(_ vc: StepBookPageViewController, context: Context) {
        context.coordinator.onPageChange = onPageChange

        let newIDs = steps.map { $0.id }
        guard newIDs != vc.lastStepIDs || vc.currentMode != mode else { return }

        let oldCount = vc.lastStepIDs.count
        let newCount = newIDs.count
        vc.currentMode = mode

        vc.rebuild(
            steps: steps,
            ingredients: ingredients,
            mode: mode,
            onDismiss: onDismiss,
            onAddStep: onAddStep,
            onDeleteStep: onDeleteStep,
            onMoveSteps: onMoveSteps,
            onFinishCooking: onFinishCooking
        )

        // Auto-navigate to a newly added step
        if mode == .edit && newCount > oldCount && newCount > 0 {
            vc.navigateTo(page: newCount)
        }
    }
}

// MARK: - Coordinator

final class StepBookCoordinator: NSObject,
    UIPageViewControllerDataSource,
    UIPageViewControllerDelegate
{
    weak var hostVC: StepBookPageViewController?
    var onPageChange: ((Int) -> Void)?

    func pageViewController(
        _ pvc: UIPageViewController,
        viewControllerBefore vc: UIViewController
    ) -> UIViewController? {
        guard let pages = hostVC?.pages,
              let i = pages.firstIndex(of: vc), i > 0 else { return nil }
        return pages[i - 1]
    }

    func pageViewController(
        _ pvc: UIPageViewController,
        viewControllerAfter vc: UIViewController
    ) -> UIViewController? {
        guard let pages = hostVC?.pages,
              let i = pages.firstIndex(of: vc), i < pages.count - 1 else { return nil }
        return pages[i + 1]
    }

    func pageViewController(
        _ pvc: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed,
              let current = pvc.viewControllers?.first,
              let i = hostVC?.pages.firstIndex(of: current) else { return }
        hostVC?.currentPage = i
        onPageChange?(i)
    }
}

// MARK: - UIPageViewController

final class StepBookPageViewController: UIPageViewController {
    var pages: [UIViewController] = []
    var currentPage: Int = 0
    var lastStepIDs: [UUID] = []
    var currentMode: StepBookMode = .edit
    weak var coordinator: StepBookCoordinator?
    let modelContext: ModelContext

    static let pageBackground = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? .systemBackground
            : UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1)
    }

    init(modelContext: ModelContext, startPage: Int = 0) {
        self.modelContext = modelContext
        self.currentPage = startPage
        super.init(
            transitionStyle: .pageCurl,
            navigationOrientation: .horizontal,
            options: [.spineLocation: UIPageViewController.SpineLocation.min.rawValue]
        )
        view.backgroundColor = Self.pageBackground
    }

    required init?(coder: NSCoder) { fatalError() }

    func rebuild(
        steps: [StepRecipe],
        ingredients: [RecipeFoodModel],
        mode: StepBookMode,
        onDismiss: (() -> Void)?,
        onAddStep: (() -> Void)?,
        onDeleteStep: ((StepRecipe) -> Void)?,
        onMoveSteps: ((IndexSet, Int) -> Void)?,
        onFinishCooking: (() -> Void)?
    ) {
        lastStepIDs = steps.map { $0.id }
        var newPages: [UIViewController] = []

        if mode == .edit {
            newPages.append(makeHostingVC(
                StepIndexPageView(
                    steps: steps,
                    onDone: { onDismiss?() },
                    onAdd: { onAddStep?() },
                    onDelete: { step in onDeleteStep?(step) },
                    onMove: { set, dest in onMoveSteps?(set, dest) },
                    onSelectStep: { [weak self] step in
                        guard let self,
                              let i = steps.firstIndex(where: { $0.id == step.id }) else { return }
                        navigateTo(page: i + 1)
                    }
                )
            ))
        }

        let total = steps.count
        for (i, step) in steps.enumerated() {
            newPages.append(makeHostingVC(
                StepNotePageView(
                    step: step,
                    stepNumber: i + 1,
                    totalSteps: total,
                    ingredients: ingredients,
                    allSteps: steps,
                    isEditing: mode == .edit,
                    isCooking: mode == .cook || mode == .view,
                    onBack: mode == .edit ? { [weak self] in self?.navigateTo(page: 0) } : nil,
                    onDelete: mode == .edit ? { [weak self] in
                        self?.navigateTo(page: 0)
                        onDeleteStep?(step)
                    } : nil,
                    onClose: (mode == .cook || mode == .view) ? { onDismiss?() } : nil
                )
            ))
        }

        if mode == .cook {
            newPages.append(makeHostingVC(
                StepCookDonePage(onFinish: { onFinishCooking?() })
            ))
        }

        pages = newPages
        dataSource = coordinator
        delegate = coordinator

        let target = max(0, min(currentPage, pages.count - 1))
        if let vc = pages[safeIndex: target] {
            setViewControllers([vc], direction: .forward, animated: false)
        }
    }

    func navigateTo(page: Int) {
        guard page >= 0, page < pages.count, page != currentPage else { return }
        let dir: NavigationDirection = page > currentPage ? .forward : .reverse
        currentPage = page
        setViewControllers([pages[page]], direction: dir, animated: true)
    }

    private func makeHostingVC<V: View>(_ rootView: V) -> UIViewController {
        let vc = UIHostingController(rootView: rootView.environment(\.modelContext, modelContext))
        vc.view.backgroundColor = Self.pageBackground
        return vc
    }
}

// MARK: - Step Index Page (edit mode)

private struct StepIndexPageView: View {
    var steps: [StepRecipe]
    var onDone: () -> Void
    var onAdd: () -> Void
    var onDelete: (StepRecipe) -> Void
    var onMove: (IndexSet, Int) -> Void
    var onSelectStep: (StepRecipe) -> Void

    @State private var isReordering = false

    private let pageColor = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? .systemBackground
            : UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1)
    })

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                pageColor.ignoresSafeArea()
                DottedPaperBackground().ignoresSafeArea()

                if steps.isEmpty {
                    emptyState
                } else {
                    stepList
                }

                if !isReordering {
                    Text("Index")
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 12)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("Steps")
                            .font(.title.weight(.bold))
                            .fontDesign(.serif)
                        Text(steps.isEmpty ? "No steps" : "\(steps.count) step\(steps.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if !steps.isEmpty {
                        Button(isReordering ? "Done" : "Reorder") {
                            withAnimation { isReordering.toggle() }
                        }
                        .font(.system(.body, design: .serif))
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !isReordering {
                        Button(action: onAdd) { Image(systemName: "plus") }
                        Button("Done", action: onDone)
                            .font(.system(.body, design: .serif).weight(.semibold))
                    }
                }
            }
        }
    }

    private var stepList: some View {
        List {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                stepRow(index: index + 1, step: step)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                    .onTapGesture { if !isReordering { onSelectStep(step) } }
            }
            .onDelete { set in set.forEach { onDelete(steps[$0]) } }
            .onMove(perform: onMove)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(isReordering ? .active : .inactive))
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 48) }
    }

    private func stepRow(index: Int, step: StepRecipe) -> some View {
        HStack(spacing: 0) {
            Text("\(index)")
                .font(.system(size: 15, weight: .light, design: .serif))
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .center)

            VStack(alignment: .leading, spacing: 3) {
                let preview = stepPreview(step)
                Text(preview.isEmpty ? "Step \(index)" : preview)
                    .font(.system(.body, design: .serif))
                    .lineLimit(1)
                let count = step.sortedBlocks.count
                if count > 0 {
                    Text("\(count) block\(count == 1 ? "" : "s")")
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(.secondary)
                } else if !step.text.isEmpty {
                    Text("Tap to add rich content")
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.light))
                .foregroundStyle(.quaternary)
                .padding(.trailing, 32)
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private func stepPreview(_ step: StepRecipe) -> String {
        if let block = step.sortedBlocks.first(where: { $0.type == .text }) {
            return block.textContent
        }
        return step.text
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.number")
                .font(.system(size: 52))
                .foregroundStyle(.secondary.opacity(0.4))
            Text("No steps yet")
                .font(.system(.title3, design: .serif))
            Text("Tap + to add your first step")
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Cook Done Page

private struct StepCookDonePage: View {
    var onFinish: () -> Void

    var body: some View {
        ZStack {
            DottedPaperBackground().ignoresSafeArea()
            VStack(spacing: 28) {
                Text("🍽️")
                    .font(.system(size: 72))
                VStack(spacing: 8) {
                    Text("All done!")
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                    Text("Your dish is ready to serve.")
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(.secondary)
                }
                Button(action: onFinish) {
                    Label("Finish Cooking", systemImage: "checkmark")
                        .font(.system(.callout, design: .serif).weight(.semibold))
                        .frame(minWidth: 200)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .padding(.top, 8)
            }
        }
    }
}
