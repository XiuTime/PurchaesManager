//
//  DFProductsFetchHandler.swift
//  DFPurchaseManager
//
//  Created by GSW on 2021/5/21.
//

import Foundation
import StoreKit


 class DFProductsFetchHandler: NSObject, SKProductsRequestDelegate {
    
     var successBlock: DFPurchaseManagerProductsFetchSuccessBlock?
     var failureBlock: DFPurchaseManagerErrorBlock?
    
     var request: SKProductsRequest?
    
     override init() {
        super.init()
    }
    
     func fetch(productIdentifiers: [String]) {
        request = SKProductsRequest(productIdentifiers: Set(productIdentifiers))
        request?.delegate = self
        request?.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let fetchedProducts = response.products
        
        self.successBlock?(fetchedProducts, response.invalidProductIdentifiers)
        
        request.delegate = nil
        request.cancel()
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.failureBlock?(error)
        
        request.delegate = nil
        request.cancel()
    }
}
