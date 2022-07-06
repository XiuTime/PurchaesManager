import Foundation

public class DFPurchaseManager {
    let shared = DFPurchaseManager()
    
    private(set) var iap: DFPurchaseService!
    
    func setConfigure(with verifyTransaction: DFVerifyTransaction) {
        iap = DFPurchaseService()
    }
}

