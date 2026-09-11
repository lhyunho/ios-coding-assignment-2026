import Foundation
import SwiftUI

struct ProductGridItemView: View {
    let product: Product
    let imageLoader: ImageLoader
    let isFavorite: Bool
    let onSelectProduct: () -> Void
    let onToggleFavorite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onSelectProduct) {
                VStack(alignment: .leading, spacing: 8) {
                    ProductImageView(url: product.thumbnail, imageLoader: imageLoader)
                        .font(.title2)
                        .padding(6)
                        .frame(maxWidth: .infinity)
                        .frame(height: 150)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
                        .clipped()

                    Text(product.title ?? "상품명 없음")
                        .font(.body)
                        .lineLimit(2, reservesSpace: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(spacing: 4) {
                if let price = product.price {
                    Text("가격 \(price.formatted(.number.precision(.fractionLength(2))))")
                        .font(.subheadline.weight(.semibold))
                } else {
                    Text("가격 정보 없음")
                        .font(.subheadline.weight(.semibold))
                }

                Spacer(minLength: 0)

                Button(action: onToggleFavorite) {
                    Label(
                        isFavorite ? "찜 해제" : "찜하기",
                        systemImage: isFavorite ? "heart.fill" : "heart"
                    )
                    .labelStyle(.iconOnly)
                    .foregroundStyle(isFavorite ? Color.red : Color.secondary)
                    .frame(width: 44, height: 44)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 8)
    }
}
