import Foundation
import Testing
import UIKit
@testable import ProductAssignment

@MainActor
struct ImageLoaderTests {
    @Test func reusesImageForTheSameURL() async throws {
        let data = makeImageData()
        var requestCount = 0
        let loader = ImageLoader { _ in
            requestCount += 1
            return data
        }
        let url = try #require(URL(string: "https://example.com/product.png"))

        let first = try await loader.image(for: url)
        let second = try await loader.image(for: url)

        #expect(requestCount == 1)
        #expect(first === second)
        #expect(loader.cachedImage(for: url) === first)
    }

    @Test func sharesAnOngoingDownload() async throws {
        let data = makeImageData()
        var requestCount = 0
        let loader = ImageLoader { _ in
            requestCount += 1
            // 첫 다운로드가 진행 중인 동안 다른 화면도 같은 URL을 요청한다.
            try await Task.sleep(for: .milliseconds(30))
            return data
        }
        let url = try #require(URL(string: "https://example.com/product.png"))

        async let first = loader.image(for: url)
        async let second = loader.image(for: url)
        let images = try await (first, second)

        #expect(requestCount == 1)
        #expect(images.0 === images.1)
    }

    @Test func invalidImageIsNotCachedAndCanBeRetried() async throws {
        let data = makeImageData()
        var requestCount = 0
        let loader = ImageLoader { _ in
            requestCount += 1
            return requestCount == 1 ? Data() : data
        }
        let url = try #require(URL(string: "https://example.com/product.png"))

        await #expect(throws: URLError.self) {
            _ = try await loader.image(for: url)
        }
        #expect(loader.cachedImage(for: url) == nil)

        let image = try await loader.image(for: url)
        #expect(requestCount == 2)
        #expect(loader.cachedImage(for: url) === image)
    }

    private func makeImageData() -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 2, height: 2))
        return renderer.pngData { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
        }
    }
}
