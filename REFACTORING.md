# SpinFood – Refactoring Notes

## Goal

Reduce food waste and make grocery shopping more efficient. SpinFood tracks what you have in your pantry, links those items to recipes, and generates a shopping list showing exactly what you need to buy.

---

## Changes Made

### Deleted

| Item | Reason |
|------|--------|
| `SpinFoodWatch Watch App/` (entire target) | Simplify scope; removed from Xcode project and filesystem |
| `Model/WatchConnectivityManager.swift` | No longer needed without Watch target |
| `FoodModel.eatenAt: [Date]` | Legacy backward-compat field replaced by `FoodConsumptionModel` records |

---

### Model Changes

#### `FoodModel.swift`

- **Added** `category: FoodCategory` — categorises food (Produce, Dairy, Meat, etc.) for grouping in the shopping list and pantry view
- **Added** `expiryDate: Date?` — optional expiry tracking; drives `isExpiringSoon` / `isExpired` computed flags
- **Added** `stockPercentage: Double` — `currentQuantity / quantity`, clamped 0…1, drives the stock bar in `FoodRowView`
- **Added** `isLowStock: Bool` — true when stock < 20 %
- **Added** `isOutOfStock: Bool` — true when `currentQuantity <= 0`
- **Added** `daysUntilExpiry: Int?` — calendar-day delta from today
- **Added** `isExpiringSoon: Bool` — true when expiry is within 3 days
- **Added** `isExpired: Bool` — true when expiry has passed
- **Removed** `eatenAt: [Date]` — legacy field; all consumption is tracked via `FoodConsumptionModel`

#### `FoodCategory` enum (new, in `FoodModel.swift`)

Ten categories with a `icon: String` (SF Symbol) and `color: String` property:
`produce`, `dairy`, `meat`, `seafood`, `grains`, `pantry`, `frozen`, `beverages`, `snacks`, `other`

#### `RecipeModel.swift`

- **Added** `servings: Int = 2` — number of servings the recipe produces
- **Added** `canCook: Bool` — computed; true when all ingredient `currentQuantity` ≥ `quantityNeeded`
- **Added** `missingIngredients: [RecipeFoodModel]` — computed; list of ingredients where stock is insufficient

---

### New Views

#### `View/Onboarding/OnboardingView.swift`

Three-step animated onboarding shown on first launch (controlled by `@AppStorage("onboarding_completed")`):

1. **Welcome** — explains app purpose with animated icon and three feature rows
2. **Add Food** — inline form: name, category picker, quantity + unit; saves a `FoodModel` on confirm
3. **Add Recipe** — names a first recipe; saves a `RecipeModel` on confirm

Each step has a "Skip for now" escape hatch. Spring animations and slide transitions make the flow feel native.

#### `View/Shopping/ShoppingListView.swift`

Generates a shopping list from recipe ingredient gaps (`quantityNeeded - currentQuantity`):

- Aggregates the same ingredient across multiple recipes into a single line item
- Groups items by `FoodCategory` with section headers showing the category icon
- Checkbox per item (strikethrough when ticked, "Clear checked" toolbar button)
- Optional recipe filter sheet (`RecipePickerSheet`) — narrow the list to specific recipes
- Empty state when pantry covers all recipe requirements

---

### Updated Views

#### `View/Food/FoodRowView.swift`

- Category icon in a coloured circle (hue matches `FoodCategory`)
- Category name and optional expiry label in secondary text
- Stock bar (`StockBar`) showing fill percentage, coloured green/orange/red

#### `View/Food/EditFoodView.swift`

- **Category** `Picker` added
- **Expiry date** section with a `Toggle` to opt in and a `DatePicker` when enabled
- Toolbar uses `cancellationAction` / `confirmationAction` placement for sheet-correct layout
- Save now uses a clean `isEditing` computed property instead of checking `food != nil` everywhere

#### `View/ContentView.swift`

- Added onboarding gate: shows `OnboardingView` when `onboarding_completed` is `false`
- Added **Shopping** tab (`ShoppingListView`) — 4 tabs total: Summary · Recipes · Shopping · Pantry
- "Food" tab renamed **Pantry** for clarity

#### `SpinFoodApp.swift`

- Schema now explicitly lists all six models: `RecipeModel`, `StepRecipe`, `FoodModel`, `RecipeFoodModel`, `FoodConsumptionModel`, `FoodRefillModel`
- Watch-related code removed

#### `View/Summary/FoodConsumptionStatsView.swift`

- Removed all references to the deleted `eatenAt` field
- `consumedFood` filter and detail view now rely entirely on `FoodConsumptionModel` records

#### `View/Recipe/RecipeConfirmEatView.swift`

- Removed the `inventoryItem.eatenAt.append(Date.now)` legacy write

---

## Architecture Notes

- **Data persistence**: SwiftData (`@Model`, `@Relationship`). No migration step needed — all new fields have defaults (`category = .other`, `expiryDate = nil`, `servings = 2`).
- **Onboarding state**: `@AppStorage("onboarding_completed")` — persists across launches, survives app updates.
- **Shopping list**: purely computed from live SwiftData queries — no extra model or persistence needed.
- **No Combine**: async/await and SwiftData reactive queries used throughout, consistent with existing codebase style.
