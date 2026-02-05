//
//  Item.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/07.
//

import Foundation
import SwiftData
import Tono

@Model
final class Item: Codable, Hashable {
    typealias AttributeKey = String
    typealias AttributeEncryptString = String
    typealias PlaneString = String
    
    var id: String = UUID().uuidString
    var ownerId: String = "no-id"
    var type: String = ItemType.planeText.rawValue
    var timestamp: Date = Date()
    var sortValue: String = ""
    var caption: String = ""
    
    public enum GeneralAttributeKeys: String {
        case tags
    }

    public enum ItemType: String {
        case planeText = "text"
        case password = "pw"
        case system = "sys"
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case ownerId
        case type
        case timestamp
        case sortValue
        case caption
        case attributes
    }
    
    private var attributes: [AttributeKey: SealedEnvelopeBase64String] = [:]
    
    @Transient private var attributePlaneStringCache: [AttributeKey: String] = [:]
    @Transient private var attributeSealedBase64Cache: [AttributeKey: SealedEnvelopeBase64String] = [:]
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(String.self, forKey: .id)
        self.ownerId = try container.decode(String.self, forKey: .ownerId)
        self.type = try container.decode(String.self, forKey: .type)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.sortValue = try container.decode(String.self, forKey: .sortValue)
        self.caption = try container.decode(String.self, forKey: .caption)
        self.attributes = try container.decode([AttributeKey: SealedEnvelopeBase64String].self, forKey: .attributes)
        
        self.attributePlaneStringCache = [:]
        self.attributeSealedBase64Cache = [:]
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ownerId, forKey: .ownerId)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(sortValue, forKey: .sortValue)
        try container.encode(caption, forKey: .caption)
        try container.encode(attributes, forKey: .attributes)

        self.attributePlaneStringCache = [:]
        self.attributeSealedBase64Cache = [:]
    }

    init(ownerId: String, type: ItemType, timestamp: Date, sortValue: String, caption: String, attrubutes: [String: String]) {
        self.ownerId = ownerId
        self.type = type.rawValue
        self.timestamp = timestamp
        self.sortValue = sortValue
        self.caption = caption
        self.attributes = attrubutes
        attributePlaneStringCache.removeAll()
        attributeSealedBase64Cache.removeAll()
    }
    
    init(ownerId: String, type: ItemType) {
        self.ownerId = ownerId
        self.type = type.rawValue
        self.timestamp = Date()
        attributePlaneStringCache.removeAll()
        attributeSealedBase64Cache.removeAll()
    }
    
    init(ownerId: String) {
        self.id = ownerId
        self.ownerId = ownerId
        self.type = ItemType.system.rawValue
        self.timestamp = Date()
        self.sortValue = "[user parameter]"
        self.caption = "[user parameter]"
        attributePlaneStringCache.removeAll()
        attributeSealedBase64Cache.removeAll()
    }
    
    func isEmpty() -> Bool {
        return caption.isEmpty
    }
    
    func set(key: AttributeKey, planeText: PlaneString, recipientPublicKey: Base64String, owner: String) throws {
        let salt = "\(owner)/\(Info.encryptSalt)"
        let sealedEnvelop = try DigitalEnvelope.seal(plainText: planeText, recipientPublicKeyBase64: recipientPublicKey, salt: salt)
        attributes[key] = sealedEnvelop
        attributeSealedBase64Cache[key] = sealedEnvelop
        attributePlaneStringCache[key] = planeText
    }
    
    func get(key: AttributeKey, myRsa: Rsa) throws -> PlaneString {
        if let cachedPlaneText = attributePlaneStringCache[key] {
            if attributePlaneStringCache[key] == attributes[key] {
                return cachedPlaneText
            }
        }
        let planeText = try DigitalEnvelope.open(sealedString: attributes[key]!, myRsa: myRsa)
        attributePlaneStringCache[key] = planeText
        attributeSealedBase64Cache[key] = attributes[key] ?? ""
        return planeText
    }
    
    func get(key: AttributeKey, myRsa: Rsa?, defaultString: PlaneString) -> PlaneString {
        if let cachedPlaneText = attributePlaneStringCache[key] {
            return cachedPlaneText
        }
        guard let myRsa = myRsa else {
            return defaultString
        }
        guard let sealedString = attributes[key] else {
            return defaultString
        }
        guard let planeText = try? DigitalEnvelope.open(sealedString: sealedString, myRsa: myRsa) else {
            return defaultString
        }
        attributePlaneStringCache[key] = planeText
        attributeSealedBase64Cache[key] = sealedString
        return planeText
    }
    
    func containsTag(_ tag: String, myRsa: Rsa) -> Bool {
        let tagsString = get(key: GeneralAttributeKeys.tags.rawValue, myRsa: myRsa, defaultString: "")
        let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces)}
        return tags.contains(tag)
    }
    
    func addTag(_ tag: String, myRsa: Rsa, owner: String) {
        let tagsString = get(key: GeneralAttributeKeys.tags.rawValue, myRsa: myRsa, defaultString: "")
        let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces)}.filter { $0 != tag }
        let newTags = (tags + [tag]).sorted()
        let newTagsString = newTags.joined(separator: ",")
        try? set(key: GeneralAttributeKeys.tags.rawValue, planeText: newTagsString, recipientPublicKey: myRsa.getMyPublicKey(), owner: owner)
    }
    
    func removeTag(_ tag: String, myRsa: Rsa, owner: String) {
        let tagsString = get(key: GeneralAttributeKeys.tags.rawValue, myRsa: myRsa, defaultString: "")
        let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces)}.filter { $0 != tag }
        let newTags = tags.sorted()
        let newTagsString = newTags.joined(separator: ",")
        try? set(key: GeneralAttributeKeys.tags.rawValue, planeText: newTagsString, recipientPublicKey: myRsa.getMyPublicKey(), owner: owner)
    }
}
