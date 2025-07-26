//
//  WatchConnectivityManager.swift
//  SpinFood
//
//  Created by Giuseppe Cosenza on 26/07/25.
//

import Foundation
import WatchConnectivity

final class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    
    func sendPurchasedProducts(_ ids: [String]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["purchasedProducts": ids], replyHandler: nil) { error in
                print("Errore invio messaggio al Watch: \(error)")
            }
        }
    }
    
    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {}
}
