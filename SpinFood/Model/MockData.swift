import Foundation
import SwiftData

enum MockData {
    @MainActor
    static func insertSampleData(into context: ModelContext) {
        // MARK: - Foods
        let pasta = FoodModel(name: "Spaghetti", emoji: "🍝", quantity: 500, currentQuantity: 400, unit: .gram, category: .grains)
        let tomatoSauce = FoodModel(name: "Tomato Sauce", emoji: "🍅", quantity: 400, currentQuantity: 400, unit: .milliliter, category: .pantry)
        let groundBeef = FoodModel(name: "Ground Beef", emoji: "🥩", quantity: 500, currentQuantity: 300, unit: .gram, category: .meat)
        let parmesan = FoodModel(name: "Parmesan", emoji: "🧀", quantity: 200, currentQuantity: 150, unit: .gram, category: .dairy)
        let eggs = FoodModel(name: "Eggs", emoji: "🥚", quantity: 12, currentQuantity: 8, unit: .piece, category: .produce)
        let butter = FoodModel(name: "Butter", emoji: "🧈", quantity: 250, currentQuantity: 200, unit: .gram, category: .dairy)
        let milk = FoodModel(name: "Milk", emoji: "🥛", quantity: 1, currentQuantity: 1, unit: .liter, category: .dairy)
        let chickenBreast = FoodModel(name: "Chicken Breast", emoji: "🍗", quantity: 600, currentQuantity: 500, unit: .gram, category: .meat)
        let garlic = FoodModel(name: "Garlic", emoji: "🧄", quantity: 10, currentQuantity: 8, unit: .piece, category: .produce)
        let oliveOil = FoodModel(name: "Olive Oil", emoji: "🫒", quantity: 500, currentQuantity: 350, unit: .milliliter, category: .pantry)
        let onion = FoodModel(name: "Onion", emoji: "🧅", quantity: 5, currentQuantity: 4, unit: .piece, category: .produce)
        let rice = FoodModel(name: "Jasmine Rice", emoji: "🍚", quantity: 500, currentQuantity: 400, unit: .gram, category: .grains)
        let soySauce = FoodModel(name: "Soy Sauce", emoji: "🫙", quantity: 250, currentQuantity: 200, unit: .milliliter, category: .pantry)
        let bellPepper = FoodModel(name: "Bell Pepper", emoji: "🫑", quantity: 4, currentQuantity: 3, unit: .piece, category: .produce)
        let salmon = FoodModel(name: "Salmon Fillet", emoji: "🐟", quantity: 400, currentQuantity: 400, unit: .gram, category: .seafood)
        let lemon = FoodModel(name: "Lemon", emoji: "🍋", quantity: 6, currentQuantity: 5, unit: .piece, category: .produce)

        let allFoods = [pasta, tomatoSauce, groundBeef, parmesan, eggs, butter, milk,
                        chickenBreast, garlic, oliveOil, onion, rice, soySauce, bellPepper, salmon, lemon]
        allFoods.forEach { context.insert($0) }

        // MARK: - Recipe 1: Spaghetti Bolognese
        let bolognese = RecipeModel(
            name: "Spaghetti Bolognese",
            descriptionRecipe: "A classic Italian meat sauce served over al dente spaghetti, slow-cooked to develop deep, rich flavour.",
            duration: 45 * 60,
            servings: 4
        )

        let bStep1 = StepRecipe(text: "Sauté aromatics")
        bStep1.order = 0
        bStep1.blocks = [
            StepBlock(type: .text, order: 0, textContent: "Heat olive oil in a large pan over medium heat. Add diced onion and minced garlic. Cook for 5 minutes until softened and translucent."),
            StepBlock(type: .timer, order: 1, timerDuration: 5 * 60, timerLabel: "Sauté onion & garlic")
        ]

        let bStep2 = StepRecipe(text: "Brown the beef")
        bStep2.order = 1
        bStep2.blocks = [
            StepBlock(type: .text, order: 0, textContent: "Add ground beef to the pan, breaking it apart with a wooden spoon. Cook until no pink remains, about 8 minutes."),
            StepBlock(type: .timer, order: 1, timerDuration: 8 * 60, timerLabel: "Brown beef")
        ]

        let bStep3 = StepRecipe(text: "Simmer the sauce")
        bStep3.order = 2
        bStep3.blocks = [
            StepBlock(type: .text, order: 0, textContent: "Pour in tomato sauce. Reduce heat and simmer uncovered for 20 minutes, stirring occasionally."),
            StepBlock(type: .timer, order: 1, timerDuration: 20 * 60, timerLabel: "Simmer sauce")
        ]

        let bStep4 = StepRecipe(text: "Cook pasta & serve")
        bStep4.order = 3
        bStep4.blocks = [
            StepBlock(type: .text, order: 0, textContent: "Cook spaghetti in salted boiling water until al dente. Drain and top with bolognese sauce. Finish with grated parmesan."),
            StepBlock(type: .bulletList, order: 1, listItems: ["Salt the pasta water generously", "Reserve some pasta water to adjust sauce consistency", "Serve immediately"])
        ]

        bolognese.steps = [bStep1, bStep2, bStep3, bStep4]
        bolognese.ingredients = [
            RecipeFoodModel(ingredient: pasta, quantityNeeded: 200),
            RecipeFoodModel(ingredient: tomatoSauce, quantityNeeded: 200),
            RecipeFoodModel(ingredient: groundBeef, quantityNeeded: 250),
            RecipeFoodModel(ingredient: parmesan, quantityNeeded: 40),
            RecipeFoodModel(ingredient: onion, quantityNeeded: 1),
            RecipeFoodModel(ingredient: garlic, quantityNeeded: 2),
            RecipeFoodModel(ingredient: oliveOil, quantityNeeded: 30)
        ]

        // MARK: - Recipe 2: Creamy Scrambled Eggs
        let scrambledEggs = RecipeModel(
            name: "Creamy Scrambled Eggs",
            descriptionRecipe: "Soft, buttery scrambled eggs cooked low and slow for the creamiest texture.",
            duration: 10 * 60,
            servings: 2
        )

        let eStep1 = StepRecipe(text: "Whisk the eggs")
        eStep1.order = 0
        eStep1.blocks = [
            StepBlock(type: .text, order: 0, textContent: "Crack 4 eggs into a bowl, add a splash of milk and a pinch of salt. Whisk vigorously until fully combined and slightly frothy."),
        ]

        let eStep2 = StepRecipe(text: "Cook low and slow")
        eStep2.order = 1
        eStep2.blocks = [
            StepBlock(type: .text, order: 0, textContent: "Melt butter in a non-stick pan over the lowest heat. Pour in egg mixture. Using a silicone spatula, gently fold the eggs every 20–30 seconds."),
            StepBlock(type: .timer, order: 1, timerDuration: 4 * 60, timerLabel: "Cook eggs")
        ]

        let eStep3 = StepRecipe(text: "Finish & plate")
        eStep3.order = 2
        eStep3.blocks = [
            StepBlock(type: .text, order: 0, textContent: "Remove from heat while the eggs still look slightly underdone — residual heat will finish them. Season with salt and serve immediately."),
            StepBlock(type: .bulletList, order: 1, listItems: ["Do not overcook", "Serve on warm plates", "Add chives for garnish if desired"])
        ]

        scrambledEggs.steps = [eStep1, eStep2, eStep3]
        scrambledEggs.ingredients = [
            RecipeFoodModel(ingredient: eggs, quantityNeeded: 4),
            RecipeFoodModel(ingredient: butter, quantityNeeded: 20),
            RecipeFoodModel(ingredient: milk, quantityNeeded: 30)
        ]

        // MARK: - Recipe 3: Chicken Stir Fry
        let stirFry = RecipeModel(
            name: "Chicken Stir Fry",
            descriptionRecipe: "A quick and flavourful stir fry with tender chicken, crisp vegetables, and a savory soy-garlic sauce over steamed rice.",
            duration: 30 * 60,
            servings: 3
        )

        let sStep1 = StepRecipe(text: "Cook the rice")
        sStep1.order = 0
        sStep1.blocks = [
            StepBlock(type: .text, order: 0, textContent: "Rinse rice until water runs clear. Add to a pot with 1.5x water. Bring to a boil, then cover and simmer on low for 15 minutes."),
            StepBlock(type: .timer, order: 1, timerDuration: 15 * 60, timerLabel: "Simmer rice")
        ]

        let sStep2 = StepRecipe(text: "Prep the chicken")
        sStep2.order = 1
        sStep2.blocks = [
            StepBlock(type: .text, order: 0, textContent: "Slice chicken breast into thin strips. Season lightly with salt and pepper. Set aside."),
        ]

        let sStep3 = StepRecipe(text: "Stir fry")
        sStep3.order = 2
        sStep3.blocks = [
            StepBlock(type: .text, order: 0, textContent: "Heat olive oil in a wok or large pan over high heat. Add chicken and cook until golden, about 5 minutes. Add garlic and bell pepper, stir fry for 3 more minutes."),
            StepBlock(type: .timer, order: 1, timerDuration: 5 * 60, timerLabel: "Cook chicken")
        ]

        let sStep4 = StepRecipe(text: "Add sauce & serve")
        sStep4.order = 3
        sStep4.blocks = [
            StepBlock(type: .text, order: 0, textContent: "Pour soy sauce over the stir fry. Toss everything together for 1 minute. Serve over steamed rice."),
            StepBlock(type: .bulletList, order: 1, listItems: ["Keep the heat high for wok hei flavour", "Don't crowd the pan", "Garnish with sesame seeds if available"])
        ]

        stirFry.steps = [sStep1, sStep2, sStep3, sStep4]
        stirFry.ingredients = [
            RecipeFoodModel(ingredient: chickenBreast, quantityNeeded: 300),
            RecipeFoodModel(ingredient: rice, quantityNeeded: 200),
            RecipeFoodModel(ingredient: soySauce, quantityNeeded: 50),
            RecipeFoodModel(ingredient: garlic, quantityNeeded: 3),
            RecipeFoodModel(ingredient: bellPepper, quantityNeeded: 2),
            RecipeFoodModel(ingredient: oliveOil, quantityNeeded: 20)
        ]

        // MARK: - Recipe 4: Pan-Seared Salmon
        let searedSalmon = RecipeModel(
            name: "Pan-Seared Salmon",
            descriptionRecipe: "Crispy-skinned salmon with a golden crust, finished with garlic butter and a squeeze of fresh lemon.",
            duration: 20 * 60,
            servings: 2
        )

        let ssStep1 = StepRecipe(text: "Prep the salmon")
        ssStep1.order = 0
        ssStep1.blocks = [
            StepBlock(type: .text, order: 0, textContent: "Pat salmon fillets dry with paper towels — this is key for a crispy skin. Season generously with salt and pepper on both sides."),
        ]

        let ssStep2 = StepRecipe(text: "Sear skin-side down")
        ssStep2.order = 1
        ssStep2.blocks = [
            StepBlock(type: .text, order: 0, textContent: "Heat olive oil in a skillet over medium-high heat until shimmering. Place salmon skin-side down and press gently. Cook without moving for 4 minutes."),
            StepBlock(type: .timer, order: 1, timerDuration: 4 * 60, timerLabel: "Sear skin side")
        ]

        let ssStep3 = StepRecipe(text: "Flip & add garlic butter")
        ssStep3.order = 2
        ssStep3.blocks = [
            StepBlock(type: .text, order: 0, textContent: "Flip the salmon. Add butter and crushed garlic to the pan. Baste the fish with the melted butter for 2–3 minutes until cooked through."),
            StepBlock(type: .timer, order: 1, timerDuration: 3 * 60, timerLabel: "Baste with butter")
        ]

        let ssStep4 = StepRecipe(text: "Rest & serve")
        ssStep4.order = 3
        ssStep4.blocks = [
            StepBlock(type: .text, order: 0, textContent: "Transfer salmon to a plate and let rest for 1 minute. Squeeze fresh lemon juice over the top and serve immediately."),
            StepBlock(type: .bulletList, order: 1, listItems: ["The skin should be crispy and release easily", "Internal temperature: 52–54°C for medium", "Pairs well with steamed greens or roasted potatoes"])
        ]

        searedSalmon.steps = [ssStep1, ssStep2, ssStep3, ssStep4]
        searedSalmon.ingredients = [
            RecipeFoodModel(ingredient: salmon, quantityNeeded: 400),
            RecipeFoodModel(ingredient: butter, quantityNeeded: 30),
            RecipeFoodModel(ingredient: garlic, quantityNeeded: 2),
            RecipeFoodModel(ingredient: oliveOil, quantityNeeded: 20),
            RecipeFoodModel(ingredient: lemon, quantityNeeded: 1)
        ]

        // MARK: - Insert recipes
        [bolognese, scrambledEggs, stirFry, searedSalmon].enumerated().forEach { index, recipe in
            recipe.order = index
            context.insert(recipe)
        }
    }
}
