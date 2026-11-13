import SwiftUI
import StoreKit

/// When Foo asks for a rating. Ratings are what lift an app in App Store search, and Foo had almost none,
/// so it asks at a few moments when something just went well, each one once, and never two days in a row.
/// iOS still decides whether the prompt appears (at most three times a year).
enum ReviewMoment: String {
    case firstMeal = "first_meal"
    case fifthMeal = "fifth_meal"
    /// The third recipe someone wrote themselves: they've invested in the book.
    case thirdRecipe = "third_recipe"
    /// The first food used up before it expired: the thing Foo promises.
    case firstSavedFood = "first_saved_food"

    private static let lastAskedKey = "review_last_asked_at"
    private static let minimumGap: TimeInterval = 2 * 86_400

    private var askedKey: String { "review_asked_\(rawValue)" }

    /// For moments an earlier version already asked about.
    func markAsked() {
        UserDefaults.standard.set(true, forKey: askedKey)
    }

    /// Asks once for this moment, unless another moment asked in the last two days.
    /// The prompt waits a second, so it isn't lost while a sheet or screen is closing.
    @MainActor
    func askIfDue(_ requestReview: RequestReviewAction) {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: askedKey) else { return }
        let lastAsked = defaults.double(forKey: Self.lastAskedKey)
        guard lastAsked == 0 || Date.now.timeIntervalSince1970 - lastAsked > Self.minimumGap else { return }

        defaults.set(true, forKey: askedKey)
        defaults.set(Date.now.timeIntervalSince1970, forKey: Self.lastAskedKey)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            requestReview()
        }
    }
}
