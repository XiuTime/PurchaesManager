//
//  DFTransaction.swift
//  DFPurchaseManager
//
//  Created by GSW on 2021/5/24.
//

import StoreKit

class DFTransaction {
    var transaction: SKPaymentTransaction
    var receipt: String
    var productIdentifier: String
    var handle: Bool
    
    init(transaction: SKPaymentTransaction,
         receipt: String,
         productIdentifier: String,
         handle: Bool = false) {
        self.transaction = transaction
        self.receipt = receipt
        self.productIdentifier = productIdentifier
        self.handle = handle
    }
}
