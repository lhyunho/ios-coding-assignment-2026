import Foundation
import Observation

@MainActor
@Observable
final class ProductListViewModel {
    private(set) var state: ProductListState = .loading

    private let service: any ProductServicing

    init(service: any ProductServicing) {
        self.service = service
    }

    func load() async {
        // 같은 뷰모델에 목록이 있으면 다시 요청하지 않는다.
        if case .loaded = state { return }

        state = .loading

        do {
            let products = try await service.fetchProducts()
            state = .loaded(products)
        } catch {
            state = .failed(message: Self.message(for: error))
        }
    }

    private static func message(for error: any Error) -> String {
        switch (error as? URLError)?.code {
        case .notConnectedToInternet, .networkConnectionLost:
            "인터넷 연결을 확인한 뒤 다시 시도해 주세요."
        case .timedOut:
            "응답이 지연되고 있어요. 잠시 후 다시 시도해 주세요."
        default:
            "상품을 불러오지 못했어요. 잠시 후 다시 시도해 주세요."
        }
    }
}

enum ProductListState: Equatable {
    case loading
    case loaded([Product])
    case failed(message: String)
}
