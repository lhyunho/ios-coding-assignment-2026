import Foundation
import Testing
@testable import ProductAssignment

@MainActor
struct ProductListViewModelTests {
    @Test func successfulLoadStoresProductsAndKeepsThem() async {
        // 준비: 서버 대신 정해진 상품을 반환한다.
        let service = StubProductService()
        let products = [Product(id: 1, title: "상품", price: 10, thumbnail: nil)]
        service.products = products
        let viewModel = ProductListViewModel(service: service)

        // 실행: 상품을 조회한다.
        await viewModel.load()

        // 확인: 받은 상품을 저장하고, 재진입해도 다시 요청하지 않는다.
        #expect(viewModel.state == .loaded(products))
        await viewModel.load()
        #expect(service.requestCount == 1)
    }

    @Test func emptyResponseStoresAnEmptyList() async {
        let service = StubProductService()
        let viewModel = ProductListViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.state == .loaded([]))
    }

    @Test func failedLoadShowsAnError() async {
        let service = StubProductService()
        service.error = URLError(.notConnectedToInternet)
        let viewModel = ProductListViewModel(service: service)

        await viewModel.load()

        #expect(viewModel.state == .failed(
            message: "인터넷 연결을 확인한 뒤 다시 시도해 주세요."
        ))
    }

    @Test func retryCanLoadProductsAfterFailure() async {
        let service = StubProductService()
        service.error = URLError(.notConnectedToInternet)
        let viewModel = ProductListViewModel(service: service)
        await viewModel.load()

        // 연결이 복구된 상황을 만든 뒤 다시 조회한다.
        service.error = nil
        let products = [Product(id: 1, title: "상품", price: 10, thumbnail: nil)]
        service.products = products
        await viewModel.load()

        #expect(viewModel.state == .loaded(products))
        #expect(service.requestCount == 2)
    }
}

// 실제 통신 없이 테스트에서 지정한 상품이나 오류를 돌려준다.
@MainActor
private final class StubProductService: ProductServicing {
    var products: [Product] = []
    var error: URLError?
    var requestCount = 0

    @MainActor
    func fetchProducts() async throws -> [Product] {
        requestCount += 1
        if let error {
            throw error
        }
        return products
    }
}
