//
//  PasswordEditViewModel.swift
//  tBag
//
//  Created by Gemini CLI on 2026-04-26.
//

import SwiftUI
import SwiftData
import Tono

@Observable
class PasswordEditViewModel {
    var item: Item
    var cryptoService: CryptoServiceProtocol
    var appController: AppController
    
    private var planeTextCache: [String: String] = [:]

    init(item: Item, appController: AppController, cryptoService: CryptoServiceProtocol = CryptoService.shared) {
        self.item = item
        self.appController = appController
        self.cryptoService = cryptoService
    }
    
    func getPlainValue(key: String, defaultString: String = "") -> String {
        if let cached = planeTextCache[key] {
            return cached
        }
        
        guard let myRsa = try? appController.myRsa,
              let sealedString = item.attributes[key] else {
            return defaultString
        }
        
        do {
            let plainText = try cryptoService.open(sealedString: sealedString, myRsa: myRsa)
            planeTextCache[key] = plainText
            return plainText
        } catch {
            return defaultString
        }
    }
    
    func setPlainValue(key: String, value: String) {
        guard let myPublicKey = try? appController.myPublicKey else { return }
        
        do {
            let salt = "\(appController.accountId)/\(Info.encryptSalt)"
            let sealed = try cryptoService.seal(plainText: value, recipientPublicKey: myPublicKey, salt: salt)
            item.attributes[key] = sealed
            planeTextCache[key] = value
            item.timestamp = Date()
        } catch {
            print("Failed to encrypt: \(error)")
        }
    }
    
    func containsTag(_ tag: String) -> Bool {
        let tagsString = getPlainValue(key: Item.GeneralAttributeKeys.tags.rawValue)
        let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return tags.contains(tag)
    }
    
    func toggleTag(_ tag: String) {
        let tagsString = getPlainValue(key: Item.GeneralAttributeKeys.tags.rawValue)
        var tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
        if tags.contains(tag) {
            tags.removeAll { $0 == tag }
        } else {
            tags.append(tag)
        }
        
        let newTagsString = tags.sorted().joined(separator: ",")
        setPlainValue(key: Item.GeneralAttributeKeys.tags.rawValue, value: newTagsString)
    }
}
