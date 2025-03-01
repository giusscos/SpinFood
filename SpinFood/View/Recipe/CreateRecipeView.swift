//
//  CreateRecipeView.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 11/12/24.
//

import SwiftUI
import SwiftData
import PhotosUI

struct CreateRecipeView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Query var foods: [FoodModal]
    
    @State private var name: String = ""
    @State private var descriptionRecipe: String = ""
    @State private var duration: TimeInterval = 300.0
    @State private var ingredients: [RecipeFoodModal] = []
    @State private var steps: [String] = []
    @State private var imageItem: PhotosPickerItem? = nil
    @State private var imageData: Data? = nil
    
    @State private var newStep: String = ""
    
    @State private var selectedFood: FoodModal? = nil
    @State private var quantityNeeded: Decimal = 0.0
    
    var gradientBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [.purple, .indigo]),
            startPoint: .topLeading,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    var background: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .overlay {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .black.opacity(1),
                                .black.opacity(0.5),
                                .clear,
                                .clear
                            ]),
                            startPoint: .bottom,
                            endPoint: .center
                        )
                    }
            } else {
                gradientBackground
            }
        }
        .ignoresSafeArea()
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    if imageData == nil {
                        PhotosPicker(
                            selection: $imageItem,
                            matching: .images,
                            photoLibrary: .shared()) {
                                Group {
                                    VStack {
                                        Image(systemName: "photo")
                                            .font(.largeTitle)
                                            .foregroundColor(Color.white.opacity(0.6))
                                            .padding()
                                            .background(.ultraThinMaterial)
                                            .clipShape(Circle())
                                        
                                        Text("Add Photo")
                                            .foregroundColor(.white)
                                            .font(.headline)
                                            .padding(.vertical, 8)
                                            .padding(.horizontal)
                                            .background(.ultraThinMaterial)
                                            .clipShape(Capsule())
                                    }
                                    .frame(height: 250)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                }
                            }
                            .padding(.horizontal)
                    }
                        
                    if imageData != nil {
                        Menu {
                            Button(role: .destructive) {
                                withAnimation(.smooth) {
                                    imageItem = nil
                                    self.imageData = nil
                                }
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                            
                            PhotosPicker(selection: $imageItem,
                                       matching: .images,
                                       photoLibrary: .shared()) {
                                Label("Update", systemImage: "photo")
                            }
                        } label: {
                            Label("Edit photo", systemImage: "ellipsis")
                                .labelStyle(.titleOnly)
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                                .tint(.white)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        .frame(height: 250)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top)
                    }
                }
                .task(id: imageItem) {
                    if let data = try? await imageItem?.loadTransferable(type: Data.self) {
                        withAnimation(.smooth) {
                            imageData = data
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
                
                Section {
                    VStack(spacing: 25) {
                        VStack {
                            TextField("Name", text: $name)
                                .font(.title)
                                .foregroundColor(.white)
                            
                            Divider()
                            
                            TimePickerView(duration: $duration)
                            
                            Divider()
                            
                            TextEditor(text: $descriptionRecipe)
                                .scrollContentBackground(.hidden)
                                .background(Color.clear)
                                .frame(height: 100)
                                .overlay(alignment: .topLeading, content: {
                                    VStack {
                                        if descriptionRecipe.isEmpty {
                                            Text("Add a recipe description...")
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    }
                                })
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        
                        
                        if !foods.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Ingredients", systemImage: "list.bullet")
                                    .labelStyle(.titleOnly)
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                if !ingredients.isEmpty {
                                    ForEach(ingredients) { ingredient in
                                        if let ingredientInfo = ingredient.ingredient {
                                            HStack {
                                                Text(ingredientInfo.name)
                                                    .foregroundColor(.white)
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                
                                                Text("\(ingredient.quantityNeeded) \(ingredientInfo.unit.abbreviation)")
                                                    .foregroundColor(.white.opacity(0.8))
                                            }
                                            .padding(.vertical, 4)
                                        }
                                    }
                                    .onDelete { indexSet in
                                        ingredients.remove(atOffsets: indexSet)
                                    }
                                }
                                
                                HStack {
                                    Picker("Select Ingredient", selection: $selectedFood) {
                                        ForEach(foods) { value in
                                            Text(value.name)
                                                .tag(value as FoodModal?)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(.white)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 15))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    if selectedFood != nil {
                                        TextField("Quantity", value: $quantityNeeded, format: .number)
                                            .keyboardType(.decimalPad)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(.ultraThinMaterial)
                                            .clipShape(RoundedRectangle(cornerRadius: 15))
                                            .frame(width: 100)
                                    }
                                    
                                    Button {
                                        guard let food = selectedFood, quantityNeeded > 0 else { return }
                                        
                                        let newIngredient = RecipeFoodModal(ingredient: food, quantityNeeded: quantityNeeded)
                                        
                                        withAnimation {
                                            ingredients.append(newIngredient)
                                        }
                                        
                                        selectedFood = foods.first
                                        quantityNeeded = 0.0
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.white)
                                            .font(.title2)
                                    }
                                    .disabled(quantityNeeded == 0.0)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            VStack {
                                Label("Steps", systemImage: "list.number")
                                    .labelStyle(.titleOnly)
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                ForEach(steps, id: \.self) { step in
                                    Text(step)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 4)
                                }
                                .onDelete { indexSet in
                                    steps.remove(atOffsets: indexSet)
                                }
                            }
                            .padding(.horizontal, 8)
                            
                            HStack {
                                TextEditor(text: $newStep)
                                    .scrollContentBackground(.hidden)
                                    .background(Color.clear)
                                    .frame(height: 80)
                                    .padding()
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 24))
                                    .overlay(alignment: .topLeading, content: {
                                        VStack {
                                            if descriptionRecipe.isEmpty {
                                                Text("Add a step...")
                                                    .foregroundColor(.white.opacity(0.5))
                                                    .padding()
                                            }
                                        }
                                    })
                                
                                Button {
                                    guard !newStep.isEmpty else { return }
                                    
                                    withAnimation {
                                        steps.append(newStep)
                                    }
                                    
                                    newStep = ""
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.white)
                                        .font(.title2)
                                }
                                .disabled(newStep.isEmpty)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                    }
                    .padding()
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .padding()
            .background(background)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        undoAndClose()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .font(.title)
                            .bold()
                            .foregroundStyle(.white, .ultraThinMaterial)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveRecipe()
                    } label: {
                        Text("Save")
                            .foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
            }
            .ignoresSafeArea()
        }
        .onAppear {
            selectedFood = foods.first
        }
    }
    
    func undoAndClose() {
        dismiss()
    }
    
    func saveRecipe() {
        let newRecipe = RecipeModal(
            name: name,
            descriptionRecipe: descriptionRecipe,
            image: imageData,
            ingredients: ingredients,
            steps: steps,
            duration: duration
        )
        
        newRecipe.rating = 0
        
        modelContext.insert(newRecipe)
        
        dismiss()
    }
}

#Preview {
    CreateRecipeView()
}
