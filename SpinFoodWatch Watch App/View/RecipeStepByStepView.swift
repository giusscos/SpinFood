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
    
    @Query var food: [FoodModel]
    
    var recipe: RecipeModel
    
    @State private var currentStepIndex: Int = 0
    @State private var showConfirmFinish: Bool = false
    
    var totalSteps: Int {
        if let steps = recipe.steps {
            return steps.count
        } else {
            return 0
        }
    }
    
    var body: some View {
        ScrollView {
//            VStack(alignment: .leading, spacing: 15) {
//                Text("Step \(currentStepIndex + 1) of \(totalSteps)")
//                    .font(.headline)
//                
//                if !recipe.steps.isEmpty && currentStepIndex < recipe.steps.count {
//                    // Step image (if available)
//                    if currentStepIndex < recipe.stepImages.count,
//                       let imageData = recipe.step[currentStepIndex],
//                       let uiImage = UIImage(data: imageData) {
//                        Image(uiImage: uiImage)
//                            .resizable()
//                            .scaledToFit()
//                            .frame(maxWidth: .infinity)
//                            .clipShape(RoundedRectangle(cornerRadius: 8))
//                    }
//                    
//                    // Step instructions
//                    Text(recipe.stepInstructions[currentStepIndex])
//                        .multilineTextAlignment(.leading)
//                        .font(.body)
//                        .padding(.vertical)
//                        .frame(maxHeight: .infinity, alignment: .topLeading)
//                } else {
//                    Text("No steps available for this recipe")
//                        .foregroundStyle(.secondary)
//                }
//            }
//            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showConfirmFinish = true
                } label: {
                    Label("Skip", systemImage: "forward.end.fill")
                }
            }
            
            ToolbarItem(placement: .bottomBar) {
                // Navigation buttons
                HStack {
                    if currentStepIndex > 0 {
                        Button {
                            currentStepIndex -= 1
                        } label: {
                            Label("Back", systemImage: "arrow.left")
                                .padding()
                        }
                        .clipShape(Circle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    if currentStepIndex < totalSteps - 1 {
                        Button {
                            currentStepIndex += 1
                            recipe.lastStepIndex = currentStepIndex
                        } label: {
                            Label("Next", systemImage: "arrow.right")
                                .padding()
                        }
                        .clipShape(Circle())
                    } else {
                        Button {
                            finishCooking()
                        } label: {
                            Text("Finish")
                        }
                        .padding(.horizontal)
                        .tint(Color.purple)
                    }
                }
            }
        }
        .navigationTitle("Cooking")
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
        // Record cooking timestamp
        recipe.cookedAt.append(Date())
        
        // Consume ingredients
        consumeIngredients()
        
        // Reset step index
        recipe.lastStepIndex = 0
        
        // Dismiss view
        dismiss()
    }
    
    // Method to consume ingredients when starting to cook
    private func consumeIngredients() {
        RecipeUtils.consumeRecipeIngredients(recipe: recipe, modelContext: modelContext, foodInventory: food)
    }
}

#Preview {
    RecipeStepByStepView(recipe: RecipeModel(name: "Carbonara"))
} 
