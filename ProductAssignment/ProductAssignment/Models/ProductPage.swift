nonisolated struct ProductPage: Decodable {
    let products: [Product]
    let total: Int
    let skip: Int
}
