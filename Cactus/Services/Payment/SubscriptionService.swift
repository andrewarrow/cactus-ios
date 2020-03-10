//
//  CheckoutService.swift
//  Cactus
//
//  Created by Neil Poulin on 2/28/20.
//  Copyright © 2020 Cactus. All rights reserved.
//

import Foundation
import StoreKit

//Methods to help with the checkout process
class SubscriptionService: NSObject {
    static var sharedInstance = SubscriptionService()
    var logger = Logger("CheckoutService")
    var subscriptionProductService = SubscriptionProductService.sharedInstance
    var isAuthorizedForPayments: Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    private var appleRequests: [ProductRequest] = []

    var upgradeTrialDescription = "After your trial of Cactus Plus, you'll continue to get free prompts, but only occasionally."
        + " Give your reflection practice momentum by receiving a fresh prompt, every day"
    
    var upgradeBasicDescription = "Give your reflection practice momentum by receiving a fresh prompt, every day"
    
    func getSubscriptionProductGroupEntryMap(_ onData: @escaping (SubscriptionProductGroupEntryMap?) -> Void) {
        SubscriptionProductGroupService.sharedInstance.getAll { (groupResult) in
            if let error = groupResult.error {
                self.logger.error("Failed to get product groups from flamelink", error)
                onData(nil)
                return
            }
            let productGroups = groupResult.results
            
            SubscriptionProductService.sharedInstance.getAllForSale { (productResult) in
                if let productError = productResult.error {
                    self.logger.error("Failed to get product from flamelink", productError)
                    onData(nil)
                    return
                }
                let subscriptionProducts = productResult.results
                if let appleIds = subscriptionProducts?.compactMap({ isBlank($0.appleProductId) ? nil : $0.appleProductId }) {
                    let appleRequest = ProductRequest()
                    self.appleRequests.append(appleRequest)
                    appleRequest.onCompleted = {
                        let appleProducts = appleRequest.availableAppleProducts
                        let map = createSubscriptionProductGroupEntryMap(products: subscriptionProducts, groups: productGroups, appleProducts: appleProducts)
                        onData(map)
                    }
                    appleRequest.fetchAppleProducts(appleProductIds: appleIds)
                } else {
                    let map = createSubscriptionProductGroupEntryMap(products: subscriptionProducts, groups: productGroups)
                    onData(map)
                }
                                
                return
            }
        }
        
        return
    }
    
    func getSubscriptionDetails(_ onData: @escaping (SubscriptionDetails?, Any?) -> Void) {
        ApiService.sharedInstance.get(path: .checkoutSubscriptionDetails, responseType: SubscriptionDetails.self, authenticated: true) { response, error in
            onData(response, error)
        }
    }
    
    func submitPurchase(product: SKProduct) {
        guard self.isAuthorizedForPayments == true else {
            let alert = UIAlertController(title: "Not Authorized", message: "This device is not authorized to make payments.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
            NavigationService.sharedInstance.present(alert)
            
            return
        }
        
        self.logger.info("Starting checkout for apple product \(product.productIdentifier)")
        let payment = SKPayment(product: product)
        
        SKPaymentQueue.default().add(payment)
        self.logger.info("Payment added to queue. \(payment.productIdentifier)")
    }
    
    /// Calls StoreObserver to restore all restorable purchases.
    func restorePurchase() {
        let alert = UIAlertController(title: "Restore Purchases?", message: "If you have past purchases, they will be restored. Are you sure you want to continue?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Restore", style: .default, handler: { (_) in
            StoreObserver.sharedInstance.restore()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        NavigationService.sharedInstance.present(alert, animated: true)
    }
    
    func completePurchase(onComplete: @escaping ((CompletePurchaseResult?, Any?) -> Void)) {
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
            FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {

            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                let receiptString = receiptData.base64EncodedString(options: [])
                
                let receiptParams = CompletePurchaseRequest(receiptData: receiptString)
                self.logger.info("Sending verify receipt data to backend")
                ApiService.sharedInstance.post(path: ApiPath.appleCompletePurchase, body: receiptParams, responseType: CompletePurchaseResult.self, authenticated: true) { result, error in
                    if let error = error {
                        self.logger.error("Failed to verify receit. error", error)
                    }
                    self.logger.info("completed verify receipt call result: \(String(describing: result))")
                    onComplete(result, error)
                }
            } catch {
                self.logger.error("Couldn't read receipt data with error: " + error.localizedDescription, error)
                onComplete(nil, error)
            }
        } else {
            self.logger.warn("Unable to get receipt data")
            onComplete(nil, "No apple receipt found on the device")
        }
        
    }
}

class ProductRequest: NSObject, SKProductsRequestDelegate {
    let logger = Logger("ProductRequest")
    
    var availableAppleProducts: [SKProduct] = []
    var invalidAppleProductIds: [String]?
    var appleProductRequest: SKProductsRequest?
    var onCompleted: (() -> Void)?
    
    fileprivate func fetchAppleProducts(appleProductIds identifiers: [String]) {
        // Create a set for the product identifiers.
        let productIdentifiers = Set(identifiers)
        
        // Initialize the product request with the above identifiers.
        self.appleProductRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        self.appleProductRequest?.delegate = self
        
        // Send the request to the App Store.
        self.appleProductRequest?.start()
        
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.logger.info("Product request did return")
        
        // products contains products whose identifiers have been recognized by the App Store. As such, they can be purchased.
        if !response.products.isEmpty {
            self.logger.info("Found \(response.products.count): \(response.products)")
            availableAppleProducts = response.products
            //            storeResponse.append(Section(type: .availableProducts, elements: availableProducts))
            //            self.updateProductButtons()
        }
        
        // invalidProductIdentifiers contains all product identifiers not recognized by the App Store.
        if !response.invalidProductIdentifiers.isEmpty {
            self.logger.warn("Fouond invalid products: \(response.invalidProductIdentifiers)")
            self.invalidAppleProductIds = response.invalidProductIdentifiers
            //            storeResponse.append(Section(type: .invalidProductIdentifiers, elements: invalidProductIdentifiers))
        }
        
        self.onCompleted?()
    }
}
