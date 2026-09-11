import Foundation
import Observation

@MainActor
@Observable
final class FavoriteStore {
    private var favoriteIDs: Set<Int> = []
    private let userDefaults: UserDefaults
    private let storageKey = "favoriteProductIDs"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        let savedIDs = userDefaults.array(forKey: storageKey) as? [Int] ?? []
        favoriteIDs = Set(savedIDs)
    }

    func isFavorite(_ productID: Int) -> Bool {
        favoriteIDs.contains(productID)
    }

    func toggle(_ productID: Int) {
        if favoriteIDs.contains(productID) {
            favoriteIDs.remove(productID)
        } else {
            favoriteIDs.insert(productID)
        }

        userDefaults.set(Array(favoriteIDs), forKey: storageKey)
    }
}
