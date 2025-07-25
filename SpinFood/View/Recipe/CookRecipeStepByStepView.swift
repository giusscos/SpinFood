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
    
    @Query var recipes: [RecipeModel]
        
    @State var currentIndex: Int = 0
    @State var showEatConfirmation: Bool = false
    
    var recipe: RecipeModel
    
    var steps: [StepRecipe]
    
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
                                    .frame(maxWidth: .infinity, maxHeight: 300)
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
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .navigationTitle(recipe.name)
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
    CookRecipeStepByStepView(recipe: RecipeModel(name: "Recipe"), steps: [StepRecipe(text: "Step 1")])
}
