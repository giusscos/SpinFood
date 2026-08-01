import WidgetKit
import SwiftUI

@main
struct SpinFoodWidgetBundle: WidgetBundle {
    var body: some Widget {
        SpinFoodWidget()
        CookableRecipeWidget()
        CookTimerLiveActivity()
    }
}
