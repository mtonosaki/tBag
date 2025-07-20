//
//  KeychainStore.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/20.
//

import Foundation

class KeychainStore {
    static let shared = KeychainStore(accountName: "tBag")

    let accountName: String
    
    private init(accountName: String) {
        self.accountName = accountName
    }
    
    func set(_ key: String, _ string: String) -> Bool {
        let data = string.data(using: .utf8)!
        return set(key, data: data)
    }
    
    func set(_ key: String, data: Data) -> Bool {
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: key,
            kSecAttrAccount: self.accountName,
        ] as CFDictionary
        
        let matchingStatus = SecItemCopyMatching(query, nil)
        switch matchingStatus {
            case errSecItemNotFound:
                let status = SecItemAdd(query, nil)
                return status == noErr
            case errSecSuccess:
                SecItemUpdate(query, [kSecValueData as String: data] as CFDictionary)
                return true
            default:
                return false
        }
    }
    
    func get(_ key: String) -> String? {
        let query = [
            kSecAttrService: key,
            kSecAttrAccount: self.accountName,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        
        if let data = (result as? Data) {
            return String(data: data, encoding: .utf8)
        } else {
            return nil
        }
    }
    
    func delete(key: String) -> Bool {
        let query = [
            kSecAttrService: key,
            kSecAttrAccount: self.accountName,
            kSecClass: kSecClassGenericPassword,
        ] as CFDictionary
        
        let status = SecItemDelete(query)
        return status == noErr
    }
}
