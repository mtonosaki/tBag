//
//  AppController.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/20.
//

import SwiftUI
import SwiftData
import Tono

class AppController: ObservableObject {
    @Published var accountId: String = ""
    @Published var path = NavigationPath()
    
    private var cacheRsa: Rsa?
    private var cacheAccountId: String?
    private var cachePublicKey: Base64String?
    
    enum Error: Swift.Error {
        case blankAccountID
    }
    
    static let sample = AppController(accountId: "ffffffff-1111-2222-3333-444455556666")
    static let sampleNoAccount = AppController()
    
    init() {
        
    }
    
    init(accountId: String) {
        self.accountId = accountId
    }
    
    var myRsa: Rsa {
        get throws {
            if accountId.isEmpty {
                throw Error.blankAccountID
            }
            if let cacheRsa = cacheRsa {
                if cacheAccountId == accountId {
                    return cacheRsa
                }
            }
            cacheRsa = Rsa(nameMain: "com.tomarika.tBag", nameSub: accountId)
            cacheAccountId = accountId
            return cacheRsa!
        }
    }
    
    var myPublicKey: Base64String {
        get throws {
            if let cachePublicKey = cachePublicKey {
                if cacheAccountId == accountId {
                    return cachePublicKey
                }
            }
            cachePublicKey = try myRsa.getMyPublicKey()
            return cachePublicKey!
        }
    }
}
