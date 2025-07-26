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
    
    @Query var recipes: [RecipeModel]
    
    @State var currentIndex: Int = 0
    @State var showEatConfirmation: Bool = false
    
    var recipe: RecipeModel
    
    var steps: [StepRecipe]
        
    var totalSteps: Int {
        if let steps = recipe.steps {
            return steps.count
        } else {
            return 0
        }
    }
    
    var body: some View {
        NavigationStack {
            TabView(selection: $currentIndex, content: {
                ForEach(steps.indices, id: \.self) { index in
                    ScrollView {
                        VStack (alignment: .leading, spacing: 16) {
                            if let imageData = steps[index].image, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, maxHeight: 168)
                                    .clipShape(.rect(cornerRadius: 20))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            Text(steps[index].text)
                                .padding(4)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.bottom, 24)
                    }
                    .tag(index)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
            })
            .navigationTitle(recipe.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if currentIndex == steps.count - 1 {
                            if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                                showEatConfirmation = true
                            }
                        } else {
                            withAnimation {
                                currentIndex = steps.count - 1
                            }
                        }
                    } label: {
                        Text(currentIndex == steps.count - 1 ? "Eat" : "Skip")
                    }
                }
            }
            .sheet(isPresented: $showEatConfirmation, content: {
                if let ingredients = recipe.ingredients, !ingredients.isEmpty {
                    RecipeConfirmEatView(recipe: recipe)
                        .onDisappear() {
                            dismiss()
                            
                            currentIndex = 0
                        }
                }
            })
            .onAppear() {
                currentIndex = recipe.lastStepIndex
            }
            .onDisappear() {
                recipe.lastStepIndex = currentIndex
            }
        }
    }
}

#Preview {
    RecipeStepByStepView(recipe: RecipeModel(name: "Carbonara"), steps: [StepRecipe(text: "Step 1")])
}
