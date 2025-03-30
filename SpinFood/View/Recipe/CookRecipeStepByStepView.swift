//
//  CookRecipeStepByStepView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 10/12/24.
//

import SwiftUI
import SwiftData

struct CookRecipeStepByStepView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Bindable var recipe: RecipeModel
    var onComplete: () -> Void
    
    @State private var currentStepIndex: Int
    
    // Computed properties
    private var hasSteps: Bool {
        return !recipe.stepInstructions.isEmpty
    }
    
    private var currentStepInstructions: String? {
        guard hasSteps && currentStepIndex < recipe.stepInstructions.count else { return nil }
        return recipe.stepInstructions[currentStepIndex]
    }
    
    private var currentStepImage: Data? {
        guard hasSteps && currentStepIndex < recipe.stepImages.count else { return nil }
        return recipe.stepImages[currentStepIndex]
    }
    
    private var isLastStep: Bool {
        return currentStepIndex == recipe.stepInstructions.count - 1
    }
    
    private var isFirstStep: Bool {
        return currentStepIndex == 0
    }
    
    init(recipe: RecipeModel, onComplete: @escaping () -> Void) {
        self.recipe = recipe
        self.onComplete = onComplete
        // Initialize with the last visited step or 0
        self._currentStepIndex = State(initialValue: recipe.lastStepIndex)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if !hasSteps {
                    ContentUnavailableView("No Steps Available", systemImage: "list.bullet.clipboard", description: Text("This recipe doesn't have any steps."))
                } else if let instructions = currentStepInstructions {
                    Text("Step \(currentStepIndex + 1) of \(recipe.stepInstructions.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ProgressView(value: Double(currentStepIndex + 1), total: Double(recipe.stepInstructions.count))
                        .padding()
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Step image
                            if let imageData = currentStepImage, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                            }
                            
                            // Step description
                            Text(instructions)
                                .font(.body)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(recipe.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        currentStepIndex = recipe.stepInstructions.count - 1
                        recipe.lastStepIndex = currentStepIndex
                    } label: {
                        Label("Skip to End", systemImage: "forward.end.fill")
                            .font(.subheadline)
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        Button {
                            if currentStepIndex > 0 {
                                withAnimation {
                                    currentStepIndex -= 1
                                    recipe.lastStepIndex = currentStepIndex
                                }
                            }
                        } label: {
                            Label("Previous", systemImage: "arrow.left.circle.fill")
                                .labelStyle(.iconOnly)
                                .font(.title)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .disabled(isFirstStep)
                        .foregroundStyle(isFirstStep ? .secondary : Color.accentColor)
                        
                        if isLastStep {
                            Button {
                                // Instead of showing a local sheet, use the passed completion handler
                                dismiss()
                                onComplete()
                            } label: {
                                Label("Complete", systemImage: "checkmark.circle.fill")
                                    .labelStyle(.iconOnly)
                                    .font(.title)
                            }
                            .foregroundStyle(Color.purple)
                        } else {
                            Button {
                                withAnimation {
                                    currentStepIndex += 1
                                    recipe.lastStepIndex = currentStepIndex
                                }
                            } label: {
                                Label("Next", systemImage: "arrow.right.circle.fill")
                                    .labelStyle(.iconOnly)
                                    .font(.title)
                            }
                        }
                    }
                }
            }
            .onChange(of: currentStepIndex) { _, newValue in
                // Save progress
                recipe.lastStepIndex = newValue
            }
        }
    }
}

#Preview {
    let recipe = RecipeModel(name: "Pasta")
    recipe.addStep(instructions: "Boil water with salt")
    recipe.addStep(instructions: "Add pasta and cook for 8-10 minutes")
    recipe.addStep(instructions: "Drain and serve")
    
    return CookRecipeStepByStepView(recipe: recipe, onComplete: {})
} 
