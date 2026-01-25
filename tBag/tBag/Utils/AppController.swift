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
    
    static let sampleNoAccount = AppController()
    static private let errorRsa = RsaLocalKeyChain(nameMain: "com.tomarika.tBag", nameSub: "error")
    
    init() {
        guard let savedId = KeychainStore.shared.get("accountId") else {
            print("ERROR!!: Could not get accountId from KeyChain store")
            return
        }
        self.accountId = savedId
    }
    
    init(accountId: String) {
        self.accountId = accountId
    }
    
    var myRsaNoThrow: Rsa {
        do {
            return try myRsa
        } catch {
            print("Fatal error in myRsaNoThrow")
            return AppController.errorRsa
        }
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
            let accessGroupName = "\(Info.teamId).com.tomarika.tBag.shared"
            print("Shared KeyChain Access Group : \(accessGroupName)")
            cacheRsa = RsaSharedKeyChain(nameMain: "com.tomarika.tBag", nameSub: accountId, accessGroup: accessGroupName)
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
