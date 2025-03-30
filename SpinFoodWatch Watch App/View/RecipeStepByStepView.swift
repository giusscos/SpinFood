//
//  RecipeStepByStepView.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 30/03/25.
//

import SwiftUI
import SwiftData

struct RecipeStepByStepView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var recipe: RecipeModel
    
    @State private var currentStepIndex: Int = 0
    @State private var showConfirmFinish: Bool = false
    
    var totalSteps: Int {
        return recipe.stepInstructions.count
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // Progress indicator
                HStack {
                    Text("Step \(currentStepIndex + 1) of \(totalSteps)")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        showConfirmFinish = true
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                if !recipe.stepInstructions.isEmpty && currentStepIndex < recipe.stepInstructions.count {
                    // Step image (if available)
                    if currentStepIndex < recipe.stepImages.count,
                       let imageData = recipe.stepImages[currentStepIndex],
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // Step instructions
                    Text(recipe.stepInstructions[currentStepIndex])
                        .multilineTextAlignment(.leading)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical)
                    
                    Spacer()
                    
                    // Navigation buttons
                    HStack {
                        if currentStepIndex > 0 {
                            Button {
                                currentStepIndex -= 1
                            } label: {
                                Image(systemName: "arrow.left")
                                    .padding()
                            }
                            .buttonStyle(.bordered)
                            .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        if currentStepIndex < totalSteps - 1 {
                            Button {
                                currentStepIndex += 1
                                recipe.lastStepIndex = currentStepIndex
                            } label: {
                                Image(systemName: "arrow.right")
                                    .padding()
                            }
                            .buttonStyle(.borderedProminent)
                            .clipShape(Circle())
                        } else {
                            Button {
                                finishCooking()
                            } label: {
                                Text("Finish")
                                    .padding(.horizontal)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    Text("No steps available for this recipe")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .navigationTitle("Cooking")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Start from the last viewed step or from the beginning
            currentStepIndex = min(recipe.lastStepIndex, max(0, totalSteps - 1))
        }
        .alert("Finish cooking?", isPresented: $showConfirmFinish) {
            Button("Continue Cooking", role: .cancel) {}
            Button("Finish", role: .destructive) {
                finishCooking()
            }
        } message: {
            Text("Are you sure you want to finish cooking this recipe?")
        }
    }
    
    private func finishCooking() {
        // Mark recipe as cooked
        if !recipe.cookedAt.contains(where: { Calendar.current.isDate($0, inSameDayAs: Date()) }) {
            recipe.cookedAt.append(Date())
        }
        
        // Update ingredient inventory by decreasing quantities
        if let ingredients = recipe.ingredients {
            for ingredient in ingredients {
                if let foodItem = ingredient.ingredient {
                    // Find the item in inventory
                    if let inventoryItem = foodItem.consumptions?.first?.food {
                        let consumptionQuantity = ingredient.quantityNeeded
                        
                        // Create a consumption record
                        let consumption = FoodConsumptionModel(
                            food: inventoryItem,
                            quantity: consumptionQuantity,
                            unit: inventoryItem.unit,
                            date: Date()
                        )
                        
                        // Update current quantity
                        inventoryItem.currentQuantity = max(0, inventoryItem.currentQuantity - consumptionQuantity)
                        
                        // Add consumption to model context
                        modelContext.insert(consumption)
                    }
                }
            }
        }
        
        // Reset step index
        recipe.lastStepIndex = 0
        
        // Dismiss view
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: RecipeModel.self, configurations: config)
    
    let sampleRecipe = RecipeModel(name: "Pasta Carbonara")
    sampleRecipe.stepInstructions = [
        "Boil water and cook pasta according to package instructions.",
        "In a bowl, whisk together eggs, grated cheese, and pepper.",
        "Cook pancetta or bacon until crispy.",
        "Drain pasta, reserving some pasta water.",
        "Off heat, quickly mix pasta with egg mixture and pancetta."
    ]
    
    return RecipeStepByStepView(recipe: sampleRecipe)
        .modelContainer(container)
} 