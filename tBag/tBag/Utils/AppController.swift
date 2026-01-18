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
            return Rsa(nameMain: "com.tomarika.tBag", nameSub: accountId)
        }
    }
    
    var myPublicKey: Base64String {
        get throws {
            return try myRsa.getMyPublicKey()
        }
    }
}
