import Foundation
import Testing
@testable import ProductAssignment

@MainActor
struct FavoriteStoreTests {
    @Test func togglingFavoriteKeepsOtherProducts() throws {
        let suiteName = "FavoriteStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }
        let store = FavoriteStore(userDefaults: userDefaults)

        #expect(!store.isFavorite(1))

        store.toggle(1)
        #expect(store.isFavorite(1))

        store.toggle(2)
        store.toggle(1)

        #expect(!store.isFavorite(1))
        #expect(store.isFavorite(2))
    }

    @Test func favoritesAndRemovalsAreRestored() throws {
        let suiteName = "FavoriteStoreTests.\(UUID().uuidString)"
        let userDefaults = try #require(UserDefaults(suiteName: suiteName))
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let store = FavoriteStore(userDefaults: userDefaults)
        store.toggle(1)

        // 같은 저장 공간으로 새 저장소를 만들어 복원 여부를 확인한다.
        let restoredStore = FavoriteStore(userDefaults: userDefaults)
        #expect(restoredStore.isFavorite(1))

        restoredStore.toggle(1)
        let storeAfterRemoval = FavoriteStore(userDefaults: userDefaults)
        #expect(!storeAfterRemoval.isFavorite(1))
    }
}
