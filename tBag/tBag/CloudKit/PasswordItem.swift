//
//  PasswordItem.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2026-01-26.
//

import Tono
import Foundation

extension Item {
    func isHome(rsa: Rsa) -> Bool {
        containsTag(Item.Groups.home.rawValue, rsa: rsa)
    }
    func isOffice(rsa: Rsa) -> Bool {
        containsTag(Item.Groups.office.rawValue, rsa: rsa)
    }
    func isDeleted(rsa: Rsa) -> Bool {
        containsTag(Item.Groups.deleted.rawValue, rsa: rsa)
    }
    
    private func containsTag(_ tag: String, rsa: Rsa) -> Bool {
        guard let attributeData = self.attributes[AttributeKeys.tags.rawValue] else { return false }
        do {
            let tagsString = try CryptoService.shared.open(sealedString: attributeData.encryptedValue, myRsa: rsa)
            let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            return tags.contains(tag)
        } catch {
            return false
        }
    }
}

struct ItemBuilder {
    static func createNewPasswordItem(ownerAccountId: String, myRsa: Rsa) -> Item {
        let newItem = Item(ownerId: ownerAccountId, type: .password)
        let salt = "\(ownerAccountId)/\(Info.encryptSalt)"
        let tags = [Item.Groups.home.rawValue, Item.Groups.office.rawValue].sorted().joined(separator: ",")
        
        if let sealed = try? CryptoService.shared.seal(plainText: tags, recipientPublicKey: myRsa.getMyPublicKey(), salt: salt) {
            newItem.attributes[Item.AttributeKeys.tags.rawValue] = AttributeData(encryptedValue: sealed, timestamp: Date())
        }
        return newItem
    }
}
