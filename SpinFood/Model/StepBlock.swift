import Foundation
import SwiftData

enum StepBlockType: String, Codable {
    case text
    case bulletList
    case image
    case drawing
    case timer
    case ingredient
}

@Model
final class StepBlock {
    var id: UUID = UUID()
    var order: Int = 0
    var type: StepBlockType = StepBlockType.text
    var textContent: String = ""
    var listItems: [String] = []
    var isCheckList: Bool = false
    @Attribute(.externalStorage) var imageData: Data?
    @Attribute(.externalStorage) var drawingData: Data?
    var timerDuration: TimeInterval = 60
    var timerLabel: String = ""
    var linkedIngredientIDs: [UUID] = []
    var ingredientStepQuantities: [String: Double] = [:]

    @Relationship var step: StepRecipe? = nil

    init(
        type: StepBlockType,
        order: Int = 0,
        textContent: String = "",
        listItems: [String] = [],
        isCheckList: Bool = false,
        imageData: Data? = nil,
        drawingData: Data? = nil,
        timerDuration: TimeInterval = 60,
        timerLabel: String = "",
        linkedIngredientIDs: [UUID] = [],
        ingredientStepQuantities: [String: Double] = [:]
    ) {
        self.type = type
        self.order = order
        self.textContent = textContent
        self.listItems = listItems
        self.isCheckList = isCheckList
        self.imageData = imageData
        self.drawingData = drawingData
        self.timerDuration = timerDuration
        self.timerLabel = timerLabel
        self.linkedIngredientIDs = linkedIngredientIDs
        self.ingredientStepQuantities = ingredientStepQuantities
    }
}
