import Foundation
import SwiftData
import UniformTypeIdentifiers

// MARK: - Export model

struct RecipeExport: Codable {
    var version: Int = 1
    var name: String
    var descriptionRecipe: String
    var imageBase64: String?
    var duration: TimeInterval
    var servings: Int
    var rating: Int
    var difficulty: RecipeDifficulty?
    var tags: [RecipeTag]
    var ingredients: [ExportIngredient]
    var steps: [ExportStep]

    struct ExportIngredient: Codable {
        var foodName: String
        var emoji: String
        var unitRaw: String
        var quantityNeeded: Double
    }

    struct ExportStep: Codable {
        var text: String
        var suggestedDuration: TimeInterval?
        var blocks: [ExportBlock]
    }

    struct ExportBlock: Codable {
        var typeRaw: String
        var textContent: String
        var listItems: [String]
        var isCheckList: Bool
        var timerDuration: Double
        var timerLabel: String
    }
}

// MARK: - Errors

enum RecipeTransferError: LocalizedError {
    case encodingFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed: return "Could not export the recipe."
        case .decodingFailed: return "The selected file is not a valid SpinFood recipe."
        }
    }
}

// MARK: - Transfer logic

final class RecipeTransfer {
    static let fileExtension = "spinfood"

    static func export(_ recipe: RecipeModel) throws -> URL {
        let export = RecipeExport(
            name: recipe.name,
            descriptionRecipe: recipe.descriptionRecipe,
            imageBase64: recipe.image?.base64EncodedString(),
            duration: recipe.duration,
            servings: recipe.servings,
            rating: recipe.rating,
            difficulty: recipe.difficulty,
            tags: recipe.tags,
            ingredients: (recipe.ingredients ?? []).compactMap { item -> RecipeExport.ExportIngredient? in
                guard let food = item.ingredient else { return nil }
                return RecipeExport.ExportIngredient(
                    foodName: food.name,
                    emoji: food.emoji,
                    unitRaw: food.unit.rawValue,
                    quantityNeeded: NSDecimalNumber(decimal: item.quantityNeeded).doubleValue
                )
            },
            steps: (recipe.steps ?? [])
                .sorted { $0.order < $1.order }
                .map { step in
                    RecipeExport.ExportStep(
                        text: step.text,
                        suggestedDuration: step.suggestedDuration,
                        blocks: step.sortedBlocks.compactMap { block -> RecipeExport.ExportBlock? in
                            switch block.type {
                            case .text:
                                return RecipeExport.ExportBlock(
                                    typeRaw: "text",
                                    textContent: block.textContent,
                                    listItems: [],
                                    isCheckList: false,
                                    timerDuration: 0,
                                    timerLabel: ""
                                )
                            case .bulletList:
                                return RecipeExport.ExportBlock(
                                    typeRaw: "bulletList",
                                    textContent: "",
                                    listItems: block.listItems,
                                    isCheckList: block.isCheckList,
                                    timerDuration: 0,
                                    timerLabel: ""
                                )
                            case .timer:
                                return RecipeExport.ExportBlock(
                                    typeRaw: "timer",
                                    textContent: "",
                                    listItems: [],
                                    isCheckList: false,
                                    timerDuration: block.timerDuration,
                                    timerLabel: block.timerLabel
                                )
                            case .image, .drawing, .ingredient:
                                return nil
                            }
                        }
                    )
                }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(export) else {
            throw RecipeTransferError.encodingFailed
        }

        let safeName = recipe.name.isEmpty ? "Recipe" : recipe.name
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(safeName)
            .appendingPathExtension(fileExtension)
        try data.write(to: url)
        return url
    }

    static func `import`(from url: URL, into modelContext: ModelContext) throws {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        guard let export = try? JSONDecoder().decode(RecipeExport.self, from: data) else {
            throw RecipeTransferError.decodingFailed
        }

        let recipe = RecipeModel(
            name: export.name,
            descriptionRecipe: export.descriptionRecipe,
            image: export.imageBase64.flatMap { Data(base64Encoded: $0) },
            duration: export.duration,
            servings: export.servings,
            difficulty: export.difficulty,
            tags: export.tags
        )
        recipe.rating = export.rating
        modelContext.insert(recipe)

        for (i, exportStep) in export.steps.enumerated() {
            let step = StepRecipe(text: exportStep.text, suggestedDuration: exportStep.suggestedDuration ?? 0)
            step.order = i
            step.recipes = recipe
            modelContext.insert(step)

            for (j, exportBlock) in exportStep.blocks.enumerated() {
                guard let type = StepBlockType(rawValue: exportBlock.typeRaw) else { continue }
                let block = StepBlock(type: type, order: j)
                switch type {
                case .text:
                    block.textContent = exportBlock.textContent
                case .bulletList:
                    block.listItems = exportBlock.listItems
                    block.isCheckList = exportBlock.isCheckList
                case .timer:
                    block.timerDuration = exportBlock.timerDuration
                    block.timerLabel = exportBlock.timerLabel
                default:
                    break
                }
                modelContext.insert(block)
                if step.blocks == nil { step.blocks = [] }
                step.blocks!.append(block)
            }

            if recipe.steps == nil { recipe.steps = [] }
            recipe.steps!.append(step)
        }

        try modelContext.save()
    }
}
