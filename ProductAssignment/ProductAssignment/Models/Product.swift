import Foundation

nonisolated struct Product: Decodable, Identifiable, Equatable {
    let id: Int
    let title: String?
    let price: Decimal?
    let thumbnail: URL?
    let description: String?
}
