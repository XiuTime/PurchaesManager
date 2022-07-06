//
//  DFPurchaseService.swift
//  DFPurchaseManager
//
//  Created by GSW on 2021/5/21.
//

import Foundation
import StoreKit

class DFPurchaseService: NSObject {
    let verifyInterval: TimeInterval = 10.0
    let keyChainHelper = DFPurchaseKeyChainHelper()
    var transactionMaps: [String: DFTransaction]
    var purchaseProductResult: DFPurchaseProductsResult?
    var
        verifyTransaction: DFVerifyTransaction
    var handlerOrderId: String?
    var timer: Timer
    
    public init(with verifyTransaction: DFVerifyTransaction) {
        self.verifyTransaction = verifyTransaction
        self.transactionMaps = [:]
        SKPaymentQueue.default().add(self)
        timer = Timer(timeInterval: verifyInterval, target: self, selector: #selector(reVerify), userInfo: nil, repeats: true)
        RunLoop.current.add(timer, forMode: .commonModes)
        timer.fireDate = Date(timeIntervalSinceNow: verifyInterval)
    }
    
    public func purchaseProduct(product: SKProduct,
                                user userIdentifier: String,
                                onCompletion completion: @escaping DFPurchaseProductsResult) {
        guard SKPaymentQueue.canMakePayments() else {
            completion(.failure)
            return
        }
        self.purchaseProductResult = completion
        let orderId = userIdentifier + "-" + String(Date().timeIntervalSince1970)
        self.handlerOrderId = orderId
        let payment = SKMutablePayment(product: product)
        payment.applicationUsername = orderId
        keyChainHelper.update(orderId: orderId, productId: product.productIdentifier)
        SKPaymentQueue.default().add(payment)
    }
    
    public func fetchProducts(withIdentifiers productIdentifiers: [String],
                              onSuccess success: @escaping DFPurchaseManagerProductsFetchSuccessBlock,
                              onFailure failure: @escaping DFPurchaseManagerErrorBlock) {
        let handler = DFProductsFetchHandler()
        handler.successBlock = success
        handler.failureBlock = failure
        handler.fetch(productIdentifiers: productIdentifiers)
    }
    
    fileprivate func clear() {
        transactionMaps.removeAll()
        keyChainHelper.removeAll()
    }
    
    @objc fileprivate func reVerify() {
        if let needVerifyOrder = transactionMaps.first(where: {!$0.value.handle}) {
            verify(order: needVerifyOrder.key, handler: nil)
        } else {
            objc_sync_enter(self)
            self.timer.fireDate = Date.distantFuture
            objc_sync_exit(self)
        }
    }
    
    fileprivate func completeTransaction(transaction: SKPaymentTransaction, retryWhenReceiptEmpty retry: Bool) {
        guard let orderId = orderId(of: transaction) else {
            finish(transaction: transaction, result: .unverified)
            return
        }
        var t = transactionMaps[orderId]
        if t == nil {
            t = insert(orderId: orderId, transaction: transaction)
        }
        
        let verificator = DFReceiptVerificator()
        verificator.fetchReceiptBlock = {[weak self] receipt in
            if let r = receipt {
                t?.receipt = r
                self?.verify(order: orderId, handler: nil)
            } else {
                t?.handle = false
                self?.finish(transaction: transaction, result: .unverified)
            }
        }
        verificator.fetchReceipt(forceRefresh: retry)
    }
    
    fileprivate func faildTransaction(transaction: SKPaymentTransaction) {
        let cancel = ((transaction.error as? SKError)?.code == .paymentCancelled)
        let result: DFPurchaseResult = cancel ? .cancel : .failure
        if let order = orderId(of: transaction) {
            verifyTransaction.pushFailReulttToServer(userCancelled: cancel, transaction: transaction) { [weak self] isSuccess in
                if self?.handlerOrderId == order {
                    self?.handlerOrderId = nil;
                    self?.purchaseProductResult?(result)
                }
            }
        } else {
            finish(transaction: transaction, result: result)
        }
    }
    
    fileprivate func insert(orderId: String, transaction: SKPaymentTransaction) -> DFTransaction {
        let t = DFTransaction(transaction: transaction, receipt: "", productIdentifier: transaction.payment.productIdentifier,
                              handle: true)
       transactionMaps[orderId] = t
        objc_sync_enter(self)
        if (self.timer.fireDate.timeIntervalSince1970 - Date().timeIntervalSince1970) > verifyInterval {
            self.timer.fireDate = Date(timeIntervalSinceNow: verifyInterval)
        }
        objc_sync_exit(self)
        return t
        
    }
    
    fileprivate func finish(transaction: SKPaymentTransaction,
                            result: DFPurchaseResult) {
        var orderId = orderId(of: transaction)
        var t: DFTransaction?
        if let orderId = orderId {
            t = transactionMaps[orderId]
            t?.handle = false
        }
        if result == .unverified {
            //不处理 轮询
        } else {
            SKPaymentQueue.default().finishTransaction(transaction)
            if let orderId = orderId {
                transactionMaps.removeValue(forKey: orderId)
                keyChainHelper.remove(orderId: orderId)
            }
        }
        if orderId == handlerOrderId {
            self.handlerOrderId = nil;
            self.purchaseProductResult?(result)
        }
    }
    
    fileprivate func verify(order orderId: String,
                            handler: DFVerifyTransactionBlock?) {
        guard let transaction = transactionMaps[orderId] else {
            handler?(.failure)
            return
        }
        transaction.handle = true
        let receipt = transaction.receipt
        if receipt.isEmpty {
            handler?(.failure)
            return
        }
        
        self.verifyTransaction.pushSuccessReultToService(receipt: receipt, transaction: transaction.transaction) {[weak self] isSuccess in
            
            self?.finish(transaction: transaction.transaction, result: isSuccess ? .success : .unverified)
        }
    }
    
    fileprivate func orderId(of transaction: SKPaymentTransaction) -> String? {
        var orderId: String?
        if let applicationUsername =  transaction.payment.applicationUsername, !applicationUsername.isEmpty {
            orderId = applicationUsername
            
        } else if let oid = keyChainHelper.firstOrder(with: transaction.payment.productIdentifier) {
            orderId = oid
        }
        return orderId
    }
}


extension DFPurchaseService: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        if !SKPaymentQueue.default().transactions.isEmpty {
            clear()
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                debugPrint("IAP -- 商品购买成功")
                completeTransaction(transaction: transaction, retryWhenReceiptEmpty: true)
            case .failed:
                faildTransaction(transaction: transaction)
                break
            case .purchasing:
                break
            default: break
            }
        }
    }
    
}
