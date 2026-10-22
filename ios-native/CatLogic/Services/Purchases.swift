import CatLogicKit
import StoreKit

// The one-time "all levels" purchase (StoreKit 2). App Store transactions are
// the source of truth; AppModel caches the result so levels stay open offline.
@MainActor @Observable
final class Purchases {
    enum State: Equatable {
        case idle, buying, pending, failed(String)
    }

    private(set) var product: Product?
    private(set) var loadFailed = false
    var state = State.idle
    private var updates: Task<Void, Never>?

    func start(app: AppModel) {
        guard updates == nil else { return }
        // Purchases made elsewhere (another device, Ask to Buy approval, refunds)
        updates = Task {
            for await _ in Transaction.updates {
                await self.refresh(app: app)
            }
        }
        Task {
            await refresh(app: app)
            await loadProduct()
        }
    }

    func loadProduct() async {
        do {
            product = try await Product.products(for: [Unlock.productID]).first
            loadFailed = product == nil
        } catch {
            loadFailed = true
        }
    }

    // Unlocked exactly when there's a verified, unrevoked transaction
    func refresh(app: AppModel) async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Unlock.productID, t.revocationDate == nil {
                owned = true
            }
        }
        app.setAllLevelsUnlocked(owned)
    }

    func buy(app: AppModel) async {
        guard let product else { return }
        state = .buying
        do {
            switch try await product.purchase() {
            case .success(.verified(let t)):
                await t.finish()
                await refresh(app: app)
                state = .idle
            case .success(.unverified):
                state = .failed("The App Store couldn't confirm that purchase. Nothing was charged twice; try Restore.")
            case .pending:
                state = .pending
            case .userCancelled:
                state = .idle
            @unknown default:
                state = .idle
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func restore(app: AppModel) async {
        state = .buying
        do {
            try await AppStore.sync()
            await refresh(app: app)
            state = .idle
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
