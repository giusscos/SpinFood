import SwiftUI
import UIKit

/// Keeps a sideways drag that starts on a picker or sideways list from also turning the book's page
/// or swiping the sheet closed. Up-and-down drags are left alone, so the page still scrolls.
///
/// It's a pan recogniser that runs alongside the control's own gestures. Page turns, the book's
/// sliding scroll view and sheet dismissal sit above the control, and they're made to wait for this
/// one to fail. As soon as the finger moves, it succeeds, so they never start.
private struct DragShield: UIGestureRecognizerRepresentable {
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.cancelsTouchesInView = false
        pan.delaysTouchesBegan = false
        pan.delaysTouchesEnded = false
        pan.delegate = context.coordinator
        return pan
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        /// Only sideways drags: those are what turn pages. Up-and-down drags keep scrolling the page.
        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return true }
            let velocity = pan.velocity(in: pan.view)
            return abs(velocity.x) >= abs(velocity.y)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            // Only gestures on views above this one (page turns, sheet swipes) wait;
            // the control's own scrolling inside it carries on.
            guard otherGestureRecognizer is UIPanGestureRecognizer,
                  let mine = gestureRecognizer.view,
                  let theirs = otherGestureRecognizer.view,
                  mine !== theirs else { return false }
            return mine.isDescendant(of: theirs)
        }
    }
}

extension View {
    /// Dragging this view never turns a page or closes a sheet.
    func blocksPageAndSheetDrags() -> some View {
        gesture(DragShield())
    }
}
