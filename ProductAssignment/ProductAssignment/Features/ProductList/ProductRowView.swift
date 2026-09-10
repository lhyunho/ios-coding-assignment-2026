import Foundation
import SwiftUI

struct ProductRowView: View {
    let product: Product

    var body: some View {
        HStack(spacing: 16) {
            thumbnail
                .frame(width: 88, height: 88)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                .clipped()

            VStack(alignment: .leading, spacing: 8) {
                Text(product.title ?? "상품명 없음")
                    .font(.body)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let price = product.price {
                    // API에 통화 정보가 없으므로 단위를 임의로 붙이지 않는다.
                    Text("가격 \(price.formatted(.number.precision(.fractionLength(2))))")
                        .font(.subheadline.weight(.semibold))
                } else {
                    Text("가격 정보 없음")
                        .font(.subheadline.weight(.semibold))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = product.thumbnail {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable().scaledToFit().padding(6)
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
            .font(.title2)
            .foregroundStyle(.secondary)
    }
}
