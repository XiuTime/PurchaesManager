//
//  DFReceiptVerificator.swift
//  DFPurchaseManager
//
//  Created by GSW on 2021/5/25.
//

import Foundation
import StoreKit

class DFReceiptVerificator: NSObject, SKRequestDelegate {
    private let appStoreReceiptURL: URL?
    init(appStoreReceiptURL: URL? = Bundle.main.appStoreReceiptURL) {
        self.appStoreReceiptURL = appStoreReceiptURL
    }
    
    deinit {
        request?.delegate = nil
    }

    private var appStoreReceiptData: Data? {
        guard let receiptDataURL = appStoreReceiptURL,
            let data = try? Data(contentsOf: receiptDataURL) else {
            return nil
        }
        return data
    }
    
    private var appStoreReceiptDataBase64String: String? {
        guard let receiptData = appStoreReceiptData else {
            return nil
        }
        let receiptString = receiptData.base64EncodedString(options: [])
        return receiptString
    }
    
    private var request: SKReceiptRefreshRequest?
    var fetchReceiptBlock: DFPurchaseManagerFetchReceiptBlock?
    
    func fetchReceipt(forceRefresh: Bool) -> Void {
        if let receiptString = appStoreReceiptDataBase64String {
            fetchReceiptBlock?(receiptString)
        } else if forceRefresh {
            request = SKReceiptRefreshRequest(receiptProperties: nil)
            request?.delegate = self
            request?.start()
        }
    }
    
    func requestDidFinish(_ request: SKRequest) {
        DispatchQueue.main.async {
            if let receiptString = self.appStoreReceiptDataBase64String {
                self.fetchReceiptBlock?(receiptString)
            } else {
                self.fetchReceiptBlock?(nil)
            }
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.fetchReceiptBlock?(nil)
        }
    }
}
