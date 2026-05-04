//
//  Item.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/07.
//

import Foundation
import SwiftData
import Tono

typealias AttributeKey = String

@Model
final class Item: Codable, Hashable {
    var id: PlainString = UUID().uuidString
    var ownerId: PlainString = "no-id"
    var type: PlainString = ItemType.planeText.rawValue
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var sortValue: PlainString = ""
    var caption: PlainString = ""
    var iconFileName: PlainString?
    var attributes: [AttributeKey: [AttributeData]] = [:]

    public enum AttributeKeys: String {
        case tags
        case accountId
        case password
        case email
        case remarks
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }
    
    init() {
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.ownerId = try container.decode(String.self, forKey: .ownerId)
        self.type = try container.decode(String.self, forKey: .type)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        self.sortValue = try container.decode(String.self, forKey: .sortValue)
        self.caption = try container.decode(String.self, forKey: .caption)
        self.iconFileName = try container.decodeIfPresent(String.self, forKey: .iconFileName)
        self.attributes = try container.decode([AttributeKey: [AttributeData]].self, forKey: .attributes)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ownerId, forKey: .ownerId)
        try container.encode(type, forKey: .type)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encode(sortValue, forKey: .sortValue)
        try container.encode(caption, forKey: .caption)
        try container.encodeIfPresent(iconFileName, forKey: .iconFileName)
        try container.encode(attributes, forKey: .attributes)
    }

    func isEmpty() -> Bool {
        return caption.isEmpty
    }
}

struct AttributeData: Codable, Hashable {
    var createdAt: Date
    var updatedAt: Date
    var encryptedValue: SealedEnvelopeBase64String
    
    init(encryptedValue: SealedEnvelopeBase64String){
        self.createdAt = Date()
        self.updatedAt = self.createdAt
        self.encryptedValue = encryptedValue
    }

    init(createdAt: Date, encryptedValue: SealedEnvelopeBase64String){
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.encryptedValue = encryptedValue
    }
}

public enum ItemType: String {
    case planeText = "text"
    case password = "pw"
    case system = "sys"
}

public enum TagGroups: String {
    case home = "#home"
    case office = "#office"
    case deleted = "#deleted"
}

private enum CodingKeys: String, CodingKey {
    case id
    case ownerId
    case type
    case createdAt
    case updatedAt
    case sortValue
    case caption
    case iconFileName
    case attributes
    case attributeHistories
}

