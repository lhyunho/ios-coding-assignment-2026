import SwiftUI
import UIKit

struct ProductImageView: View {
    let url: URL?
    let imageLoader: ImageLoader
    @State private var result: ImageResult?

    var body: some View {
        Group {
            if let url {
                if let image = imageLoader.cachedImage(for: url) ?? loadedImage(for: url) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                } else if result?.url == url {
                    imagePlaceholder
                } else {
                    ProgressView()
                }
            } else {
                imagePlaceholder
            }
        }
        .task(id: url) {
            guard let url else { return }
            let image = try? await imageLoader.image(for: url)
            // 사라진 화면의 작업은 공유 다운로드를 취소하지 않고, 화면 반영만 생략한다.
            guard !Task.isCancelled else { return }
            result = ImageResult(url: url, image: image)
        }
    }

    private func loadedImage(for url: URL) -> UIImage? {
        guard result?.url == url else { return nil }
        return result?.image
    }

    private var imagePlaceholder: some View {
        Image(systemName: "photo")
            .foregroundStyle(.secondary)
    }
}

// URL이 바뀌면 이전 결과를 표시하지 않는다. image가 nil이면 로딩에 실패한 결과다.
private struct ImageResult {
    let url: URL
    let image: UIImage?
}
