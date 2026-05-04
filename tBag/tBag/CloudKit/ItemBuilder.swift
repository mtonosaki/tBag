//
//  ItemBuilder.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2026/05/04.
//


import Tono
import Foundation

struct ItemBuilder {
    struct ClipboardEntry: Decodable {
        let value, dt: String
        
        enum CodingKeys: String, CodingKey { case value = "Value", dt = "DT" }
    }
    
    struct ClipboardUniversalData: Decodable {
        let caption, captionRubi, accountId, email, password, memo, isFilterHome, isFilterWork, isDeleted: [ClipboardEntry]?
        
        enum CodingKeys: String, CodingKey {
            case caption = "Caption", captionRubi = "CaptionRubi", accountId = "AccountID", email = "Email", password = "Password", memo = "Memo"
            case isFilterHome, isFilterWork, isDeleted = "IsDeleted"
        }
    }
    
    struct ClipboardJSON: Decodable {
        let id: String
        let universalData: ClipboardUniversalData
        
        enum CodingKeys: String, CodingKey { case id = "ID", universalData = "UniversalData" }
    }

    static func createItem(fromJson jsonData: Data, ownerAccountId: String, myRsa: Rsa) throws -> Item {
        let decoded = try JSONDecoder().decode(ClipboardJSON.self, from: jsonData)
        let data = decoded.universalData
        let salt = "\(ownerAccountId)/\(Info.encryptSalt)"
        let newItem = ItemBuilder.build(ownerId: ownerAccountId, type: .password)
        newItem.id = decoded.id
        newItem.caption = data.caption?.last?.value ?? ""
        newItem.sortValue = data.captionRubi?.last?.value ?? ""
        
        func encrypt(_ key: Item.AttributeKeys, _ values: [ItemBuilder.ClipboardEntry]?) {
            if !newItem.attributes.contains(where: { $0.key == key.rawValue }) {
                newItem.attributes[key.rawValue] = []
            }
            // try? CryptoService.shared.seal(plainText: val, recipientPublicKey: myRsa.getMyPublicKey(), salt: salt) else { return }
            // TODO: ここで、クリップボードの値をItem形式で保存する
        }
        encrypt(.accountId, data.accountId)
        encrypt(.password, data.password)
        encrypt(.email, data.email)
        encrypt(.remarks, data.memo)
        encrypt(.tags, [])
                
        return newItem
    }

    static func createNewPasswordItem(ownerAccountId: String, myRsa: Rsa) -> Item {
        let newItem = ItemBuilder.build(ownerId: ownerAccountId, type: .password)
        let salt = "\(ownerAccountId)/\(Info.encryptSalt)"
        let tags = [TagGroups.home.rawValue, TagGroups.office.rawValue].sorted().joined(separator: ",")
        
        if let sealed = try? CryptoService.shared.seal(plainText: tags, recipientPublicKey: myRsa.getMyPublicKey(), salt: salt) {
            let history = [AttributeData(encryptedValue: sealed)]
            newItem.attributes[Item.AttributeKeys.tags.rawValue] = history
        }
        return newItem
    }
    
    static func build(
        ownerId: String,
        type: ItemType,
        createdAt: Date,
        sortValue: String,
        caption: String,
        attributes: [AttributeKey: [AttributeData]]
    ) -> Item {
        var newItem = Item()
        newItem.ownerId = ownerId
        newItem.type = type.rawValue
        newItem.createdAt = createdAt
        newItem.updatedAt = createdAt
        newItem.sortValue = sortValue
        newItem.caption = caption
        newItem.attributes = attributes
        return newItem
    }
    
    static func build(ownerId: String, type: ItemType) -> Item {
        var newItem = Item()
        newItem.ownerId = ownerId
        newItem.type = type.rawValue
        return newItem
    }
    
    static func build(ownerId: String) -> Item {
        var newItem = Item()
        newItem.ownerId = ownerId
        return newItem
    }
}
