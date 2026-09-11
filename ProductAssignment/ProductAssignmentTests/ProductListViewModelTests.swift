import Foundation
import Testing
@testable import ProductAssignment

@MainActor
struct ProductListViewModelTests {
    @Test func successfulLoadStoresProductsAndKeepsThem() async {
        // 준비: 서버 대신 정해진 상품을 반환한다.
        let service = StubProductService()
        let products = [Product(id: 1, title: "상품", price: 10, thumbnail: nil, description: nil)]
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
        let products = [Product(id: 1, title: "상품", price: 10, thumbnail: nil, description: nil)]
        service.products = products
        await viewModel.load()

        #expect(viewModel.state == .loaded(products))
        #expect(service.requestCount == 2)
    }

    @Test func loadsAllPagesAndStopsAtTheTotal() async {
        let service = StubProductService()
        service.products = makeProducts(count: 194)
        let viewModel = ProductListViewModel(service: service)

        await viewModel.load()
        #expect(viewModel.state == .loaded(Array(service.products.prefix(30))))
        for _ in 0..<6 {
            await viewModel.loadNextPage()
        }
        // 마지막 14개를 받은 뒤에는 더 요청하지 않는다.
        await viewModel.loadNextPage()

        #expect(viewModel.state == .loaded(service.products))
        #expect(service.requestedSkips == [0, 30, 60, 90, 120, 150, 180])
        #expect(service.requestedLimits == Array(repeating: 30, count: 7))
        #expect(!viewModel.hasMorePages)
        #expect(!viewModel.isLoadingNextPage)
    }

    @Test func onlyTheLastProductLoadsMoreAndDuplicateRequestsArePrevented() async {
        let service = StubProductService()
        service.products = makeProducts(count: 60)
        let viewModel = ProductListViewModel(service: service)
        await viewModel.load()

        await viewModel.loadNextPageIfNeeded(after: 1)
        #expect(service.requestedSkips == [0])

        // 응답을 기다리는 중 보기 방식이 바뀌어 마지막 항목이 다시 나타난 상황.
        service.delay = .milliseconds(30)
        async let first: Void = viewModel.loadNextPageIfNeeded(after: 30)
        async let second: Void = viewModel.loadNextPageIfNeeded(after: 30)
        _ = await (first, second)

        #expect(service.requestedSkips == [0, 30])
        #expect(viewModel.state == .loaded(service.products))
    }

    @Test func nextPageFailureKeepsProductsAndRetriesTheSameOffset() async {
        let service = StubProductService()
        service.products = makeProducts(count: 60)
        let viewModel = ProductListViewModel(service: service)
        await viewModel.load()
        service.error = URLError(.notConnectedToInternet)

        await viewModel.loadNextPage()

        #expect(viewModel.state == .loaded(Array(service.products.prefix(30))))
        #expect(viewModel.nextPageError == "인터넷 연결을 확인한 뒤 다시 시도해 주세요.")
        #expect(!viewModel.isLoadingNextPage)
        #expect(viewModel.hasMorePages)
        // 실패 후 스크롤·보기 전환만으로 재시도를 반복하지 않는다.
        await viewModel.loadNextPageIfNeeded(after: 30)
        #expect(service.requestedSkips == [0, 30])

        service.error = nil
        await viewModel.loadNextPage()

        #expect(viewModel.state == .loaded(service.products))
        #expect(service.requestedSkips == [0, 30, 30])
        #expect(viewModel.nextPageError == nil)
    }

    @Test func anEmptyPageStopsFurtherRequests() async {
        let service = StubProductService()
        service.products = makeProducts(count: 30)
        service.reportedTotal = 60
        let viewModel = ProductListViewModel(service: service)
        await viewModel.load()

        await viewModel.loadNextPage()
        await viewModel.loadNextPage()

        #expect(viewModel.state == .loaded(service.products))
        #expect(!viewModel.hasMorePages)
        #expect(service.requestedSkips == [0, 30])
    }

    private func makeProducts(count: Int) -> [Product] {
        (1...count).map {
            Product(id: $0, title: "상품 \($0)", price: 10, thumbnail: nil, description: nil)
        }
    }
}

// 실제 통신 없이 테스트에서 지정한 상품이나 오류를 돌려준다.
@MainActor
private final class StubProductService: ProductServicing {
    var products: [Product] = []
    var error: URLError?
    var reportedTotal: Int?
    var delay: Duration?
    var requestedSkips: [Int] = []
    var requestedLimits: [Int] = []
    var requestCount: Int { requestedSkips.count }

    @MainActor
    func fetchProducts(limit: Int, skip: Int) async throws -> ProductPage {
        requestedSkips.append(skip)
        requestedLimits.append(limit)
        if let delay { try await Task.sleep(for: delay) }
        if let error {
            throw error
        }
        return ProductPage(
            products: Array(products.dropFirst(skip).prefix(limit)),
            total: reportedTotal ?? products.count,
            skip: skip
        )
    }

    @MainActor
    func fetchProduct(id: Int) async throws -> Product {
        guard let product = products.first(where: { $0.id == id }) else {
            throw ProductServiceError.httpStatus(404)
        }
        return product
    }
}
