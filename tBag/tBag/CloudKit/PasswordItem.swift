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
        let newItem = Item(ownerId: ownerAccountId, type: .password)
        newItem.id = decoded.id
        newItem.caption = data.caption?.last?.value ?? ""
        newItem.sortValue = data.captionRubi?.last?.value ?? ""
        
        func encrypt(_ key: Item.AttributeKeys, _ val: String?) {
            guard let val = val, !val.isEmpty, let sealed = try? CryptoService.shared.seal(plainText: val, recipientPublicKey: myRsa.getMyPublicKey(), salt: salt) else { return }
            newItem.attributes[key.rawValue] = AttributeData(encryptedValue: sealed, timestamp: Date())
        }
        encrypt(.accountId, data.accountId?.last?.value)
        encrypt(.password, data.password?.last?.value)
        encrypt(.email, data.email?.last?.value)
        encrypt(.remarks, data.memo?.last?.value)
        
        var tags: [String] = []
        if data.isFilterHome?.last?.value.lowercased() == "true" { tags.append(Item.Groups.home.rawValue) }
        if data.isFilterWork?.last?.value.lowercased() == "true" { tags.append(Item.Groups.office.rawValue) }
        if data.isDeleted?.last?.value.lowercased() == "true" { tags.append(Item.Groups.deleted.rawValue) }
        if !tags.isEmpty { encrypt(.tags, tags.sorted().joined(separator: ",")) }
        
        return newItem
    }

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
