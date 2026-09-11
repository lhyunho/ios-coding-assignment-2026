import SwiftUI

struct ProductListView: View {
    @State private var viewModel: ProductListViewModel
    @State private var selectedProductID: Int?
    @State private var isGrid = false
    @State private var visibleProductID: Int?
    @State private var layoutAnchorID: Int?
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
                Picker("보기 방식", selection: Binding(
                    get: { isGrid },
                    set: { newValue in
                        layoutAnchorID = visibleProductID
                        isGrid = newValue
                    }
                )) {
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
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible()), count: isGrid ? 2 : 1),
                            spacing: isGrid ? 16 : 0
                        ) {
                            ForEach(products) { product in
                                productItem(product)
                                    .id(product.id)
                                    .onAppear {
                                        Task {
                                            await viewModel.loadNextPageIfNeeded(after: product.id)
                                        }
                                    }
                            }
                        }
                        .scrollTargetLayout()
                        .padding(.horizontal)

                        paginationFooter
                    }
                    .scrollPosition(id: $visibleProductID, anchor: .top)
                    .onAppear {
                        if let layoutAnchorID {
                            proxy.scrollTo(layoutAnchorID, anchor: .top)
                            self.layoutAnchorID = nil
                        }
                    }
                }
                // 새 배치에서 전환 직전의 상품을 찾아 이동한다.
                .id(isGrid)
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

    @ViewBuilder
    private func productItem(_ product: Product) -> some View {
        if isGrid {
            ProductGridItemView(
                product: product,
                imageLoader: imageLoader,
                isFavorite: favoriteStore.isFavorite(product.id),
                onSelectProduct: { selectedProductID = product.id },
                onToggleFavorite: { favoriteStore.toggle(product.id) }
            )
        } else {
            VStack(spacing: 0) {
                ProductRowView(
                    product: product,
                    imageLoader: imageLoader,
                    isFavorite: favoriteStore.isFavorite(product.id),
                    onSelectProduct: { selectedProductID = product.id },
                    onToggleFavorite: { favoriteStore.toggle(product.id) }
                )
                .padding(.vertical, 8)

                Divider()
            }
        }
    }

    @ViewBuilder
    private var paginationFooter: some View {
        if viewModel.isLoadingNextPage {
            ProgressView("상품을 더 불러오는 중…")
                .frame(maxWidth: .infinity)
                .padding()
        } else if let message = viewModel.nextPageError {
            VStack(spacing: 12) {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("다시 시도") {
                    Task {
                        await viewModel.loadNextPage()
                    }
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity)
            .padding()
        } else if !viewModel.hasMorePages {
            Text("모든 상품을 불러왔어요")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding()
        }
    }
}
