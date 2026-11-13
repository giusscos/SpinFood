import SwiftUI
import UIKit

// Foo follows the accessibility settings people already chose in iOS: VoiceOver, Larger Text,
// Increase Contrast, Reduce Motion and Differentiate Without Color. These helpers keep that
// consistent across the app.

// MARK: - Larger Text

/// A system font drawn at a design size that still grows with the reader's text size.
/// `.system(size:)` alone stays fixed, so small labels like "TONIGHT" or "STEP" never got bigger.
private struct ScaledSystemFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    let width: Font.Width?

    init(size: CGFloat, weight: Font.Weight, design: Font.Design, width: Font.Width?, relativeTo style: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.weight = weight
        self.design = design
        self.width = width
    }

    func body(content: Content) -> some View {
        let font = Font.system(size: size, weight: weight, design: design)
        return content.font(width.map { font.width($0) } ?? font)
    }
}

extension View {
    func scaledFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        width: Font.Width? = nil,
        relativeTo style: Font.TextStyle = .body
    ) -> some View {
        modifier(ScaledSystemFont(size: size, weight: weight, design: design, width: width, relativeTo: style))
    }
}

// MARK: - Increase Contrast

/// Cards, chips and tiles here are drawn with faint fills that almost vanish on the paper colour.
/// With Increase Contrast on, they also get a clear outline.
private struct ContrastOutline<S: InsettableShape>: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast
    let shape: S

    func body(content: Content) -> some View {
        content.overlay {
            if contrast == .increased {
                shape.strokeBorder(Color.primary.opacity(0.55), lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
    }
}

extension View {
    func contrastOutline(cornerRadius: CGFloat) -> some View {
        modifier(ContrastOutline(shape: RoundedRectangle(cornerRadius: cornerRadius)))
    }

    func contrastOutlineCapsule() -> some View {
        modifier(ContrastOutline(shape: Capsule()))
    }
}

// MARK: - Reduce Motion

/// `withAnimation` that changes state without the movement when Reduce Motion is on.
@discardableResult
func withMotion<Result>(_ animation: Animation? = .default, _ body: () throws -> Result) rethrows -> Result {
    try withAnimation(UIAccessibility.isReduceMotionEnabled ? nil : animation, body)
}

// MARK: - VoiceOver wording

extension TimeInterval {
    /// "1 hour, 30 minutes". The on-screen "1h 30m" is read out letter by letter.
    var spokenDuration: String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = self >= 3600 ? [.hour, .minute] : [.minute, .second]
        formatter.zeroFormattingBehavior = .dropAll
        return formatter.string(from: self) ?? ""
    }
}

enum SpokenText {
    /// "4 of 5 stars", for a row of ★ characters.
    static func rating(_ stars: Int) -> String {
        String(localized: "\(stars) of 5 stars")
    }

    /// "2 servings", with the plural each language needs.
    static func servings(_ count: Int) -> String {
        String(AttributedString(localized: "^[\(count) serving](inflect: true)").characters)
    }

    /// "Expires today", "Expires in 3 days", or "Expired".
    static func expiry(daysLeft days: Int) -> String {
        if days < 0 { return String(localized: "Expired") }
        if days == 0 { return String(localized: "Expires today") }
        return String(AttributedString(localized: "Expires in ^[\(days) day](inflect: true)").characters)
    }
}

// MARK: - Page turns

extension UIAccessibility {
    /// After a page turn, move VoiceOver to the new page instead of leaving it on one that's gone.
    static func announcePageChange() {
        guard isVoiceOverRunning else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            post(notification: .screenChanged, argument: nil)
        }
    }
}
