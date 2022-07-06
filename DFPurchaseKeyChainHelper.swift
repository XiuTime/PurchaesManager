//
//  DFPurchaseKeyChainHalper.swift
//  DFPurchaseManager
//
//  Created by GSW on 2021/5/24.
//

import UIKit

class DFPurchaseKeyChainHelper {
    let keychain = KeychainSwift()
    var items: [DFPurchaseOrderItem] = []
    
    init() {
        let allKeys = keychain.allKeys
        
        allKeys.forEach { key in
            if let value = keychain.getData(key),
               let item = try? JSONDecoder().decode(DFPurchaseOrderItem.self, from: value) {
                items.append(item)
            }
        }
    }
    func update(orderId: String, productId: String) {
        let item = DFPurchaseOrderItem(orderId: orderId, productId: productId)
        if let data = try? JSONEncoder().encode(item) {
            keychain.set(data, forKey: orderId)
        }
        items.append(item)
    }
    
    func firstOrder(with productId: String) -> String? {
        guard let item = items.first(where: {$0.productId == productId}) else {
            return nil
        }
        return item.orderId
    }
    
    func remove(orderId: String) {
        guard let item = items.first(where: {$0.orderId == orderId}) else {
            return
        }
        finish(item: item)
    }
    
    func removeAll() {
        items.forEach { item in
            finish(item: item)
        }
    }
    
    private func finish(item: DFPurchaseOrderItem) {
        if item.orderId.isEmpty {
            return
        }
        var newItem = item
        newItem.finish = true
        newItem.finishTime = Date().timeIntervalSince1970
        if let data = try? JSONEncoder().encode(newItem) {
            keychain.set(data, forKey: newItem.orderId)
            //keychain.delete(newItem.orderId)
        }
        
    }
}


struct DFPurchaseOrderItem: Codable {
    let orderId: String
    let productId: String
    var finish: Bool
    let creatTime: TimeInterval
    var finishTime: TimeInterval?
    
    init(orderId: String, productId: String) {
        self.orderId = orderId
        self.productId = productId
        self.finish = false
        self.creatTime = Date().timeIntervalSince1970
        self.finishTime = .zero
    }
    
}
