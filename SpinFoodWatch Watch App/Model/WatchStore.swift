//
//  WatchStore.swift
//  SpinFoodWatch Watch App
//
//  Created by Giuseppe Cosenza on 26/07/25.
//

import Foundation
import WatchConnectivity
import SwiftUI

@Observable
class WatchStore: NSObject, WCSessionDelegate {
    var purchasedProductIDs: [String] = []
    
    override init() {
        super.init()
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let purchasedIDs = message["purchasedProducts"] as? [String] {
            DispatchQueue.main.async {
                self.purchasedProductIDs = purchasedIDs
                print("Acquisti ricevuti: \(purchasedIDs)")
            }
        }
    }
}
