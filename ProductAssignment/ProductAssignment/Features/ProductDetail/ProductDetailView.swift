import SwiftUI

struct ProductDetailView: View {
    @State private var viewModel: ProductDetailViewModel
    let favoriteStore: FavoriteStore

    init(productID: Int, service: any ProductServicing, favoriteStore: FavoriteStore) {
        _viewModel = State(initialValue: ProductDetailViewModel(
            productID: productID,
            service: service
        ))
        self.favoriteStore = favoriteStore
    }

    var body: some View {
        content
            .navigationTitle("상품 상세")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.load()
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView("상품을 불러오는 중…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let product):
            productContent(product)
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

    private func productContent(_ product: Product) -> some View {
        let isFavorite = favoriteStore.isFavorite(product.id)

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                productImage(url: product.thumbnail)
                    .frame(maxWidth: .infinity)
                    .frame(height: 280)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                    .clipped()

                VStack(alignment: .leading, spacing: 8) {
                    Text(product.title ?? "상품명 없음")
                        .font(.title2.bold())

                    if let price = product.price {
                        Text("가격 \(price.formatted(.number.precision(.fractionLength(2))))")
                            .font(.title3.weight(.semibold))
                    } else {
                        Text("가격 정보 없음")
                            .font(.title3.weight(.semibold))
                    }
                }

                Button {
                    favoriteStore.toggle(product.id)
                } label: {
                    Label(
                        isFavorite ? "찜 해제" : "찜하기",
                        systemImage: isFavorite ? "heart.fill" : "heart"
                    )
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isFavorite ? .red : .accentColor)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("상품 설명")
                        .font(.headline)
                    Text(product.description ?? "상품 설명 없음")
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func productImage(url: URL?) -> some View {
        if let url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable().scaledToFit().padding(16)
                case .failure:
                    imagePlaceholder
                @unknown default:
                    imagePlaceholder
                }
            }
        } else {
            imagePlaceholder
        }
    }

    private var imagePlaceholder: some View {
        Image(systemName: "photo")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
    }
}
