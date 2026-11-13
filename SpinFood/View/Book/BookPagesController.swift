import SwiftUI
import UIKit

// MARK: - Page turn style

/// How the recipe book and the steps book move from page to page.
enum PageTurnStyle: String, CaseIterable, Identifiable {
    /// Pages fold over like paper.
    case curl
    /// Pages slide sideways, with no folding.
    case slide
    /// Each page opens from the index, and closes back to it. No swiping from page to page.
    case single

    /// Empty until the person picks a style; Foo asks once, at the first start after onboarding.
    static let storageKey = "page_turn_style"

    var id: String { rawValue }

    /// The saved choice. Before there is one, Slide when Reduce Motion is on, otherwise the book.
    static func resolved(stored: String, reduceMotion: Bool) -> PageTurnStyle {
        PageTurnStyle(rawValue: stored) ?? (reduceMotion ? .slide : .curl)
    }

    var title: LocalizedStringKey {
        switch self {
        case .curl: "Book"
        case .slide: "Slide"
        case .single: "One at a Time"
        }
    }

    var summary: LocalizedStringKey {
        switch self {
        case .curl: "Pages fold over like a real cookbook."
        case .slide: "Pages slide across, with less motion."
        case .single: "Open each page from the index, without swiping between pages."
        }
    }

    var systemImage: String {
        switch self {
        case .curl: "book.pages"
        case .slide: "arrow.left.arrow.right.square"
        case .single: "list.bullet.rectangle.portrait"
        }
    }
}

// MARK: - Page controller

/// The page controller behind the recipe book and the steps book.
///
/// - Folds or slides, fixed when it's created: UIPageViewController can't change its transition later.
/// - Pages turn by swiping only. In fold mode UIKit also turns the page on a tap near either edge, and that
///   tap swallowed the buttons sitting there ("Index", "Done", "+", "Steps"), so people couldn't get back.
/// - Jumps never overlap. Starting a jump, or swapping the pages, while another jump is animating left
///   UIPageViewController showing one page while it believed it was on another. They now wait their turn.
class BookPagesController: UIPageViewController {
    let turnStyle: PageTurnStyle

    /// Whether a swipe moves to the next or previous page. "One at a Time" turns this off.
    var allowsSwiping: Bool { turnStyle != .single }

    /// "One at a Time" has no swiping between pages; a swipe to the right goes back to the index instead.
    var onEdgeBack: (() -> Void)?

    private let backSwipeDelegate = BackSwipeDelegate()

    private(set) var isJumping = false
    private var jumpID = 0
    private var pendingJump: (() -> Void)?

    init(turnStyle: PageTurnStyle, spineLocation: SpineLocation = .min) {
        self.turnStyle = turnStyle
        switch turnStyle {
        case .curl:
            super.init(
                transitionStyle: .pageCurl,
                navigationOrientation: .horizontal,
                options: [.spineLocation: spineLocation.rawValue]
            )
        case .slide, .single:
            super.init(
                transitionStyle: .scroll,
                navigationOrientation: .horizontal,
                options: [.interPageSpacing: 0]
            )
        }
        for recognizer in gestureRecognizers where recognizer is UITapGestureRecognizer {
            recognizer.isEnabled = false
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        guard turnStyle == .single else { return }
        let back = UIPanGestureRecognizer(target: self, action: #selector(backSwiped(_:)))
        backSwipeDelegate.controller = self
        back.delegate = backSwipeDelegate
        view.addGestureRecognizer(back)
        updateScrolling()
    }

    // UIPageViewController adds its scroll view after viewDidLoad, so this is checked again on layout.
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if turnStyle == .single { updateScrolling() }
    }

    /// In "One at a Time" the pages don't scroll sideways at all, so nothing bounces or half-turns,
    /// and a back swipe isn't undone by the page snapping back into place.
    func updateScrolling() {
        for case let scrollView as UIScrollView in view.subviews {
            scrollView.isScrollEnabled = allowsSwiping
        }
    }

    /// A swipe to the right goes back to the index.
    @objc private func backSwiped(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .ended, !allowsSwiping else { return }
        let translation = gesture.translation(in: view).x
        let velocity = gesture.velocity(in: view).x
        if translation > 80 || velocity > 600 {
            onEdgeBack?()
        }
    }

    /// Shows `controllers` without animation, now or right after the jump in progress.
    func display(_ controllers: [UIViewController]) {
        guard !isJumping else {
            pendingJump = { [weak self] in self?.display(controllers) }
            return
        }
        setViewControllers(controllers, direction: .forward, animated: false)
    }

    /// Turns to `controllers`: a fold, a slide, or a fade when sliding with Reduce Motion on.
    func jump(to controllers: [UIViewController], direction: NavigationDirection) {
        guard !isJumping else {
            pendingJump = { [weak self] in self?.jump(to: controllers, direction: direction) }
            return
        }
        UIAccessibility.announcePageChange()
        guard view.window != nil else {
            setViewControllers(controllers, direction: direction, animated: false)
            return
        }
        if turnStyle != .curl && UIAccessibility.isReduceMotionEnabled {
            UIView.transition(with: view, duration: 0.2, options: .transitionCrossDissolve) {
                self.setViewControllers(controllers, direction: direction, animated: false)
            }
            return
        }

        isJumping = true
        jumpID += 1
        let id = jumpID
        setViewControllers(controllers, direction: direction, animated: true) { [weak self] _ in
            guard let self else { return }
            guard turnStyle != .curl else {
                finishJump(id)
                return
            }
            // A slide keeps the neighbours of the page it started from, so the next swipe could land
            // on the wrong page. Setting the same page again without animation refreshes them.
            DispatchQueue.main.async {
                guard self.jumpID == id, self.isJumping else { return }
                self.setViewControllers(controllers, direction: direction, animated: false)
                self.finishJump(id)
            }
        }
        // If UIKit never reports the end of the animation, don't block every later jump.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.finishJump(id)
        }
    }

    private func finishJump(_ id: Int) {
        guard isJumping, id == jumpID else { return }
        isJumping = false
        let next = pendingJump
        pendingJump = nil
        next?()
    }
}

/// Kept apart from the page controller, which UIKit may use as the delegate of its own page-turn gestures.
private final class BackSwipeDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var controller: BookPagesController?

    /// The back swipe only starts on a mostly sideways, rightward drag, so vertical scrolling is untouched.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let controller, !controller.allowsSwiping,
              let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let velocity = pan.velocity(in: controller.view)
        return velocity.x > 0 && velocity.x > abs(velocity.y) * 1.5
    }

    /// The page's own vertical scrolling would otherwise claim the drag first.
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }
}

// MARK: - Sliding spread

/// Two facing pages side by side, for a two-page book that slides instead of folding.
/// (A folding book lays out its own spread; a sliding one shows one controller at a time.)
final class SpreadPairController: UIViewController {
    let left: UIViewController
    let right: UIViewController

    init(left: UIViewController, right: UIViewController, background: UIColor) {
        self.left = left
        self.right = right
        super.init(nibName: nil, bundle: nil)
        view.backgroundColor = background
        for child in [left, right] {
            // The index page is reused when the book is rebuilt, so it may still sit in an old pair.
            if child.parent != nil {
                child.willMove(toParent: nil)
                child.view.removeFromSuperview()
                child.removeFromParent()
            }
            addChild(child)
            view.addSubview(child.view)
            child.didMove(toParent: self)
        }
        let spine = UIView()
        spine.backgroundColor = UIColor.separator.withAlphaComponent(0.25)
        spine.tag = Self.spineTag
        view.addSubview(spine)
    }

    required init?(coder: NSCoder) { fatalError() }

    private static let spineTag = 0x5B1E

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let bounds = view.bounds
        let half = (bounds.width / 2).rounded(.down)
        left.view.frame = CGRect(x: 0, y: 0, width: half, height: bounds.height)
        right.view.frame = CGRect(x: half, y: 0, width: bounds.width - half, height: bounds.height)
        view.viewWithTag(Self.spineTag)?.frame = CGRect(x: half - 0.5, y: 0, width: 1, height: bounds.height)
    }
}
