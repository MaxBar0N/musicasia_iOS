import Foundation
import StoreKit

enum IAPError: Error, LocalizedError {
    case productsNotFound
    case paymentCancelled
    case paymentFailed
    case receiptVerificationFailed

    var errorDescription: String? {
        switch self {
        case .productsNotFound: return "未找到对应的商品"
        case .paymentCancelled: return "用户取消了支付"
        case .paymentFailed: return "支付失败，请重试"
        case .receiptVerificationFailed: return "凭证验证失败"
        }
    }
}

class IAPManager: NSObject {
    static let shared = IAPManager()

    private var productRequest: SKProductsRequest?
    private var completionHandlers: [String: (Result<SKProduct, Error>) -> Void] = [:]
    private var purchaseCompletion: ((Result<Void, Error>) -> Void)?

    // StoreKit 2: 缓存获取到的产品 (用 Any 规避 @available 存储属性限制)
    private var _cachedProducts: [String: Any] = [:]

    override private init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    deinit {
        SKPaymentQueue.default().remove(self)
    }

    /// 获取商品信息
    func fetchProduct(productID: String, completion: @escaping (Result<SKProduct, Error>) -> Void) {
        guard SKPaymentQueue.canMakePayments() else {
            completion(.failure(NSError(domain: "IAPManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "当前设备不支持内购"])))
            return
        }

        print("🛒 [IAPManager] ========== 获取商品信息 ==========")
        print("🛒 [IAPManager] Product ID: \(productID)")
        print("🛒 [IAPManager] Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")
        let osVer = ProcessInfo.processInfo.operatingSystemVersion
        print("🛒 [IAPManager] iOS 版本: \(osVer.majorVersion).\(osVer.minorVersion).\(osVer.patchVersion)")

        if #available(iOS 15.0, *) {
            // 先尝试 StoreKit 2
            fetchProductStoreKit2(productID: productID, completion: completion)
        } else {
            // iOS 14 用 StoreKit 1
            fetchProductStoreKit1(productID: productID, completion: completion)
        }
    }

    // MARK: - StoreKit 2 (iOS 15+)

    @available(iOS 15.0, *)
    private func fetchProductStoreKit2(productID: String, completion: @escaping (Result<SKProduct, Error>) -> Void) {
        print("🛒 [IAPManager] 使用 StoreKit 2 获取商品...")

        Task {
            do {
                let products = try await Product.products(for: [productID])
                print("🛒 [IAPManager] StoreKit 2 返回商品数: \(products.count)")

                if let product = products.first {
                    print("🛒 [IAPManager] ✅ 找到商品: \(product.id)")
                    print("🛒 [IAPManager]    名称: \(product.displayName)")
                    print("🛒 [IAPManager]    价格: \(product.displayPrice)")
                    print("🛒 [IAPManager]    类型: \(product.type)")

                    // 缓存 StoreKit 2 产品
                    _cachedProducts[product.id] = product

                    // 用 StoreKit 1 方式获取 SKProduct 以兼容现有 buyProduct 流程
                    fetchProductStoreKit1(productID: productID, completion: completion)
                } else {
                    print("🛒 [IAPManager] ❌ StoreKit 2 未找到商品 '\(productID)'")
                    print("🛒 [IAPManager] ⚠️ 可能原因: 沙盒环境未配置 / 产品ID不匹配 / .storekit未启用")

                    // StoreKit 2 也找不到，试试 StoreKit 1 看能否得到更多信息
                    fetchProductStoreKit1(productID: productID, completion: completion)
                }
            } catch {
                print("🛒 [IAPManager] ❌ StoreKit 2 错误: \(error.localizedDescription)")
                print("🛒 [IAPManager]    错误详情: \(error)")

                // 回退到 StoreKit 1
                fetchProductStoreKit1(productID: productID, completion: completion)
            }
        }
    }

    // MARK: - StoreKit 2 购买 (iOS 15+)

    /// StoreKit 2 购买，成功时返回 signedTransactionInfo (JWS)
    @available(iOS 15.0, *)
    func buyProductAndGetTransactionInfo(productID: String, appAccountToken: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        guard let product = _cachedProducts[productID] as? Product else {
            completion(.failure(IAPError.productsNotFound))
            return
        }

        print("🛒 [IAPManager] StoreKit 2 开始购买: \(productID)")

        Task {
            do {
                var options: Set<Product.PurchaseOption> = []
                if let token = appAccountToken, let uuid = UUID(uuidString: token) {
                    options.insert(.appAccountToken(uuid))
                }

                let result = try await product.purchase(options: options)

                switch result {
                case .success(let verification):
                    // 获取 JWS (signedTransactionInfo) 用于服务端验证
                    let jws = verification.jwsRepresentation
                    let transaction = try verification.payloadValue
                    print("🛒 [IAPManager] StoreKit 2 购买成功: \(transaction.id)")
                    print("🛒 [IAPManager] JWS 长度: \(jws.count)")
                    await transaction.finish()

                    await MainActor.run {
                        completion(.success(jws))
                    }

                case .userCancelled:
                    await MainActor.run {
                        completion(.failure(IAPError.paymentCancelled))
                    }

                case .pending:
                    print("🛒 [IAPManager] StoreKit 2 购买等待中...")

                @unknown default:
                    break
                }
            } catch {
                print("🛒 [IAPManager] StoreKit 2 购买失败: \(error)")
                await MainActor.run {
                    completion(.failure(error))
                }
            }
        }
    }

    /// StoreKit 2 购买（不含 JWS 返回，兼容旧调用）
    @available(iOS 15.0, *)
    func buyProductStoreKit2(productID: String, appAccountToken: String? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        buyProductAndGetTransactionInfo(productID: productID, appAccountToken: appAccountToken) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - StoreKit 1 (原有实现)

    private func fetchProductStoreKit1(productID: String, completion: @escaping (Result<SKProduct, Error>) -> Void) {
        print("🛒 [IAPManager] 使用 StoreKit 1 获取商品...")

        completionHandlers[productID] = completion

        let request = SKProductsRequest(productIdentifiers: [productID])
        request.delegate = self
        request.start()
        productRequest = request
    }

    /// 购买商品
    func buyProduct(_ product: SKProduct, appAccountToken: String? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        self.purchaseCompletion = completion
        let payment = SKMutablePayment(product: product)
        if let token = appAccountToken {
            payment.applicationUsername = token
        }
        SKPaymentQueue.default().add(payment)
    }

    /// 恢复购买
    func restorePurchases(completion: @escaping (Result<Void, Error>) -> Void) {
        self.purchaseCompletion = completion
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    /// 获取本地支付凭证
    func getReceiptData() -> String? {
        guard let url = Bundle.main.appStoreReceiptURL,
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return data.base64EncodedString()
    }
}

// MARK: - StoreKit 1 Delegates

extension IAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        print("🛒 [IAPManager] SK1 SKProductsResponse:")
        print("🛒 [IAPManager]   有效: \(response.products.count) 个")
        for p in response.products {
            print("🛒 [IAPManager]     ✅ \(p.productIdentifier) | \(p.localizedTitle) | \(p.price)")
        }
        print("🛒 [IAPManager]   无效: \(response.invalidProductIdentifiers.count) 个")
        for id in response.invalidProductIdentifiers {
            print("🛒 [IAPManager]     ❌ \(id)")
        }

        for product in response.products {
            if let completion = completionHandlers[product.productIdentifier] {
                completion(.success(product))
                completionHandlers[product.productIdentifier] = nil
            }
        }

        for invalidID in response.invalidProductIdentifiers {
            if let completion = completionHandlers[invalidID] {
                completion(.failure(IAPError.productsNotFound))
                completionHandlers[invalidID] = nil
            }
        }
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("🛒 [IAPManager] SK1 请求失败: \(error.localizedDescription)")
        for (_, completion) in completionHandlers {
            completion(.failure(error))
        }
        completionHandlers.removeAll()
    }
}

// MARK: - StoreKit 1 Transaction Observer

extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                SKPaymentQueue.default().finishTransaction(transaction)
                purchaseCompletion?(.success(()))
                purchaseCompletion = nil

            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                if let error = transaction.error as NSError?, error.code == SKError.paymentCancelled.rawValue {
                    purchaseCompletion?(.failure(IAPError.paymentCancelled))
                } else {
                    purchaseCompletion?(.failure(IAPError.paymentFailed))
                }
                purchaseCompletion = nil

            case .restored:
                SKPaymentQueue.default().finishTransaction(transaction)

            case .purchasing, .deferred:
                break
            @unknown default:
                break
            }
        }
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        purchaseCompletion?(.success(()))
        purchaseCompletion = nil
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        purchaseCompletion?(.failure(error))
        purchaseCompletion = nil
    }
}
