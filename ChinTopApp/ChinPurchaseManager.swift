import StoreKit
import SwiftUI

// MARK: - 完整功能解锁 IAP（StoreKit 2 · 一次性买断）
//
// 产品 ID：com.chintop.app.full_unlock（¥22 一次性买断，价格在 App Store Connect 配置）
// 免费档：每个专题每个学段前 3 题免费试练，其余题目付费解锁（见 ChinContent.PracticeListView）。
// 解锁后：五大专题（阅读/文言文/古诗词/作文/综合性学习）全部题目、逐题解析与错题复盘开放。
// 本地 UserDefaults 缓存即时呈现，启动时 Transaction.currentEntitlements 核验防破解。
// 本地调试：scheme 已挂载 ChinTopApp.storekit，可在沙盒外直接测试购买/恢复流程。

@MainActor final class ChinPurchaseManager: ObservableObject {
    static let shared = ChinPurchaseManager()

    let productID = "com.chintop.app.full_unlock"

    @Published private(set) var isUnlocked: Bool = false
    @Published private(set) var product: Product?
    @Published private(set) var isPurchasing: Bool = false
    @Published private(set) var errorMessage: String?
    /// 商品信息拉取失败（无网络 / ASC 未配置）：付费墙需提示重试，而不是长期展示兜底价。
    @Published private(set) var productLoadFailed: Bool = false

    private let storageKey = "chintop.full_unlocked"
    private var updatesTask: Task<Void, Never>?

    private init() {
        isUnlocked = UserDefaults.standard.bool(forKey: storageKey)
        Task {
            await loadProduct()
            await refreshEntitlements()
        }
        listenForTransactions()
    }

    // MARK: StoreKit

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [productID])
            product = products.first
            productLoadFailed = product == nil
        } catch {
            productLoadFailed = true
        }
    }

    /// 付费墙「重试」入口：网络恢复或 ASC 配置就绪后重新拉取价格。
    func retryLoadProduct() async {
        productLoadFailed = false
        await loadProduct()
    }

    func purchase() async {
        guard let product else {
            errorMessage = "商品信息尚未加载完成，请检查网络后重试"
            await loadProduct()
            return
        }
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                unlock()
            case .userCancelled:
                break
            case .pending:
                errorMessage = "购买待处理（可能需要家长确认），完成后将自动解锁"
            @unknown default:
                break
            }
        } catch {
            errorMessage = "购买失败：\(error.localizedDescription)"
        }
    }

    func restore() async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isUnlocked { errorMessage = "未找到购买记录" }
        } catch {
            errorMessage = "恢复失败：\(error.localizedDescription)"
        }
    }

    /// 以 App Store 记录为准：没有有效交易时回退解锁状态，退款/撤销能真实生效。
    func refreshEntitlements() async {
        var entitled = false
        for await result in StoreKit.Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == productID,
               tx.revocationDate == nil {
                entitled = true
                break
            }
        }
        if entitled {
            unlock()
        } else {
            lock()
        }
    }

    private func unlock() {
        isUnlocked = true
        UserDefaults.standard.set(true, forKey: storageKey)
    }

    /// 退款或家庭共享撤销：解锁状态回退，避免本地标记永久生效。
    private func lock() {
        isUnlocked = false
        UserDefaults.standard.set(false, forKey: storageKey)
    }

    /// 监听 App 之外完成的交易：家长批准（Ask to Buy）、换机重装、退款撤销都会走到这里。
    private func listenForTransactions() {
        updatesTask?.cancel()
        updatesTask = Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self else { return }
                guard case .verified(let tx) = result, tx.productID == self.productID else { continue }
                await self.apply(transaction: tx)
            }
        }
    }

    private func apply(transaction tx: StoreKit.Transaction) async {
        if tx.revocationDate != nil {
            lock()
            return
        }
        await tx.finish()
        unlock()
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error): throw error
        case .verified(let value): return value
        }
    }
}
