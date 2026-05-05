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
    
    func getPlainValue(_ sealedString: SealedEnvelopeBase64String, defaultString: PlainString = "") -> PlainString {
        guard let myRsa = try? appController.myRsa else {
            return defaultString
        }
        guard let plainText = try? cryptoService.open(sealedString: sealedString, myRsa: myRsa) else {
            return defaultString
        }
        return plainText
    }
    
    func getPlainValue(key: AttributeKey, defaultString: PlainString = "") -> PlainString {
        if let cached = planeTextCache[key] {
            return cached
        }
        
        guard let myRsa = try? appController.myRsa,
              let attributeData = item.attributes[key] else {
            return defaultString
        }
        guard attributeData.isEmpty == false else {
            return defaultString
        }
        guard let plainText = try? cryptoService.open(sealedString: attributeData[0].encryptedValue, myRsa: myRsa) else {
            return defaultString
        }
        planeTextCache[key] = plainText
        return plainText
    }
    
    func setPlainValue(key: String, value: String) {
        guard let myPublicKey = try? appController.myPublicKey else { return }
        
        do {
            let salt = "\(appController.accountId)/\(Info.encryptSalt)"
            let sealedString = try cryptoService.seal(plainText: value, recipientPublicKey: myPublicKey, salt: salt)
            let now = Date()
            
            if !item.attributes.contains(where: { $0.key == key }) {
                item.attributes[key] = []
            }
            var history = item.attributes[key]!
            if history.count == 0 {
                let newAttribute = AttributeData(encryptedValue: sealedString)
                history.insert(newAttribute, at: 0)
                print("---- Attribute: NEW")

            } else {
                let diffSeconds = now.timeIntervalSince(history[0].updatedAt)
                if diffSeconds < 86400 {
                    history[0].encryptedValue = sealedString
                    history[0].updatedAt = Date()
                    print("---- Attribute: UPDATE")

                } else {
                    let newAttribute = AttributeData(encryptedValue: sealedString)
                    history.insert(newAttribute, at: 0)
                    print("---- Attribute: ADD")
                }
            }
            item.attributes[key] = history
            
            planeTextCache[key] = value
            
        } catch {
            print("Failed to encrypt: \(error)")
        }
    }
    
    func containsTag(_ tag: String) -> Bool {
        let tagsString = getPlainValue(key: Item.AttributeKeys.tags.rawValue)
        let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        return tags.contains(tag)
    }
    
    func toggleTag(_ tag: String) {
        let tagsString = getPlainValue(key: Item.AttributeKeys.tags.rawValue)
        var tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        
        if tags.contains(tag) {
            tags.removeAll { $0 == tag }
        } else {
            tags.append(tag)
        }
        
        let newTagsString = tags.sorted().joined(separator: ",")
        setPlainValue(key: Item.AttributeKeys.tags.rawValue, value: newTagsString)
    }
}
