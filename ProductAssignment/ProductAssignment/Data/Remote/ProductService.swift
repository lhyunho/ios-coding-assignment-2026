import Foundation

protocol ProductServicing {
    func fetchProducts() async throws -> [Product]
    func fetchProduct(id: Int) async throws -> Product
}

actor ProductService: ProductServicing {
    func fetchProducts() async throws -> [Product] {
        let url = URL(string: "https://dummyjson.com/products")!
        let data = try await fetchData(from: url)
        return try JSONDecoder().decode(ProductListResponse.self, from: data).products
    }

    func fetchProduct(id: Int) async throws -> Product {
        let url = URL(string: "https://dummyjson.com/products/\(id)")!
        let data = try await fetchData(from: url)
        return try JSONDecoder().decode(Product.self, from: data)
    }

    private func fetchData(from url: URL) async throws -> Data {
        let request = URLRequest(url: url)
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let response = response as? HTTPURLResponse else {
            throw ProductServiceError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw ProductServiceError.httpStatus(response.statusCode)
        }

        return data
    }
}

enum ProductServiceError: Error {
    case invalidResponse
    case httpStatus(Int)
}

nonisolated private struct ProductListResponse: Decodable {
    let products: [Product]
}
