import TipKit

struct AddFirstIngredientTip: Tip {
    @Parameter
    static var hasIngredients: Bool = false

    var title: Text {
        Text("Add your first ingredient")
    }

    var message: Text? {
        Text("Tap + to stock your pantry. Ingredients can be added to any recipe.")
    }

    var image: Image? {
        Image(systemName: "carrot.fill")
    }

    var rules: [Rule] {
        #Rule(Self.$hasIngredients) { !$0 }
    }
}

struct AddFirstRecipeTip: Tip {
    @Parameter
    static var hasRecipes: Bool = false

    var title: Text {
        Text("Create your first recipe")
    }

    var message: Text? {
        Text("Tap + to write your first recipe and start building your cookbook.")
    }

    var image: Image? {
        Image(systemName: "fork.knife")
    }

    var rules: [Rule] {
        #Rule(Self.$hasRecipes) { !$0 }
    }
}
