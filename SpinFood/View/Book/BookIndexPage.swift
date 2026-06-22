import SwiftUI

struct BookIndexPage: View {
    let recipes: [RecipeModel]
    var onSelectRecipe: (RecipeModel) -> Void
    var onAdd: () -> Void
    var onSettings: () -> Void
    var onDelete: (RecipeModel) -> Void = { _ in }
    var onMove: (IndexSet, Int) -> Void = { _, _ in }

    @State private var isEditing = false

    private var pageBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .systemBackground
                : UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1)
        })
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                pageBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    if recipes.isEmpty {
                        emptyState
                        Spacer(minLength: 0)
                    } else {
                        recipeList
                    }
                }

                if !isEditing {
                    Text("i")
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(.tertiary)
                        .padding(.bottom, 12)
                }
            }
            .navigationTitle("Index")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        Button("Done") {
                            withAnimation {
                                isEditing = false
                            }
                        }
                    } else {
                        if !recipes.isEmpty {
                            Button("Edit") {
                                withAnimation {
                                    isEditing = true
                                }
                            }
                        }
                    }
                }

                ToolbarItem(placement: .principal) {
                    VStack(spacing: 1) {
                        Text("Index")
                            .font(.title.weight(.bold))
                            .fontDesign(.serif)
                        Text(recipes.isEmpty ? "No recipes yet" : "\(recipes.count) recipe\(recipes.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    if !isEditing {
                        Button(action: onAdd) {
                            Image(systemName: "plus")
                        }
                        
                        Button(action: onSettings) {
                            Image(systemName: "gear")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recipe list

    private var recipeList: some View {
        List {
            ForEach(Array(recipes.enumerated()), id: \.element.id) { index, recipe in
                VStack(spacing: 0) {
                    BookIndexEntry(index: index + 1, recipe: recipe)
                    if index < recipes.count - 1 {
                        Divider()
                            .padding(.leading, 80)
                            .padding(.trailing, 32)
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                .onTapGesture {
                    if !isEditing { onSelectRecipe(recipe) }
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { onDelete(recipes[$0]) }
            }
            .onMove(perform: onMove)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 48)
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 52))
                .foregroundStyle(.secondary.opacity(0.4))

            Text("Your recipe book is empty")
                .font(.system(.title3, design: .serif))

            Text("Tap + to write your first recipe")
                .font(.system(.subheadline, design: .serif))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 72)
    }
}

// MARK: - Index Entry Row

private struct BookIndexEntry: View {
    let index: Int
    let recipe: RecipeModel

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("\(index)")
                .font(.system(size: 15, weight: .light, design: .serif))
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .center)

            thumbnail
                .padding(.trailing, 14)

            VStack(alignment: .leading, spacing: 3) {
                Text(recipe.name)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    if recipe.duration > 0 {
                        Text(recipe.duration.formatted)
                            .font(.system(.caption, design: .serif))
                            .foregroundStyle(.secondary)
                    }
                    if recipe.servings > 0 {
                        Text("·  \(recipe.servings) servings")
                            .font(.system(.caption, design: .serif))
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.light))
                .foregroundStyle(.quaternary)
                .padding(.trailing, 32)
        }
        .padding(.vertical, 13)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = recipe.image, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 50)
                .clipped()
                .padding(3)
                .background(.white)
                .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
        } else {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.1))
                .frame(width: 64, height: 50)
                .overlay {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary.opacity(0.4))
                }
        }
    }
}
