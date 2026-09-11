import Foundation

protocol ProductServicing {
    func fetchProducts(limit: Int, skip: Int) async throws -> ProductPage
    func fetchProduct(id: Int) async throws -> Product
}

actor ProductService: ProductServicing {
    func fetchProducts(limit: Int, skip: Int) async throws -> ProductPage {
        let url = URL(string: "https://dummyjson.com/products?limit=\(limit)&skip=\(skip)")!
        let data = try await fetchData(from: url)
        return try JSONDecoder().decode(ProductPage.self, from: data)
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
