import Foundation
import Testing
@testable import ProductAssignment

@MainActor
struct ProductDetailViewModelTests {
    @Test func loadsDetailUsingSelectedProductID() async {
        let service = StubProductDetailService()
        let viewModel = ProductDetailViewModel(productID: 7, service: service)

        await viewModel.load()

        #expect(service.requestedIDs == [7])
        #expect(viewModel.state == .loaded(service.product))
    }

    @Test func missingProductShowsAnError() async {
        let service = StubProductDetailService()
        service.error = ProductServiceError.httpStatus(404)
        let viewModel = ProductDetailViewModel(productID: 7, service: service)

        await viewModel.load()

        #expect(viewModel.state == .failed(
            message: "상품을 찾을 수 없어요. 목록으로 돌아가 다른 상품을 선택해 주세요."
        ))
    }

    @Test func retryLoadsDetailAfterConnectionRecovers() async {
        let service = StubProductDetailService()
        service.error = URLError(.notConnectedToInternet)
        let viewModel = ProductDetailViewModel(productID: 7, service: service)

        await viewModel.load()
        #expect(viewModel.state == .failed(
            message: "인터넷 연결을 확인한 뒤 다시 시도해 주세요."
        ))

        service.error = nil
        await viewModel.load()

        #expect(viewModel.state == .loaded(service.product))
        #expect(service.requestedIDs == [7, 7])
    }
}

@MainActor
private final class StubProductDetailService: ProductServicing {
    let product = Product(id: 7, title: "상품", price: 10, thumbnail: nil, description: "상품 설명")
    var error: (any Error)?
    var requestedIDs: [Int] = []

    @MainActor
    func fetchProducts() async throws -> [Product] {
        [product]
    }

    @MainActor
    func fetchProduct(id: Int) async throws -> Product {
        requestedIDs.append(id)
        if let error { throw error }
        return product
    }
}
