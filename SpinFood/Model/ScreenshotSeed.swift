#if DEBUG && targetEnvironment(simulator)
import SwiftData
import UIKit

/// A screen to open straight away, so captures can be scripted: launch with `-ScreenshotScene ideas`.
enum ScreenshotScene: String {
    case ideas, quickAdd, inventory, reminders, book, spread, waste

    static var current: ScreenshotScene? {
        UserDefaults.standard.string(forKey: "ScreenshotScene").flatMap(ScreenshotScene.init(rawValue:))
    }

    static let quickAddPicks = ["tomatoes", "carrots", "bell_peppers", "spinach", "mushrooms", "apples"]

    /// Sample food shown on the reminders page.
    static var reminderPicks: [GroceryPick] {
        ["spinach", "milk"].compactMap { GroceryCatalog.item(id: $0) }.map(GroceryPick.init(item:))
    }
}

/// App Store screenshot helpers. Debug simulator builds only; compiled out of every device and Release build.
///
/// ```
/// xcrun simctl spawn booted defaults write giusscos.SpinFood SimulatorPremium -bool YES
/// xcrun simctl spawn booted defaults write giusscos.SpinFood SeedScreenshotLibrary -bool YES
/// ```
/// These flags live on the simulator, so they survive uninstalling and every clean install seeds again until
/// `xcrun simctl spawn booted defaults delete giusscos.SpinFood` clears them.
/// The launch that seeds shows system blue instead of the accent color and can ignore taps on recipes,
/// so relaunch the app before capturing.
/// Recipe photos are read from the app's Documents/ScreenshotSeed folder (e.g. `salmon.jpg`, `scanner.jpg`);
/// pasta, pizza, salad and soup fall back to the bundled onboarding illustrations.
enum ScreenshotSeed {
    static var simulatorPremium: Bool {
        UserDefaults.standard.bool(forKey: "SimulatorPremium")
    }

    /// The scanner's viewfinder shows this still photo, since the simulator has no camera.
    static var scannerFeedImage: UIImage? {
        photo(named: "scanner")
    }

    /// What the still scanner feed "scans": an unbranded product, so no third-party packaging shows up in screenshots.
    static let feedBarcode = "8012345678901"

    static func scannedProduct(for barcode: String) -> OpenFoodFactsProduct? {
        guard barcode == feedBarcode, let url = photoURL(named: "scanner") else { return nil }
        return OpenFoodFactsProduct(barcode: barcode, name: "Fusilli", brand: nil,
                                    quantityText: "500 g", parsedQuantity: 500, imageURL: url,
                                    category: .grains, unit: .gram, emoji: "🍝")
    }

    private static func photoURL(named name: String) -> URL? {
        let folder = URL.documentsDirectory.appending(path: "ScreenshotSeed")
        return ["jpg", "jpeg", "png"]
            .map { folder.appending(path: "\(name).\($0)") }
            .first { FileManager.default.fileExists(atPath: $0.path) }
    }

    private static func photo(named name: String) -> UIImage? {
        photoURL(named: name).flatMap { UIImage(contentsOfFile: $0.path) }
    }

    private static func photoData(_ name: String) -> Data? {
        let bundled = [
            "pasta": "OnboardingDishPasta",
            "pizza": "OnboardingDishPizza",
            "salad": "OnboardingDishSalad",
            "soup": "OnboardingDishSoup",
        ]
        let image = photo(named: name) ?? bundled[name].flatMap { UIImage(named: $0) }
        return image?.jpegData(compressionQuality: 0.85)
    }

    /// Sample names in the app's language, so captures aren't half English: [en: (it, de, es, fr)].
    private static let names: [String: (String, String, String, String)] = [
        "Spaghetti": ("Spaghetti", "Spaghetti", "Espaguetis", "Spaghettis"),
        "A slow-rise dough, bright tomato and melting mozzarella, baked as hot as your oven goes.": (
            "Un impasto a lenta lievitazione, pomodoro vivace e mozzarella filante, cotto alla massima temperatura del forno.",
            "Ein langsam gereifter Teig, fruchtige Tomaten und schmelzender Mozzarella, so heiß gebacken, wie dein Ofen kann.",
            "Una masa de fermentación lenta, tomate intenso y mozzarella fundida, horneada a la máxima temperatura de tu horno.",
            "Une pâte à levée lente, une tomate éclatante et de la mozzarella fondante, cuites aussi chaud que ton four le permet."
        ),
        "Crisp leaves, cucumber, avocado and tomatoes with a sharp lemon dressing.": (
            "Foglie croccanti, cetriolo, avocado e pomodori con un vivace condimento al limone.",
            "Knackige Blätter, Gurke, Avocado und Tomaten mit einem frischen Zitronendressing.",
            "Hojas crujientes, pepino, aguacate y tomates con un aliño intenso de limón.",
            "Des feuilles croquantes, du concombre, de l'avocat et des tomates avec une vinaigrette vive au citron."
        ),
        "Sweet cherry tomatoes cooked down with garlic and olive oil, tossed with spaghetti and finished with fresh basil.": (
            "Pomodorini dolci cotti con aglio e olio d'oliva, saltati con gli spaghetti e completati con basilico fresco.",
            "Süße Kirschtomaten, mit Knoblauch und Olivenöl eingekocht, mit Spaghetti vermengt und mit frischem Basilikum vollendet.",
            "Tomates cherry dulces cocinados con ajo y aceite de oliva, mezclados con espaguetis y terminados con albahaca fresca.",
            "Des tomates cerises sucrées mijotées avec de l'ail et de l'huile d'olive, mêlées aux spaghettis et relevées de basilic frais."
        ),
        "Cherry Tomatoes": ("Pomodorini", "Kirschtomaten", "Tomates cherry", "Tomates cerises"),
        "Tomato Passata": ("Passata di pomodoro", "Passierte Tomaten", "Tomate triturado", "Coulis de tomate"),
        "Garlic": ("Aglio", "Knoblauch", "Ajo", "Ail"),
        "Olive Oil": ("Olio d'oliva", "Olivenöl", "Aceite de oliva", "Huile d'olive"),
        "Basil": ("Basilico", "Basilikum", "Albahaca", "Basilic"),
        "Parmesan": ("Parmigiano", "Parmesan", "Parmesano", "Parmesan"),
        "Flour": ("Farina", "Mehl", "Harina", "Farine"),
        "Dry Yeast": ("Lievito secco", "Trockenhefe", "Levadura seca", "Levure sèche"),
        "Mozzarella": ("Mozzarella", "Mozzarella", "Mozzarella", "Mozzarella"),
        "Mixed Lettuce": ("Insalata mista", "Gemischter Salat", "Lechuga variada", "Salade mélangée"),
        "Cucumber": ("Cetrioli", "Gurken", "Pepinos", "Concombres"),
        "Avocado": ("Avocado", "Avocados", "Aguacates", "Avocats"),
        "Lemon": ("Limoni", "Zitronen", "Limones", "Citrons"),
        "Onion": ("Cipolle", "Zwiebeln", "Cebollas", "Oignons"),
        "Cooking Cream": ("Panna", "Sahne", "Nata", "Crème"),
        "Bread": ("Pane", "Brot", "Pan", "Pain"),
        "Salmon Fillet": ("Filetto di salmone", "Lachsfilet", "Filete de salmón", "Filet de saumon"),
        "Butter": ("Burro", "Butter", "Mantequilla", "Beurre"),
        "Chicken Breast": ("Petto di pollo", "Hähnchenbrust", "Pechuga de pollo", "Blanc de poulet"),
        "Jasmine Rice": ("Riso jasmine", "Jasminreis", "Arroz jazmín", "Riz jasmin"),
        "Soy Sauce": ("Salsa di soia", "Sojasoße", "Salsa de soja", "Sauce soja"),
        "Bell Pepper": ("Peperoni", "Paprika", "Pimientos", "Poivrons"),
        "Eggs": ("Uova", "Eier", "Huevos", "Œufs"),
        "Milk": ("Latte", "Milch", "Leche", "Lait"),
        "Blueberries": ("Mirtilli", "Heidelbeeren", "Arándanos", "Myrtilles"),
        "Maple Syrup": ("Sciroppo d'acero", "Ahornsirup", "Sirope de arce", "Sirop d'érable"),
        "Greek Yogurt": ("Yogurt greco", "Griechischer Joghurt", "Yogur griego", "Yaourt grec"),
        "Apples": ("Mele", "Äpfel", "Manzanas", "Pommes"),
        "Coffee Beans": ("Caffè in grani", "Kaffeebohnen", "Café en grano", "Café en grains"),
        "Ricotta": ("Ricotta", "Ricotta", "Ricotta", "Ricotta"),
        "Spaghetti al Pomodoro": ("Spaghetti al pomodoro", "Spaghetti al Pomodoro", "Espaguetis con tomate", "Spaghettis à la tomate"),
        "Margherita Pizza": ("Pizza Margherita", "Pizza Margherita", "Pizza Margarita", "Pizza Margherita"),
        "Garden Salad": ("Insalata dell'orto", "Gartensalat", "Ensalada de la huerta", "Salade du jardin"),
        "Roasted Tomato Soup": ("Vellutata di pomodori", "Tomatensuppe", "Crema de tomate", "Velouté de tomates"),
        "Lemon Butter Salmon": ("Salmone al limone", "Zitronenlachs", "Salmón al limón", "Saumon au citron"),
        "Chicken Stir Fry": ("Pollo saltato", "Hähnchenpfanne", "Pollo salteado", "Poulet sauté"),
        "Fluffy Pancakes": ("Pancake soffici", "Fluffige Pancakes", "Tortitas esponjosas", "Pancakes moelleux"),
        "Avocado Toast": ("Toast all'avocado", "Avocado-Toast", "Tostada de aguacate", "Toast à l'avocat"),
    ]

    private static func localized(_ name: String) -> String {
        guard let translations = names[name] else { return name }
        switch AppLanguage.system {
        case "it": return translations.0
        case "de": return translations.1
        case "es": return translations.2
        case "fr": return translations.3
        default: return name
        }
    }

    /// Fills the book, pantry and shopping needs once, then clears the flag.
    @MainActor
    static func seedIfRequested(in context: ModelContext) {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: "SeedScreenshotLibrary") else { return }
        defaults.set(false, forKey: "SeedScreenshotLibrary")
        defaults.set(true, forKey: "onboarding_completed")
        defaults.set(true, forKey: "milestone_paywall_shown")

        let day: TimeInterval = 86_400
        func food(_ name: String, _ emoji: String, _ quantity: Decimal, _ current: Decimal,
                  _ unit: FoodUnit, _ category: FoodCategory, expiresIn days: Double? = nil) -> FoodModel {
            let item = FoodModel(name: localized(name), emoji: emoji, quantity: quantity, currentQuantity: current,
                                 unit: unit, category: category,
                                 expiryDate: days.map { Date.now.addingTimeInterval($0 * day) })
            context.insert(item)
            return item
        }

        // Pantry
        let spaghetti = food("Spaghetti", "🍝", 1000, 850, .gram, .grains)
        let tomatoes = food("Cherry Tomatoes", "🍅", 500, 400, .gram, .produce, expiresIn: 4)
        let passata = food("Tomato Passata", "🥫", 700, 700, .milliliter, .pantry, expiresIn: 120)
        let garlic = food("Garlic", "🧄", 10, 9, .piece, .produce, expiresIn: 20)
        let oliveOil = food("Olive Oil", "🫒", 1000, 850, .milliliter, .pantry)
        let basil = food("Basil", "🌿", 30, 20, .gram, .produce)
        let parmesan = food("Parmesan", "🧀", 300, 180, .gram, .dairy, expiresIn: 25)
        let flour = food("Flour", "🌾", 1000, 900, .gram, .grains)
        let yeast = food("Dry Yeast", "🫙", 50, 45, .gram, .pantry, expiresIn: 90)
        let mozzarella = food("Mozzarella", "🧀", 250, 0, .gram, .dairy)
        let lettuce = food("Mixed Lettuce", "🥬", 300, 250, .gram, .produce, expiresIn: 2)
        let cucumber = food("Cucumber", "🥒", 3, 3, .piece, .produce, expiresIn: 5)
        let avocado = food("Avocado", "🥑", 4, 4, .piece, .produce, expiresIn: 3)
        let lemon = food("Lemon", "🍋", 6, 5, .piece, .produce, expiresIn: 12)
        let onion = food("Onion", "🧅", 6, 5, .piece, .produce, expiresIn: 30)
        let cream = food("Cooking Cream", "🥛", 200, 200, .milliliter, .dairy, expiresIn: 6)
        let bread = food("Bread", "🍞", 500, 400, .gram, .grains, expiresIn: 2)
        let salmon = food("Salmon Fillet", "🐟", 400, 0, .gram, .seafood)
        let butter = food("Butter", "🧈", 250, 200, .gram, .dairy, expiresIn: 30)
        let chicken = food("Chicken Breast", "🍗", 600, 500, .gram, .meat, expiresIn: 3)
        let rice = food("Jasmine Rice", "🍚", 1000, 800, .gram, .grains)
        let soySauce = food("Soy Sauce", "🫙", 250, 200, .milliliter, .pantry)
        let pepper = food("Bell Pepper", "🫑", 4, 1, .piece, .produce, expiresIn: 6)
        let eggs = food("Eggs", "🥚", 12, 10, .piece, .dairy, expiresIn: 14)
        let milk = food("Milk", "🥛", 1, 1, .liter, .dairy, expiresIn: 5)
        let blueberries = food("Blueberries", "🫐", 250, 0, .gram, .produce)
        let maple = food("Maple Syrup", "🍁", 250, 200, .milliliter, .pantry)
        _ = food("Greek Yogurt", "🥣", 500, 450, .gram, .dairy, expiresIn: 8)
        _ = food("Apples", "🍎", 6, 5, .piece, .produce, expiresIn: 15)
        _ = food("Coffee Beans", "☕️", 500, 90, .gram, .beverages)
        let ricotta = food("Ricotta", "🧀", 250, 200, .gram, .dairy, expiresIn: -1)

        let wasted: [(FoodModel, Decimal, Double)] = [
            (lettuce, 150, 2), (bread, 100, 5), (ricotta, 50, 9), (lettuce, 120, 16), (cream, 100, 24),
            (lettuce, 200, 34), (bread, 100, 38), (salmon, 200, 45), (cream, 150, 52),
        ]
        for (item, quantity, daysAgo) in wasted {
            context.insert(FoodWasteModel(wastedAt: Date.now.addingTimeInterval(-daysAgo * day), quantity: quantity, food: item))
        }

        for (index, item) in [spaghetti, tomatoes, cream, bread, lettuce].enumerated() {
            context.insert(FoodConsumptionModel(
                consumedAt: Date.now.addingTimeInterval(-Double(index) * day),
                quantity: 100,
                unit: item.unit,
                food: item,
                rescued: true
            ))
        }

        func text(_ order: Int, _ content: String) -> StepBlock {
            StepBlock(type: .text, order: order, textContent: content)
        }
        func timer(_ order: Int, minutes: Double, _ label: String) -> StepBlock {
            StepBlock(type: .timer, order: order, timerDuration: minutes * 60, timerLabel: label)
        }
        func list(_ order: Int, _ items: [String]) -> StepBlock {
            StepBlock(type: .bulletList, order: order, listItems: items)
        }
        func step(_ order: Int, _ title: String, _ blocks: [StepBlock]) -> StepRecipe {
            let step = StepRecipe(text: title)
            step.order = order
            step.blocks = blocks
            return step
        }

        struct Seed {
            let name: String
            let photo: String
            let description: String
            let minutes: Double
            let servings: Int
            let difficulty: RecipeDifficulty
            let tags: [RecipeTag]
            let rating: Int
            let timesCooked: Int
            let ingredients: [(FoodModel, Decimal)]
            let steps: [StepRecipe]
        }

        let seeds: [Seed] = [
            Seed(name: "Spaghetti al Pomodoro", photo: "pasta",
                 description: "Sweet cherry tomatoes cooked down with garlic and olive oil, tossed with spaghetti and finished with fresh basil.",
                 minutes: 25, servings: 2, difficulty: .easy, tags: [.vegetarian, .quick], rating: 5, timesCooked: 6,
                 ingredients: [(spaghetti, 200), (tomatoes, 300), (garlic, 2), (oliveOil, 30), (basil, 10), (parmesan, 40)],
                 steps: [
                    step(0, "Boil the water", [text(0, "Bring a large pot of water to a boil and salt it generously."), timer(1, minutes: 10, "Water to a boil")]),
                    step(1, "Make the sauce", [text(0, "Warm the olive oil with the sliced garlic over low heat. Add the halved tomatoes, a pinch of salt, and let them burst and soften."), timer(1, minutes: 12, "Simmer the tomatoes"), list(2, ["Press the tomatoes with a spoon as they soften", "Keep the heat low so the garlic stays golden"])]),
                    step(2, "Cook the pasta", [text(0, "Cook the spaghetti until 1 minute short of al dente. Save a cup of the cooking water."), timer(1, minutes: 9, "Spaghetti")]),
                    step(3, "Toss and serve", [text(0, "Toss the pasta in the sauce with a splash of cooking water until glossy. Tear in the basil and finish with parmesan.")]),
                 ]),
            Seed(name: "Margherita Pizza", photo: "pizza",
                 description: "A slow-rise dough, bright tomato and melting mozzarella, baked as hot as your oven goes.",
                 minutes: 90, servings: 4, difficulty: .easy, tags: [.vegetarian], rating: 5, timesCooked: 3,
                 ingredients: [(flour, 500), (yeast, 7), (passata, 250), (mozzarella, 250), (basil, 8), (oliveOil, 20)],
                 steps: [
                    step(0, "Make the dough", [text(0, "Mix the flour, yeast, a teaspoon of salt and 320 ml of warm water. Knead for 10 minutes until smooth."), timer(1, minutes: 10, "Knead")]),
                    step(1, "Let it rise", [text(0, "Cover and leave somewhere warm until doubled."), timer(1, minutes: 60, "Rise")]),
                    step(2, "Top and bake", [text(0, "Stretch the dough, spread the passata, add torn mozzarella and bake at the highest temperature."), timer(1, minutes: 12, "Bake")]),
                 ]),
            Seed(name: "Garden Salad", photo: "salad",
                 description: "Crisp leaves, cucumber, avocado and tomatoes with a sharp lemon dressing.",
                 minutes: 10, servings: 2, difficulty: .easy, tags: [.vegan, .healthy, .quick], rating: 4, timesCooked: 9,
                 ingredients: [(lettuce, 150), (cucumber, 1), (avocado, 1), (tomatoes, 120), (lemon, 1), (oliveOil, 20)],
                 steps: [
                    step(0, "Prep the vegetables", [text(0, "Wash and dry the lettuce. Slice the cucumber and avocado, halve the tomatoes.")]),
                    step(1, "Dress and toss", [text(0, "Whisk the lemon juice with olive oil and a pinch of salt. Toss everything just before serving.")]),
                 ]),
            Seed(name: "Roasted Tomato Soup", photo: "soup",
                 description: "Tomatoes and onion roasted until sweet, blended smooth with a swirl of cream.",
                 minutes: 45, servings: 4, difficulty: .easy, tags: [.vegetarian], rating: 5, timesCooked: 4,
                 ingredients: [(tomatoes, 350), (passata, 300), (onion, 1), (garlic, 3), (cream, 50), (oliveOil, 30), (bread, 100)],
                 steps: [
                    step(0, "Roast", [text(0, "Toss the tomatoes, onion and garlic with olive oil and roast at 200 °C until blistered."), timer(1, minutes: 25, "Roast vegetables")]),
                    step(1, "Simmer", [text(0, "Tip everything into a pot with the passata and simmer to bring the flavors together."), timer(1, minutes: 10, "Simmer soup")]),
                    step(2, "Blend and serve", [text(0, "Blend until smooth, season, and finish with a swirl of cream. Serve with toasted sourdough.")]),
                 ]),
            Seed(name: "Lemon Butter Salmon", photo: "salmon",
                 description: "Crispy-skinned salmon basted in garlic butter with plenty of lemon.",
                 minutes: 20, servings: 2, difficulty: .medium, tags: [.glutenFree, .healthy], rating: 5, timesCooked: 2,
                 ingredients: [(salmon, 300), (butter, 30), (garlic, 2), (lemon, 1)],
                 steps: [
                    step(0, "Sear", [text(0, "Pat the salmon dry, season, and sear skin-side down without moving it."), timer(1, minutes: 4, "Sear skin side")]),
                    step(1, "Baste", [text(0, "Flip, add butter and garlic, and spoon the foaming butter over the fish."), timer(1, minutes: 3, "Baste")]),
                 ]),
            Seed(name: "Chicken Stir Fry", photo: "stirfry",
                 description: "Tender chicken and crunchy peppers in a quick soy-garlic glaze over jasmine rice.",
                 minutes: 30, servings: 3, difficulty: .easy, tags: [.dairyFree, .quick], rating: 4, timesCooked: 5,
                 ingredients: [(chicken, 300), (rice, 200), (soySauce, 40), (garlic, 2), (pepper, 2), (oliveOil, 20)],
                 steps: [
                    step(0, "Cook the rice", [text(0, "Rinse the rice and simmer, covered, with 1.5 times its volume of water."), timer(1, minutes: 15, "Rice")]),
                    step(1, "Stir fry", [text(0, "Cook the chicken over high heat until golden, then add the peppers and garlic."), timer(1, minutes: 6, "Stir fry")]),
                 ]),
            Seed(name: "Fluffy Pancakes", photo: "pancakes",
                 description: "Thick, soft pancakes with blueberries and a drizzle of maple syrup.",
                 minutes: 20, servings: 2, difficulty: .easy, tags: [.vegetarian], rating: 5, timesCooked: 7,
                 ingredients: [(flour, 150), (eggs, 2), (milk, 0.25), (butter, 20), (blueberries, 80), (maple, 30)],
                 steps: [
                    step(0, "Mix the batter", [text(0, "Whisk the flour, eggs and milk into a thick batter. Fold in the melted butter.")]),
                    step(1, "Cook", [text(0, "Cook ladlefuls on a buttered pan until bubbles form, then flip."), timer(1, minutes: 3, "Each batch")]),
                 ]),
            Seed(name: "Avocado Toast", photo: "toast",
                 description: "Sourdough, smashed avocado, lemon and a soft-boiled egg.",
                 minutes: 10, servings: 2, difficulty: .easy, tags: [.vegetarian, .quick], rating: 4, timesCooked: 11,
                 ingredients: [(bread, 100), (avocado, 1), (lemon, 1), (eggs, 2)],
                 steps: [
                    step(0, "Boil the egg", [text(0, "Lower the egg into boiling water."), timer(1, minutes: 6, "Soft-boiled egg")]),
                    step(1, "Assemble", [text(0, "Toast the bread, smash the avocado with lemon and salt, and top with the halved egg.")]),
                 ]),
        ]

        for (index, seed) in seeds.enumerated() {
            let recipe = RecipeModel(
                name: localized(seed.name),
                descriptionRecipe: localized(seed.description),
                image: photoData(seed.photo),
                duration: seed.minutes * 60,
                servings: seed.servings,
                difficulty: seed.difficulty,
                tags: seed.tags
            )
            recipe.order = index
            recipe.rating = seed.rating
            recipe.cookedAt = (0..<seed.timesCooked).map { Date.now.addingTimeInterval(-Double($0 * 4 + 1) * day) }
            recipe.createdAt = Date.now.addingTimeInterval(-Double(60 - index * 5) * day)
            context.insert(recipe)
            recipe.ingredients = seed.ingredients.map { RecipeFoodModel(ingredient: $0.0, quantityNeeded: $0.1) }
            recipe.steps = seed.steps
        }
        try? context.save()
    }
}
#endif
