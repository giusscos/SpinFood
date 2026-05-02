# Recipe UI Redesign

## Overview

End-to-end visual overhaul of the recipe section — from the list card through the detail page and into the editor. The theme is a physical cookbook: full-bleed image cards in the list, a polaroid-photo detail page on warm paper, and a matching editor that feels like filling in a recipe card.

---

## Recipe List (`RecipeView` + `RecipeRowView`)

### RecipeView
- Replaced grouped `List` style with `.plain` so cards sit edge-to-edge.
- Filter logic simplified to use model-level computed properties (`recipe.canCook`, `recipe.missingIngredients`) instead of re-querying food.
- Empty states updated with clearer copy and inline action buttons.

### RecipeRowView
- Complete rewrite as a **full-bleed image card** (220 pt on iPhone, 320 pt on iPad).
- Bottom gradient overlay (`clear → black 0.7`) keeps text readable over any photo.
- Three info pills on the bottom row: duration (clock icon), servings (person.2 icon), and a **Ready** (green) or **N missing** (orange) status badge.
- Placeholder card uses an orange→red gradient with a fork-and-knife icon when no photo is set.
- `matchedTransitionSource` + `.navigationTransition(.zoom)` for a smooth zoom into the detail.

---

## Recipe Detail (`RecipeDetailsView` + subviews)

### RecipeDetailsView
- **Removed** parallax hero image and blurred background.
- New layout: `NavigationStack > ScrollView > VStack`.
- **Polaroid photo** centered at the top — white frame (12 pt padding), 52 pt white bottom strip, 2 pt corner radius, drop shadow, −1.5° tilt. Falls back to a styled gradient placeholder with the same treatment.
- **Warm paper background**: `#FCFAF5` in light mode, `.secondarySystemBackground` in dark.
- Title uses `.largeTitle.bold()`; description uses `.body` in secondary color.
- DURATION and SERVINGS shown as small uppercase label + value pairs side by side.
- Thin `.secondary.opacity(0.25)` divider separates the header block from content sections.
- Added `.steps([StepRecipe])` case to `ActiveRecipeDetailSheet` for the full method sheet.

### RecipeDetailsIngredientView
- Replaced vertical list with a **3-row horizontal `LazyHGrid`** (scrollable).
- Each ingredient is an `IngredientCardView` (88 × 110 pt + 8 pt padding):
  - Category icon in a colored circle (15% opacity fill).
  - Ingredient name (2-line cap, center-aligned).
  - Quantity + unit in caption2.
  - Missing ingredients get a red icon/text and a 1.5 pt red border.

### RecipeDetailsStepView
- Shows only the **first step as a preview** with the numbered accent circle.
- "View all N steps" button opens `StepsSheetView` (hidden when only 1 step).
- `StepsSheetView` — modal sheet with full numbered step list, optional step images, and a Done toolbar button.

### RecipeDetailsCookButtonView
- Prominent Cook button disabled when ingredients are missing.
- Shows "\(n) ingredient(s) missing" caption below the button when disabled.

---

## Recipe Editor (`EditRecipeView` + subviews)

### EditRecipeView
- **Removed** `GeometryReader`, parallax scroll, and blurred image background.
- Adopts the same **warm paper background** as the detail view.
- Layout: `NavigationStack > ScrollView > VStack` with consistent `.secondary.opacity(0.25)` dividers between sections.
- Photo section, name/description, duration/servings, ingredients, and steps flow naturally in a single scroll.
- Duration and Servings moved into a side-by-side `HStack` with icon-labeled headers.
- Stepper value displayed as a standalone text label (not inline in the stepper).
- `photosPicker` moved to the `ScrollView` level (no longer nested inside the VStack).

### EditRecipePhotoView
- **Removed** `safeArea` and `size` parameters.
- Redesigned as a **polaroid card** matching the detail view (260 × 220 pt image, white frame, −1.5° tilt, drop shadow).
- When no photo: grey placeholder with camera icon and "Add Photo" label; tap the "Choose photo" button inside the white strip.
- When a photo is set: "Edit photo" menu button inside the white strip → Update / Remove options.

### EditRecipeIngredientView
- Ingredient list now uses a `.regularMaterial` card with `Divider` separators and category icons — matching the detail view layout.
- "Add ingredient" area has a styled Picker and quantity field, each on a `.regularMaterial` background pill.
- Remove button uses `xmark.circle.fill` with palette rendering (white × red).
- Add button disabled unless a positive quantity is entered.

---

## Shared Design Tokens

| Token | Value |
|---|---|
| Paper background (light) | `UIColor(red: 0.99, green: 0.98, blue: 0.96)` |
| Paper background (dark) | `.secondarySystemBackground` |
| Polaroid frame padding | 12 pt sides/top, 52 pt bottom |
| Polaroid tilt | −1.5° |
| Polaroid shadow | `black 18% opacity, radius 10, y +4` |
| Section divider | `.secondary.opacity(0.25)`, 1 pt height |
| Ingredient card size | 88 × 110 pt (+ 8 pt inner padding) |
| Step number circle | 32 × 32 pt, `.accent` fill, white bold text |
