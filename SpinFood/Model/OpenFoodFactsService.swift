import Foundation

struct OpenFoodFactsProduct: Equatable {
    var barcode: String
    var name: String
    var brand: String?
    var quantityText: String?
    var parsedQuantity: Decimal?
    var imageURL: URL?
    var category: FoodCategory
    var unit: FoodUnit
    var emoji: String
}

enum OpenFoodFactsError: LocalizedError {
    case notFound
    case network
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .notFound: return String(localized: "Product not found")
        case .network: return String(localized: "Network error. Check your connection.")
        case .invalidResponse: return String(localized: "Could not read product data.")
        }
    }
}

enum OpenFoodFactsService {
    private static let cacheKey = "barcodeLookupCache"

    static func lookup(barcode: String) async throws -> OpenFoodFactsProduct {
        if let cached = cachedProduct(for: barcode) {
            return cached
        }

        let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json")!
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw OpenFoodFactsError.network
        }

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw OpenFoodFactsError.network
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? Int else {
            throw OpenFoodFactsError.invalidResponse
        }

        guard status == 1, let product = json["product"] as? [String: Any] else {
            throw OpenFoodFactsError.notFound
        }

        let name = (product["product_name"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackName = (product["generic_name"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedName = [name, fallbackName].compactMap { $0 }.first { !$0.isEmpty } ?? barcode

        let brand = (product["brands"] as? String)?
            .split(separator: ",")
            .first
            .map(String.init)?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let quantityText = product["quantity"] as? String
        let categories = (product["categories_tags"] as? [String]) ?? []
        let mappedCategory = mapCategory(tags: categories)
        let mappedUnit = mapUnit(quantityText: quantityText, categories: categories)
        let parsedQuantity = parseQuantity(from: quantityText)

        let imageURL = (product["image_front_small_url"] as? String).flatMap { URL(string: $0) }
            ?? (product["image_front_url"] as? String).flatMap { URL(string: $0) }
            ?? (product["image_url"] as? String).flatMap { URL(string: $0) }

        let result = OpenFoodFactsProduct(
            barcode: barcode,
            name: resolvedName,
            brand: brand?.isEmpty == true ? nil : brand,
            quantityText: quantityText,
            parsedQuantity: parsedQuantity,
            imageURL: imageURL,
            category: mappedCategory,
            unit: mappedUnit,
            emoji: mappedCategory.defaultEmoji
        )
        cache(result)
        return result
    }

    // MARK: - Mapping

    private static func mapCategory(tags: [String]) -> FoodCategory {
        let joined = tags.joined(separator: " ").lowercased()
        if joined.contains("en:beverages") || joined.contains("drink") { return .beverages }
        if joined.contains("en:dairy") || joined.contains("cheese") || joined.contains("milk") { return .dairy }
        if joined.contains("en:meats") || joined.contains("meat") || joined.contains("poultry") { return .meat }
        if joined.contains("en:seafood") || joined.contains("fish") || joined.contains("seafood") { return .seafood }
        if joined.contains("en:frozen") { return .frozen }
        if joined.contains("en:fruits") || joined.contains("en:vegetables") || joined.contains("produce") { return .produce }
        if joined.contains("en:cereals") || joined.contains("bread") || joined.contains("pasta") || joined.contains("rice") { return .grains }
        if joined.contains("en:snacks") || joined.contains("biscuit") || joined.contains("candy") { return .snacks }
        if joined.contains("en:plant-based-foods") || joined.contains("grocery") || joined.contains("condiment") { return .pantry }
        return .other
    }

    private static func mapUnit(quantityText: String?, categories: [String]) -> FoodUnit {
        let text = (quantityText ?? "").lowercased()
        if text.contains("ml") || text.contains("cl") { return .milliliter }
        if text.contains("l") && !text.contains("lb") { return .liter }
        if text.contains("kg") { return .kilogram }
        if text.contains("g") { return .gram }
        if text.contains("pcs") || text.contains("pieces") || text.contains("x") { return .piece }

        let joined = categories.joined(separator: " ").lowercased()
        if joined.contains("beverage") || joined.contains("drink") || joined.contains("milk") {
            return .milliliter
        }
        return .piece
    }

    // Extracts the leading numeric value from a quantity string like "500 g" or "1.5 l".
    private static func parseQuantity(from text: String?) -> Decimal? {
        guard let text, !text.isEmpty else { return nil }
        guard let range = text.range(of: #"(\d+(?:[.,]\d+)?)"#, options: .regularExpression) else { return nil }
        let numberStr = String(text[range]).replacingOccurrences(of: ",", with: ".")
        return Decimal(string: numberStr)
    }

    // MARK: - Cache

    private static func cachedProduct(for barcode: String) -> OpenFoodFactsProduct? {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let cache = try? JSONDecoder().decode([String: CachedProduct].self, from: data),
              let item = cache[barcode] else { return nil }
        return item.asProduct
    }

    private static func cache(_ product: OpenFoodFactsProduct) {
        var cache: [String: CachedProduct] = [:]
        if let data = UserDefaults.standard.data(forKey: cacheKey),
           let existing = try? JSONDecoder().decode([String: CachedProduct].self, from: data) {
            cache = existing
        }
        cache[product.barcode] = CachedProduct(product)
        if let data = try? JSONEncoder().encode(cache) {
            UserDefaults.standard.set(data, forKey: cacheKey)
        }
    }
}

private struct CachedProduct: Codable {
    var barcode: String
    var name: String
    var brand: String?
    var quantityText: String?
    var parsedQuantity: Decimal?
    var imageURL: URL?
    var categoryRaw: String
    var unitRaw: String
    var emoji: String

    init(_ product: OpenFoodFactsProduct) {
        barcode = product.barcode
        name = product.name
        brand = product.brand
        quantityText = product.quantityText
        parsedQuantity = product.parsedQuantity
        imageURL = product.imageURL
        categoryRaw = product.category.rawValue
        unitRaw = product.unit.rawValue
        emoji = product.emoji
    }

    var asProduct: OpenFoodFactsProduct {
        OpenFoodFactsProduct(
            barcode: barcode,
            name: name,
            brand: brand,
            quantityText: quantityText,
            parsedQuantity: parsedQuantity,
            imageURL: imageURL,
            category: FoodCategory(rawValue: categoryRaw) ?? .other,
            unit: FoodUnit(rawValue: unitRaw) ?? .piece,
            emoji: emoji
        )
    }
}
