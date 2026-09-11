import Foundation
import Observation

@MainActor
@Observable
final class ProductListViewModel {
    private(set) var state: ProductListState = .loading
    private(set) var isLoadingNextPage = false
    private(set) var nextPageError: String?
    private(set) var hasMorePages = false

    private let service: any ProductServicing
    private let pageSize = 30
    private var nextSkip = 0

    init(service: any ProductServicing) {
        self.service = service
    }

    func load() async {
        // 같은 뷰모델에 목록이 있으면 다시 요청하지 않는다.
        if case .loaded = state { return }

        state = .loading

        do {
            let page = try await service.fetchProducts(limit: pageSize, skip: 0)
            updatePagination(with: page)
            state = .loaded(page.products)
        } catch {
            state = .failed(message: Self.message(for: error))
        }
    }

    func loadNextPageIfNeeded(after productID: Int) async {
        guard case .loaded(let products) = state,
              products.last?.id == productID,
              nextPageError == nil else { return }
        await loadNextPage()
    }

    func loadNextPage() async {
        guard case .loaded(let products) = state,
              hasMorePages,
              !isLoadingNextPage else { return }

        isLoadingNextPage = true
        nextPageError = nil
        defer { isLoadingNextPage = false }

        do {
            let page = try await service.fetchProducts(limit: pageSize, skip: nextSkip)
            updatePagination(with: page)
            state = .loaded(products + page.products)
        } catch {
            // 추가 조회에 실패해도 이미 받은 목록과 다음 조회 위치는 유지한다.
            nextPageError = Self.message(for: error)
        }
    }

    private func updatePagination(with page: ProductPage) {
        nextSkip = page.skip + page.products.count
        // 빈 응답이면 같은 위치를 계속 요청하지 않는다.
        hasMorePages = !page.products.isEmpty && nextSkip < page.total
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
