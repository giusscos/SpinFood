import Foundation
import SwiftData

enum AppLanguage {
    static let supported = ["en", "it", "de", "es", "fr"]
    static let storageKey = "selectedLanguage"

    /// The device's language if Foo is translated into it, otherwise English.
    static var system: String {
        let code = String((Bundle.main.preferredLocalizations.first ?? "en").prefix(2))
        return supported.contains(code) ? code : "en"
    }

    /// What someone picked in Settings, or the device's language until they do.
    static var current: String {
        UserDefaults.standard.string(forKey: storageKey) ?? system
    }

    /// Call before any `@AppStorage(storageKey)` is read, so its "en" fallback never wins over the device.
    static func registerDefault() {
        UserDefaults.standard.register(defaults: [storageKey: system])
    }
}

/// A common grocery people can add with one tap. Names ship in every app language,
/// so adding food works offline and needs no typing.
struct GroceryItem: Identifiable, Hashable {
    let id: String
    let emoji: String
    let category: FoodCategory
    let unit: FoodUnit
    /// What one tap adds: a typical pack.
    let packQuantity: Decimal
    /// Typical days before it spoils. `nil` for food that keeps for months, which gets no expiry date.
    let shelfLifeDays: Int?
    let names: [String: String]

    init(
        _ id: String, _ emoji: String, _ category: FoodCategory, _ unit: FoodUnit,
        _ packQuantity: Decimal, _ shelfLifeDays: Int?,
        en: String, it: String, de: String, es: String, fr: String
    ) {
        self.id = id
        self.emoji = emoji
        self.category = category
        self.unit = unit
        self.packQuantity = packQuantity
        self.shelfLifeDays = shelfLifeDays
        self.names = ["en": en, "it": it, "de": de, "es": es, "fr": fr]
    }

    var name: String { names[AppLanguage.current] ?? names["en"] ?? id }

    var suggestedExpiry: Date? {
        shelfLifeDays.flatMap { Calendar.current.date(byAdding: .day, value: $0, to: .now) }
    }

    func matches(search query: String) -> Bool {
        names.values.contains { $0.localizedStandardContains(query) }
    }

    /// The pantry entry for this grocery, in any language. Prefers the one with the most stock.
    func pantryFood(in foods: [FoodModel]) -> FoodModel? {
        let keys = Set(names.values.map(GroceryCatalog.matchKey))
        return foods
            .filter { keys.contains(GroceryCatalog.matchKey($0.name)) }
            .max { $0.currentQuantity < $1.currentQuantity }
    }

    /// A new pantry entry for this grocery. Not inserted, so nothing is saved if the person backs out.
    func makeFood(quantity: Decimal, currentQuantity: Decimal, expiryDate: Date?) -> FoodModel {
        FoodModel(
            name: name,
            emoji: emoji,
            quantity: quantity,
            currentQuantity: currentQuantity,
            unit: unit,
            category: category,
            expiryDate: expiryDate
        )
    }
}

enum GroceryCatalog {
    static func item(id: String) -> GroceryItem? { byID[id] }

    /// The grocery a typed name refers to, if any: "tomato", "Tomatoes" and "Pomodori" all find the same item.
    static func item(matching name: String) -> GroceryItem? {
        byKey[matchKey(name)]
    }

    /// Case, accent and plural-insensitive form of a food name.
    static func matchKey(_ name: String) -> String {
        var key = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        if key.count > 4, key.hasSuffix("es") {
            key.removeLast(2)
        } else if key.count > 3, key.hasSuffix("s") {
            key.removeLast()
        }
        if key.count > 3, let last = key.last, "aeiou".contains(last) {
            key.removeLast()
        }
        return key
    }

    /// Stocks the most common groceries first when someone sets up their kitchen.
    static let essentials: [GroceryItem] = [
        "eggs", "milk", "butter", "cheese", "yogurt", "bread",
        "pasta", "rice", "tomatoes", "onions", "garlic", "potatoes",
        "carrots", "bell_peppers", "spinach", "zucchini", "lemons", "bananas",
        "apples", "chicken_breast", "ground_beef", "canned_tomatoes", "olive_oil", "flour",
    ].compactMap { byID[$0] }

    private static let byID = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    private static let byKey: [String: GroceryItem] = {
        var index: [String: GroceryItem] = [:]
        for item in all {
            for name in item.names.values {
                let key = matchKey(name)
                if index[key] == nil { index[key] = item }
            }
        }
        return index
    }()

    static let all: [GroceryItem] = [
        // MARK: Produce
        GroceryItem("tomatoes", "🍅", .produce, .piece, 6, 7, en: "Tomatoes", it: "Pomodori", de: "Tomaten", es: "Tomates", fr: "Tomates"),
        GroceryItem("onions", "🧅", .produce, .piece, 3, 30, en: "Onions", it: "Cipolle", de: "Zwiebeln", es: "Cebollas", fr: "Oignons"),
        GroceryItem("garlic", "🧄", .produce, .piece, 10, 60, en: "Garlic cloves", it: "Spicchi d'aglio", de: "Knoblauchzehen", es: "Dientes de ajo", fr: "Gousses d'ail"),
        GroceryItem("potatoes", "🥔", .produce, .gram, 1000, 30, en: "Potatoes", it: "Patate", de: "Kartoffeln", es: "Patatas", fr: "Pommes de terre"),
        GroceryItem("sweet_potatoes", "🍠", .produce, .gram, 1000, 30, en: "Sweet potatoes", it: "Patate dolci", de: "Süßkartoffeln", es: "Boniatos", fr: "Patates douces"),
        GroceryItem("carrots", "🥕", .produce, .piece, 6, 21, en: "Carrots", it: "Carote", de: "Karotten", es: "Zanahorias", fr: "Carottes"),
        GroceryItem("bell_peppers", "🫑", .produce, .piece, 3, 10, en: "Bell peppers", it: "Peperoni", de: "Paprika", es: "Pimientos", fr: "Poivrons"),
        GroceryItem("zucchini", "🥒", .produce, .piece, 3, 7, en: "Zucchini", it: "Zucchine", de: "Zucchini", es: "Calabacines", fr: "Courgettes"),
        GroceryItem("cucumber", "🥒", .produce, .piece, 2, 7, en: "Cucumber", it: "Cetrioli", de: "Gurken", es: "Pepinos", fr: "Concombres"),
        GroceryItem("lettuce", "🥬", .produce, .piece, 1, 5, en: "Lettuce", it: "Lattuga", de: "Kopfsalat", es: "Lechuga", fr: "Laitue"),
        GroceryItem("spinach", "🥬", .produce, .gram, 200, 5, en: "Spinach", it: "Spinaci", de: "Spinat", es: "Espinacas", fr: "Épinards"),
        GroceryItem("broccoli", "🥦", .produce, .piece, 1, 7, en: "Broccoli", it: "Broccoli", de: "Brokkoli", es: "Brócoli", fr: "Brocoli"),
        GroceryItem("mushrooms", "🍄", .produce, .gram, 250, 5, en: "Mushrooms", it: "Funghi", de: "Champignons", es: "Champiñones", fr: "Champignons"),
        GroceryItem("eggplant", "🍆", .produce, .piece, 2, 7, en: "Eggplant", it: "Melanzane", de: "Auberginen", es: "Berenjenas", fr: "Aubergines"),
        GroceryItem("celery", "🥬", .produce, .gram, 300, 14, en: "Celery", it: "Sedano", de: "Sellerie", es: "Apio", fr: "Céleri"),
        GroceryItem("avocado", "🥑", .produce, .piece, 2, 4, en: "Avocados", it: "Avocado", de: "Avocados", es: "Aguacates", fr: "Avocats"),
        GroceryItem("lemons", "🍋", .produce, .piece, 4, 21, en: "Lemons", it: "Limoni", de: "Zitronen", es: "Limones", fr: "Citrons"),
        GroceryItem("apples", "🍎", .produce, .piece, 6, 30, en: "Apples", it: "Mele", de: "Äpfel", es: "Manzanas", fr: "Pommes"),
        GroceryItem("bananas", "🍌", .produce, .piece, 6, 5, en: "Bananas", it: "Banane", de: "Bananen", es: "Plátanos", fr: "Bananes"),
        GroceryItem("oranges", "🍊", .produce, .piece, 6, 21, en: "Oranges", it: "Arance", de: "Orangen", es: "Naranjas", fr: "Oranges"),
        GroceryItem("strawberries", "🍓", .produce, .gram, 250, 3, en: "Strawberries", it: "Fragole", de: "Erdbeeren", es: "Fresas", fr: "Fraises"),
        GroceryItem("grapes", "🍇", .produce, .gram, 500, 7, en: "Grapes", it: "Uva", de: "Trauben", es: "Uvas", fr: "Raisin"),
        GroceryItem("blueberries", "🫐", .produce, .gram, 125, 7, en: "Blueberries", it: "Mirtilli", de: "Heidelbeeren", es: "Arándanos", fr: "Myrtilles"),
        GroceryItem("basil", "🌿", .produce, .gram, 30, 5, en: "Basil", it: "Basilico", de: "Basilikum", es: "Albahaca", fr: "Basilic"),
        GroceryItem("parsley", "🌿", .produce, .gram, 30, 7, en: "Parsley", it: "Prezzemolo", de: "Petersilie", es: "Perejil", fr: "Persil"),
        GroceryItem("chili", "🌶️", .produce, .piece, 3, 14, en: "Chili peppers", it: "Peperoncini", de: "Chilischoten", es: "Guindillas", fr: "Piments"),
        GroceryItem("ginger", "🫚", .produce, .gram, 100, 21, en: "Ginger", it: "Zenzero", de: "Ingwer", es: "Jengibre", fr: "Gingembre"),

        // MARK: Dairy & eggs
        GroceryItem("eggs", "🥚", .dairy, .piece, 6, 21, en: "Eggs", it: "Uova", de: "Eier", es: "Huevos", fr: "Œufs"),
        GroceryItem("milk", "🥛", .dairy, .milliliter, 1000, 7, en: "Milk", it: "Latte", de: "Milch", es: "Leche", fr: "Lait"),
        GroceryItem("butter", "🧈", .dairy, .gram, 250, 30, en: "Butter", it: "Burro", de: "Butter", es: "Mantequilla", fr: "Beurre"),
        GroceryItem("cheese", "🧀", .dairy, .gram, 200, 21, en: "Cheese", it: "Formaggio", de: "Käse", es: "Queso", fr: "Fromage"),
        GroceryItem("parmesan", "🧀", .dairy, .gram, 200, 60, en: "Parmesan", it: "Parmigiano", de: "Parmesan", es: "Parmesano", fr: "Parmesan"),
        GroceryItem("mozzarella", "🧀", .dairy, .gram, 125, 5, en: "Mozzarella", it: "Mozzarella", de: "Mozzarella", es: "Mozzarella", fr: "Mozzarella"),
        GroceryItem("feta", "🧀", .dairy, .gram, 200, 14, en: "Feta", it: "Feta", de: "Feta", es: "Queso feta", fr: "Feta"),
        GroceryItem("ricotta", "🧀", .dairy, .gram, 250, 5, en: "Ricotta", it: "Ricotta", de: "Ricotta", es: "Ricotta", fr: "Ricotta"),
        GroceryItem("yogurt", "🥣", .dairy, .gram, 500, 10, en: "Yogurt", it: "Yogurt", de: "Joghurt", es: "Yogur", fr: "Yaourt"),
        GroceryItem("cream", "🥛", .dairy, .milliliter, 200, 7, en: "Cream", it: "Panna", de: "Sahne", es: "Nata", fr: "Crème"),

        // MARK: Meat
        GroceryItem("chicken_breast", "🍗", .meat, .gram, 500, 2, en: "Chicken breast", it: "Petto di pollo", de: "Hähnchenbrust", es: "Pechuga de pollo", fr: "Blanc de poulet"),
        GroceryItem("ground_beef", "🥩", .meat, .gram, 500, 2, en: "Ground beef", it: "Carne macinata", de: "Hackfleisch", es: "Carne picada", fr: "Viande hachée"),
        GroceryItem("beef_steak", "🥩", .meat, .gram, 400, 3, en: "Beef steak", it: "Bistecca di manzo", de: "Rindersteak", es: "Filete de ternera", fr: "Steak de bœuf"),
        GroceryItem("bacon", "🥓", .meat, .gram, 200, 7, en: "Bacon", it: "Pancetta", de: "Speck", es: "Beicon", fr: "Lardons"),
        GroceryItem("ham", "🍖", .meat, .gram, 150, 5, en: "Ham", it: "Prosciutto cotto", de: "Kochschinken", es: "Jamón cocido", fr: "Jambon"),
        GroceryItem("sausages", "🌭", .meat, .piece, 6, 5, en: "Sausages", it: "Salsicce", de: "Würstchen", es: "Salchichas", fr: "Saucisses"),

        // MARK: Seafood
        GroceryItem("salmon", "🐟", .seafood, .gram, 300, 2, en: "Salmon", it: "Salmone", de: "Lachs", es: "Salmón", fr: "Saumon"),
        GroceryItem("white_fish", "🐟", .seafood, .gram, 400, 2, en: "White fish", it: "Merluzzo", de: "Kabeljau", es: "Bacalao", fr: "Cabillaud"),
        GroceryItem("shrimp", "🦐", .seafood, .gram, 300, 2, en: "Shrimp", it: "Gamberi", de: "Garnelen", es: "Gambas", fr: "Crevettes"),

        // MARK: Grains & bakery
        GroceryItem("bread", "🍞", .grains, .gram, 500, 4, en: "Bread", it: "Pane", de: "Brot", es: "Pan", fr: "Pain"),
        GroceryItem("spaghetti", "🍝", .grains, .gram, 500, nil, en: "Spaghetti", it: "Spaghetti", de: "Spaghetti", es: "Espaguetis", fr: "Spaghettis"),
        GroceryItem("pasta", "🍝", .grains, .gram, 500, nil, en: "Pasta", it: "Pasta", de: "Nudeln", es: "Pasta", fr: "Pâtes"),
        GroceryItem("rice", "🍚", .grains, .gram, 1000, nil, en: "Rice", it: "Riso", de: "Reis", es: "Arroz", fr: "Riz"),
        GroceryItem("flour", "🌾", .grains, .gram, 1000, nil, en: "Flour", it: "Farina", de: "Mehl", es: "Harina", fr: "Farine"),
        GroceryItem("oats", "🥣", .grains, .gram, 500, nil, en: "Oats", it: "Fiocchi d'avena", de: "Haferflocken", es: "Copos de avena", fr: "Flocons d'avoine"),
        GroceryItem("cereal", "🥣", .grains, .gram, 375, nil, en: "Cereal", it: "Cereali", de: "Müsli", es: "Cereales", fr: "Céréales"),
        GroceryItem("tortillas", "🫓", .grains, .piece, 8, 14, en: "Tortillas", it: "Tortillas", de: "Tortillas", es: "Tortillas de trigo", fr: "Tortillas"),

        // MARK: Pantry
        GroceryItem("olive_oil", "🫒", .pantry, .milliliter, 750, nil, en: "Olive oil", it: "Olio d'oliva", de: "Olivenöl", es: "Aceite de oliva", fr: "Huile d'olive"),
        GroceryItem("canned_tomatoes", "🥫", .pantry, .gram, 400, nil, en: "Canned tomatoes", it: "Pomodori pelati", de: "Dosentomaten", es: "Tomate en lata", fr: "Tomates en boîte"),
        GroceryItem("chickpeas", "🫘", .pantry, .gram, 400, nil, en: "Canned chickpeas", it: "Ceci in scatola", de: "Kichererbsen", es: "Garbanzos en lata", fr: "Pois chiches en boîte"),
        GroceryItem("beans", "🫘", .pantry, .gram, 400, nil, en: "Canned beans", it: "Fagioli in scatola", de: "Dosenbohnen", es: "Alubias en lata", fr: "Haricots en boîte"),
        GroceryItem("lentils", "🫘", .pantry, .gram, 500, nil, en: "Lentils", it: "Lenticchie", de: "Linsen", es: "Lentejas", fr: "Lentilles"),
        GroceryItem("tuna", "🐟", .pantry, .gram, 160, nil, en: "Canned tuna", it: "Tonno in scatola", de: "Thunfisch in der Dose", es: "Atún en lata", fr: "Thon en boîte"),
        GroceryItem("coconut_milk", "🥥", .pantry, .milliliter, 400, nil, en: "Coconut milk", it: "Latte di cocco", de: "Kokosmilch", es: "Leche de coco", fr: "Lait de coco"),
        GroceryItem("soy_sauce", "🫙", .pantry, .milliliter, 250, nil, en: "Soy sauce", it: "Salsa di soia", de: "Sojasoße", es: "Salsa de soja", fr: "Sauce soja"),
        GroceryItem("vinegar", "🫙", .pantry, .milliliter, 500, nil, en: "Vinegar", it: "Aceto", de: "Essig", es: "Vinagre", fr: "Vinaigre"),
        GroceryItem("honey", "🍯", .pantry, .gram, 250, nil, en: "Honey", it: "Miele", de: "Honig", es: "Miel", fr: "Miel"),
        GroceryItem("sugar", "🍬", .pantry, .gram, 1000, nil, en: "Sugar", it: "Zucchero", de: "Zucker", es: "Azúcar", fr: "Sucre"),
        GroceryItem("salt", "🧂", .pantry, .gram, 1000, nil, en: "Salt", it: "Sale", de: "Salz", es: "Sal", fr: "Sel"),
        GroceryItem("baking_powder", "🧁", .pantry, .gram, 100, nil, en: "Baking powder", it: "Lievito per dolci", de: "Backpulver", es: "Levadura en polvo", fr: "Levure chimique"),
        GroceryItem("curry_powder", "🍛", .pantry, .gram, 50, nil, en: "Curry powder", it: "Curry in polvere", de: "Currypulver", es: "Curry en polvo", fr: "Poudre de curry"),
        GroceryItem("stock_cubes", "🧊", .pantry, .piece, 10, nil, en: "Stock cubes", it: "Dadi da brodo", de: "Brühwürfel", es: "Pastillas de caldo", fr: "Cubes de bouillon"),
        GroceryItem("peanut_butter", "🥜", .pantry, .gram, 350, nil, en: "Peanut butter", it: "Burro d'arachidi", de: "Erdnussbutter", es: "Crema de cacahuete", fr: "Beurre de cacahuète"),

        // MARK: Frozen
        GroceryItem("frozen_peas", "🫛", .frozen, .gram, 450, nil, en: "Frozen peas", it: "Piselli surgelati", de: "Tiefkühlerbsen", es: "Guisantes congelados", fr: "Petits pois surgelés"),
        GroceryItem("frozen_berries", "🫐", .frozen, .gram, 300, nil, en: "Frozen berries", it: "Frutti di bosco surgelati", de: "Tiefkühlbeeren", es: "Frutos rojos congelados", fr: "Fruits rouges surgelés"),
        GroceryItem("ice_cream", "🍨", .frozen, .milliliter, 500, nil, en: "Ice cream", it: "Gelato", de: "Eiscreme", es: "Helado", fr: "Glace"),

        // MARK: Beverages
        GroceryItem("orange_juice", "🧃", .beverages, .milliliter, 1000, 7, en: "Orange juice", it: "Succo d'arancia", de: "Orangensaft", es: "Zumo de naranja", fr: "Jus d'orange"),
        GroceryItem("coffee", "☕", .beverages, .gram, 250, nil, en: "Coffee", it: "Caffè", de: "Kaffee", es: "Café", fr: "Café"),
        GroceryItem("tea", "🍵", .beverages, .piece, 20, nil, en: "Tea bags", it: "Bustine di tè", de: "Teebeutel", es: "Bolsitas de té", fr: "Sachets de thé"),
        GroceryItem("wine", "🍷", .beverages, .milliliter, 750, nil, en: "Wine", it: "Vino", de: "Wein", es: "Vino", fr: "Vin"),

        // MARK: Snacks
        GroceryItem("chocolate", "🍫", .snacks, .gram, 100, nil, en: "Chocolate", it: "Cioccolato", de: "Schokolade", es: "Chocolate", fr: "Chocolat"),
        GroceryItem("biscuits", "🍪", .snacks, .gram, 300, nil, en: "Biscuits", it: "Biscotti", de: "Kekse", es: "Galletas", fr: "Biscuits"),
        GroceryItem("crisps", "🍟", .snacks, .gram, 150, nil, en: "Crisps", it: "Patatine", de: "Chips", es: "Patatas fritas", fr: "Chips"),
    ]
}

// MARK: - Adding to the pantry

/// A grocery chosen for the pantry, with the amount and expiry to save.
struct GroceryPick: Identifiable, Hashable {
    let item: GroceryItem
    var quantity: Decimal
    var expiryDate: Date?

    var id: String { item.id }

    init(item: GroceryItem) {
        self.item = item
        self.quantity = item.packQuantity
        self.expiryDate = item.suggestedExpiry
    }
}

extension GroceryCatalog {
    /// Saves picks to the pantry: tops up what's already there and creates the rest,
    /// so the same grocery never ends up twice.
    @MainActor
    static func stock(_ picks: [GroceryPick], foods: [FoodModel], in context: ModelContext) {
        for pick in picks where pick.quantity > 0 {
            guard let food = pick.item.pantryFood(in: foods) else {
                context.insert(pick.item.makeFood(
                    quantity: pick.quantity,
                    currentQuantity: pick.quantity,
                    expiryDate: pick.expiryDate
                ))
                continue
            }

            // Older stock on the shelf still spoils first, so keep its date unless it's gone or already past.
            if let expiry = pick.expiryDate, food.isOutOfStock || food.expiryDate == nil || food.isExpired {
                food.expiryDate = expiry
            }

            let added = food.unit.converted(pick.quantity, from: pick.item.unit)
            context.insert(FoodRefillModel(quantity: added, unit: food.unit, food: food))
            food.currentQuantity += added
            food.quantity = max(food.quantity, food.currentQuantity)
        }
        context.saveConfirmedChanges()
    }
}

extension ModelContext {
    /// Writes something the person just confirmed to disk now rather than waiting for autosave,
    /// which reports nothing when it fails and doesn't run if the app is killed first.
    func saveConfirmedChanges() {
        do {
            try save()
        } catch {
            assertionFailure("Could not save: \(error)")
        }
    }
}

extension FoodUnit {
    /// `quantity` of `source` expressed in this unit, using the same gram equivalents as the stats.
    func converted(_ quantity: Decimal, from source: FoodUnit) -> Decimal {
        guard source != self else { return quantity }
        let oneOfSelf = convertToGrams(Decimal(1))
        guard oneOfSelf > 0 else { return quantity }
        var exact = source.convertToGrams(quantity) / oneOfSelf
        var rounded = Decimal()
        NSDecimalRound(&rounded, &exact, 2, .plain)
        return rounded
    }
}
