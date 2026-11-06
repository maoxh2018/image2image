import Foundation
import StoreKit
import Combine

enum StoreError: Error {
    case failedVerification
}

class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var isSubscribed = false
    @Published var remainingCount = 0

    private var products: [Product] = []
    private var updateListenerTask: Task<Void, Error>?

    private init() {
        loadSubscriptionStatus()
    }

    func setupStoreKitListener() {
        updateListenerTask = listenForTransactions()
    }

    func cleanup() {
        updateListenerTask?.cancel()
    }

    private func loadSubscriptionStatus() {
        let defaults = UserDefaults.standard
        isSubscribed = defaults.bool(forKey: "isSubscribed")
        remainingCount = defaults.integer(forKey: "remainingCount")
    }

    private func saveSubscriptionStatus() {
        let defaults = UserDefaults.standard
        defaults.set(isSubscribed, forKey: "isSubscribed")
        defaults.set(remainingCount, forKey: "remainingCount")
    }

    func subscribe() {
        isSubscribed = true
        remainingCount = Config.maxGenerationCount
        saveSubscriptionStatus()
    }

    func unsubscribe() {
        isSubscribed = false
        remainingCount = 0
        saveSubscriptionStatus()
    }

    func consumeGeneration() {
        if isSubscribed && remainingCount > 0 {
            remainingCount -= 1
            saveSubscriptionStatus()
        }
    }

    func canGenerate() -> Bool {
        return isSubscribed && remainingCount > 0
    }

    // MARK: - StoreKit 2 交易监听

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("交易验证失败: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - 加载产品

    func loadProducts() async throws -> [Product] {
        let productIds = [Config.monthlyProductId, Config.yearlyProductId]
        products = try await Product.products(for: productIds)
        return products
    }

    // MARK: - 购买产品

    func purchaseProduct(_ product: Product) async throws -> PurchaseResult {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updateSubscriptionStatus()
            await transaction.finish()
            return .success

        case .userCancelled:
            return .cancelled

        case .pending:
            return .pending

        @unknown default:
            return .pending
        }
    }

    // MARK: - 恢复购买

    func restorePurchase() async throws {
        try await AppStore.sync()
        await updateSubscriptionStatus()
    }

    // MARK: - 更新订阅状态

    private func updateSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                print("当前订阅产品: \(transaction.productID)")
                DispatchQueue.main.async {
                    self.subscribe()
                }
                return
            }
        }

        DispatchQueue.main.async {
            self.unsubscribe()
        }
    }
}

enum PurchaseResult {
    case success
    case cancelled
    case pending
}
