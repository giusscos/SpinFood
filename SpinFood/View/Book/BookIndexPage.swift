import SwiftUI
import SwiftData
import TipKit
import UniformTypeIdentifiers

struct BookIndexPage: View {
    let recipes: [RecipeModel]
    var onSelectRecipe: (RecipeModel) -> Void
    var onAdd: () -> Void
    var onSettings: () -> Void
    var onEdit: (RecipeModel) -> Void = { _ in }
    var onDelete: (RecipeModel) -> Void = { _ in }
    var onMove: (IndexSet, Int) -> Void = { _, _ in }

    private let addFirstRecipeTip = AddFirstRecipeTip()

    @Environment(\.modelContext) private var modelContext

    @State private var isEditing = false
    @State private var filterDifficulty: RecipeDifficulty? = nil
    @State private var filterTags: Set<RecipeTag> = []
    @State private var showImport = false
    @State private var importErrorMessage: String? = nil

    private var pageBackground: Color {
        Color(UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? .systemBackground
                : UIColor(red: 0.97, green: 0.95, blue: 0.90, alpha: 1)
        })
    }

    private var isFiltering: Bool {
        filterDifficulty != nil || !filterTags.isEmpty
    }

    private var displayedRecipes: [RecipeModel] {
        recipes.filter { recipe in
            let difficultyOK = filterDifficulty == nil || recipe.difficulty == filterDifficulty
            let tagsOK = filterTags.isEmpty || filterTags.isSubset(of: Set(recipe.tags))
            return difficultyOK && tagsOK
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                pageBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    if recipes.isEmpty {
                        emptyState
                        Spacer(minLength: 0)
                    } else if displayedRecipes.isEmpty {
                        noResultsState
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
            .onAppear {
                AddFirstRecipeTip.hasRecipes = !recipes.isEmpty
            }
            .onChange(of: recipes.isEmpty) { _, isEmpty in
                AddFirstRecipeTip.hasRecipes = !isEmpty
            }
            .fileImporter(
                isPresented: $showImport,
                allowedContentTypes: [.data],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    do {
                        try RecipeTransfer.import(from: url, into: modelContext)
                    } catch {
                        importErrorMessage = error.localizedDescription
                    }
                case .failure(let error):
                    importErrorMessage = error.localizedDescription
                }
            }
            .alert("Import Failed", isPresented: Binding(
                get: { importErrorMessage != nil },
                set: { if !$0 { importErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { importErrorMessage = nil }
            } message: {
                Text(importErrorMessage ?? "")
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditing {
                        Button("Done") {
                            withAnimation { isEditing = false }
                        }
                    } else {
                        if !recipes.isEmpty {
                            Button("Edit") {
                                withAnimation { isEditing = true }
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
                        Button(action: {
                            addFirstRecipeTip.invalidate(reason: .actionPerformed)
                            onAdd()
                        }) {
                            Image(systemName: "plus")
                        }
                        .popoverTip(addFirstRecipeTip)

                        Menu {
                            if !recipes.isEmpty {
                                Menu {
                                    Button {
                                        filterDifficulty = nil
                                    } label: {
                                        Label("All", systemImage: filterDifficulty == nil ? "checkmark" : "circle")
                                    }
                                    ForEach(RecipeDifficulty.allCases, id: \.self) { d in
                                        Button {
                                            filterDifficulty = filterDifficulty == d ? nil : d
                                        } label: {
                                            Label(d.localizedName, systemImage: filterDifficulty == d ? "checkmark" : d.icon)
                                        }
                                    }
                                } label: {
                                    Label("Difficulty", systemImage: filterDifficulty != nil ? "gauge.medium.badge.plus" : "gauge.medium")
                                }

                                Menu {
                                    ForEach(RecipeTag.allCases, id: \.self) { tag in
                                        Button {
                                            if filterTags.contains(tag) {
                                                filterTags.remove(tag)
                                            } else {
                                                filterTags.insert(tag)
                                            }
                                        } label: {
                                            Label(tag.localizedName, systemImage: filterTags.contains(tag) ? "checkmark" : tag.icon)
                                        }
                                    }
                                } label: {
                                    Label("Tags", systemImage: filterTags.isEmpty ? "tag" : "tag.fill")
                                }

                                if isFiltering {
                                    Button(role: .destructive) {
                                        filterDifficulty = nil
                                        filterTags.removeAll()
                                    } label: {
                                        Label("Clear Filters", systemImage: "xmark.circle")
                                    }
                                }
                            }

                            Section {
                                Button {
                                    showImport = true
                                } label: {
                                    Label("Import Recipe", systemImage: "square.and.arrow.down")
                                }

                                Button(action: onSettings) {
                                    Label("Settings", systemImage: "gear")
                                }
                            }
                        } label: {
                            Image(systemName: isFiltering ? "ellipsis.circle.fill" : "ellipsis.circle")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recipe list

    private var recipeList: some View {
        List {
            if isFiltering {
                Section {
                    activeFiltersRow
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            ForEach(Array(displayedRecipes.enumerated()), id: \.element.id) { index, recipe in
                VStack(spacing: 0) {
                    BookIndexEntry(index: index + 1, recipe: recipe)
                    if index < displayedRecipes.count - 1 {
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
                .contextMenu {
                    Button {
                        onEdit(recipe)
                    } label: {
                        Label("Edit Recipe", systemImage: "pencil")
                    }
                    Divider()
                    Button(role: .destructive) {
                        withAnimation { onDelete(recipe) }
                    } label: {
                        Label("Delete Recipe", systemImage: "trash")
                    }
                }
            }
            .onDelete { indexSet in
                indexSet.forEach { onDelete(displayedRecipes[$0]) }
            }
            .onMove(perform: isFiltering ? nil : onMove)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(isEditing ? .active : .inactive))
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 48)
        }
    }

    private var activeFiltersRow: some View {
        HStack(spacing: 8) {
            if let d = filterDifficulty {
                HStack(spacing: 4) {
                    Image(systemName: d.icon)
                    Text(d.localizedName)
                }
                .font(.system(.caption, design: .rounded).weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.12))
                .foregroundStyle(.orange)
                .clipShape(.capsule)
            }
            ForEach(Array(filterTags), id: \.self) { tag in
                HStack(spacing: 4) {
                    Image(systemName: tag.icon)
                    Text(tag.localizedName)
                }
                .font(.system(.caption, design: .rounded).weight(.medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .foregroundStyle(Color.accentColor)
                .clipShape(.capsule)
            }
            Spacer()
            Text("\(displayedRecipes.count) result\(displayedRecipes.count == 1 ? "" : "s")")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
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

    private var noResultsState: some View {
        VStack(spacing: 16) {
            Image(systemName: "line.3.horizontal.decrease.circle")
                .font(.system(size: 52))
                .foregroundStyle(.secondary.opacity(0.4))

            Text("No matching recipes")
                .font(.system(.title3, design: .serif))

            Button("Clear Filters") {
                filterDifficulty = nil
                filterTags.removeAll()
            }
            .font(.system(.subheadline, design: .serif))
            .foregroundStyle(Color.accentColor)
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
                    if let d = recipe.difficulty {
                        Label(d.localizedName, systemImage: d.icon)
                            .font(.system(.caption, design: .serif))
                            .foregroundStyle(.orange)
                    }
                }

                if !recipe.tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(recipe.tags.prefix(3), id: \.self) { tag in
                            Text(tag.localizedName)
                                .font(.system(size: 9, design: .rounded).weight(.medium))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundStyle(Color.accentColor)
                                .clipShape(.capsule)
                        }
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
