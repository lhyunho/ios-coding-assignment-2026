import SwiftUI

struct ProductListView: View {
    @State private var viewModel: ProductListViewModel
    @State private var selectedProductID: Int?
    @State private var isGrid = false
    private let service: any ProductServicing
    let favoriteStore: FavoriteStore
    private let imageLoader: ImageLoader

    init(service: any ProductServicing, favoriteStore: FavoriteStore, imageLoader: ImageLoader) {
        _viewModel = State(initialValue: ProductListViewModel(service: service))
        self.service = service
        self.favoriteStore = favoriteStore
        self.imageLoader = imageLoader
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("보기 방식", selection: $isGrid) {
                    Text("1열").tag(false)
                    Text("2열").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.bottom, 8)

                content
            }
            .navigationTitle("상품")
            .navigationDestination(item: $selectedProductID) { productID in
                ProductDetailView(
                    productID: productID,
                    service: service,
                    favoriteStore: favoriteStore,
                    imageLoader: imageLoader
                )
            }
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
            } else if isGrid {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        ForEach(products) { product in
                            ProductGridItemView(
                                product: product,
                                imageLoader: imageLoader,
                                isFavorite: favoriteStore.isFavorite(product.id),
                                onSelectProduct: { selectedProductID = product.id },
                                onToggleFavorite: { favoriteStore.toggle(product.id) }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            } else {
                List(products) { product in
                    ProductRowView(
                        product: product,
                        imageLoader: imageLoader,
                        isFavorite: favoriteStore.isFavorite(product.id),
                        onSelectProduct: { selectedProductID = product.id },
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
