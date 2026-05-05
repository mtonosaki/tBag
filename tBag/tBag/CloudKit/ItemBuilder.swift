//
//  ItemBuilder.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2026/05/05.
//

import Foundation
import Tono

struct ItemBuilder {
    
    static func build(ownerAccountId: String, myRsa: Rsa) -> Item {
        let newItem = Item(ownerId: ownerAccountId, type: .password)
        let salt = "\(ownerAccountId)/\(Info.encryptSalt)"
        let tags = [TagGroups.home.rawValue, TagGroups.office.rawValue].sorted().joined(separator: ",")
        
        if let sealed = try? CryptoService.shared.seal(plainText: tags, recipientPublicKey: myRsa.getMyPublicKey(), salt: salt) {
            let history = [AttributeData(encryptedValue: sealed)]
            newItem.attributes[Item.AttributeKeys.tags.rawValue] = history
        }
        return newItem
    }
}
