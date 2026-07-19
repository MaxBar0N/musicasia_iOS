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

extension IAPManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
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
        // 通知所有等待中的回调
        for (_, completion) in completionHandlers {
            completion(.failure(error))
        }
        completionHandlers.removeAll()
    }
}

extension IAPManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                SKPaymentQueue.default().finishTransaction(transaction)
                // 支付成功，通常这里需要将凭证发给服务器验证
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
                // 恢复成功
                
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
