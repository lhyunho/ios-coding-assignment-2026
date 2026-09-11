import Foundation
import Observation

@MainActor
@Observable
final class ProductDetailViewModel {
    private(set) var state: ProductDetailState = .loading

    private let productID: Int
    private let service: any ProductServicing

    init(productID: Int, service: any ProductServicing) {
        self.productID = productID
        self.service = service
    }

    func load() async {
        if case .loaded = state { return }

        state = .loading

        do {
            let product = try await service.fetchProduct(id: productID)
            state = .loaded(product)
        } catch {
            state = .failed(message: Self.message(for: error))
        }
    }

    private static func message(for error: any Error) -> String {
        if let serviceError = error as? ProductServiceError,
           case .httpStatus(404) = serviceError {
            return "상품을 찾을 수 없어요. 목록으로 돌아가 다른 상품을 선택해 주세요."
        }

        switch (error as? URLError)?.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return "인터넷 연결을 확인한 뒤 다시 시도해 주세요."
        case .timedOut:
            return "응답이 지연되고 있어요. 잠시 후 다시 시도해 주세요."
        default:
            return "상품을 불러오지 못했어요. 잠시 후 다시 시도해 주세요."
        }
    }
}

enum ProductDetailState: Equatable {
    case loading
    case loaded(Product)
    case failed(message: String)
}
