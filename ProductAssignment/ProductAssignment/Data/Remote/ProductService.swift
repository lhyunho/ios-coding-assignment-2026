import Foundation

protocol ProductServicing {
    func fetchProducts() async throws -> [Product]
}

actor ProductService: ProductServicing {
    func fetchProducts() async throws -> [Product] {
        let url = URL(string: "https://dummyjson.com/products")!
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse else {
            throw ProductServiceError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw ProductServiceError.httpStatus(response.statusCode)
        }

        return try JSONDecoder().decode(ProductListResponse.self, from: data).products
    }
}

enum ProductServiceError: Error {
    case invalidResponse
    case httpStatus(Int)
}

nonisolated private struct ProductListResponse: Decodable {
    let products: [Product]
}
