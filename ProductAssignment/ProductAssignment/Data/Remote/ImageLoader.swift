import Foundation
import UIKit

@MainActor
final class ImageLoader {
    // HTTP 응답은 메모리에만 캐싱하고, 서버의 캐시 정책에 따라 재사용한다.
    private static let session = URLSession(configuration: .ephemeral)

    private let cache = NSCache<NSURL, UIImage>()
    private var inFlight: [URL: Task<UIImage, any Error>] = [:]
    private let fetchData: (URL) async throws -> Data

    init(fetchData: @escaping (URL) async throws -> Data = ImageLoader.downloadData) {
        self.fetchData = fetchData
    }

    func cachedImage(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func image(for url: URL) async throws -> UIImage {
        if let image = cachedImage(for: url) {
            return image
        }

        // 같은 URL을 다운로드 중이면 기존 작업의 결과를 함께 기다린다.
        if let task = inFlight[url] {
            return try await task.value
        }

        let task = Task {
            let data = try await fetchData(url)
            guard let image = UIImage(data: data) else {
                throw URLError(.cannotDecodeContentData)
            }
            return image
        }
        inFlight[url] = task
        defer { inFlight[url] = nil }

        let image = try await task.value
        cache.setObject(image, forKey: url as NSURL)
        return image
    }

    private static func downloadData(from url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let response = response as? HTTPURLResponse,
              (200..<300).contains(response.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }
}
