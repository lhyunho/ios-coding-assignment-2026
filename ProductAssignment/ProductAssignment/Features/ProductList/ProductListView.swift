import SwiftUI

struct ProductListView: View {
    @State private var viewModel: ProductListViewModel
    let favoriteStore: FavoriteStore

    init(service: any ProductServicing, favoriteStore: FavoriteStore) {
        _viewModel = State(initialValue: ProductListViewModel(service: service))
        self.favoriteStore = favoriteStore
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("상품")
                .task {
                    await viewModel.load()
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("상품을 불러오는 중…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let products):
            if products.isEmpty {
                ContentUnavailableView(
                    "상품이 없어요",
                    systemImage: "shippingbox",
                    description: Text("등록된 상품이 없습니다.")
                )
            } else {
                List(products) { product in
                    ProductRowView(
                        product: product,
                        isFavorite: favoriteStore.isFavorite(product.id),
                        onToggleFavorite: { favoriteStore.toggle(product.id) }
                    )
                }
                .listStyle(.plain)
            }
        case .failed(let message):
            ContentUnavailableView {
                Label("상품을 불러오지 못했어요", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("다시 시도") {
                    Task {
                        await viewModel.load()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
