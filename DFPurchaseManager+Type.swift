//
//  DFPurchaseManager+Type.swift
//  DFPurchaseManager
//
//  Created by GSW on 2021/5/21.
//

import Foundation
import StoreKit


enum DFPurchaseResult {
    case success //iap + 服务器验证成功
    case unverified //iap成功， 服务器验证失败
    case failure //iap失败
    case cancel //用户cancel
}

enum DFVerifyTransactionRusult {
    case created
    case failure
    case scuuess
}

enum DFPurchaseServiceErrorType {
    case none
    case orderNotExist
    case applicationUsernameNotExist
    case productKeyChainNotExist
    case receiptNotExist
    case reReceiptNotExist
    case verifyOrderFail
}

typealias DFPurchaseManagerProductsFetchSuccessBlock = (_ products: [SKProduct], _ invalidIdentifiers: [String]) -> Void
typealias DFPurchaseManagerErrorBlock = (_ error: Error) -> Void
typealias DFPurchaseManagerVerifyTransactionCallBack = (_ isSuccess: Bool) -> Void
typealias DFPurchaseProductsResult = (_ result: DFPurchaseResult) -> Void
typealias DFVerifyTransactionBlock = (_ result: DFVerifyTransactionRusult) -> Void
typealias DFPurchaseManagerFetchReceiptBlock = (_ receipt: String?) ->Void

protocol DFVerifyTransaction {
    
    func pushSuccessReultToService(receipt: String,
                                   transaction: SKPaymentTransaction,
                                   complete:DFPurchaseManagerVerifyTransactionCallBack)
    
    func pushFailReulttToServer(userCancelled: Bool,
                                transaction: SKPaymentTransaction,
                                complete:DFPurchaseManagerVerifyTransactionCallBack)
}
