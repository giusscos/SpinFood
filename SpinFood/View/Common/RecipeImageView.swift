import SwiftUI

struct RecipeImageView: View {
    var recipe: RecipeModel
    var width: CGFloat?
    var cornerRadius: CGFloat
    
    init(recipe: RecipeModel, width: CGFloat? = nil, cornerRadius: CGFloat = 12) {
        self.recipe = recipe
        self.width = width
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        if let imageData = recipe.image,
           let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: width)
                .frame(height: 200)
                .overlay (alignment: .bottom) {
                    Color.clear
                        .background(.ultraThinMaterial)
                        .frame(maxWidth: .infinity)
                        .mask(
                            LinearGradient(
                                gradient: Gradient(colors: [.black, .black, .clear, .clear, .clear]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .overlay(alignment: .bottom) {
                            VStack (alignment: .leading) {
                                Text(recipe.duration.formatted)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Text(recipe.name)
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .tint(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(8)
                        }
                }
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}

#Preview {
    RecipeImageView(recipe: RecipeModel(name: "Carbonara", duration: 13))
} 
