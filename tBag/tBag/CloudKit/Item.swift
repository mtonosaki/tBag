//
//  Item.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/07.
//

import Foundation
import SwiftData
import Tono

struct AttributeData: Codable, Hashable {
    var encryptedValue: String
    var timestamp: Date
}

@Model
final class Item: Codable, Hashable {
    typealias AttributeKey = String
    typealias PlaneString = String

    var id: String = UUID().uuidString
    var ownerId: String = "no-id"
    var type: String = ItemType.planeText.rawValue
    var timestamp: Date = Date()
    var sortValue: String = ""
    var caption: String = ""
    var iconFileName: String?
    var attributes: [AttributeKey: AttributeData] = [:]
    var attributeHistories: [AttributeKey: [AttributeData]] = [:]

    public enum GeneralAttributeKeys: String {
        case tags
    }

    public enum PasswordAttributeKeys: String {
        case accountId
        case password
        case email
    }

    public enum PasswordFilter: String {
        case home = "#home"
        case office = "#office"
        case deleted = "#deleted"
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
        case iconFileName
        case attributes
        case attributeHistories
    }

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
        self.iconFileName = try container.decodeIfPresent(String.self, forKey: .iconFileName)
        self.attributes = try container.decode([AttributeKey: AttributeData].self, forKey: .attributes)
        self.attributeHistories = try container.decodeIfPresent([AttributeKey: [AttributeData]].self, forKey: .attributeHistories) ?? [:]
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ownerId, forKey: .ownerId)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(sortValue, forKey: .sortValue)
        try container.encode(caption, forKey: .caption)
        try container.encodeIfPresent(iconFileName, forKey: .iconFileName)
        try container.encode(attributes, forKey: .attributes)
        try container.encode(attributeHistories, forKey: .attributeHistories)
    }

    init(ownerId: String, type: ItemType, timestamp: Date, sortValue: String, caption: String, attributes: [String: AttributeData]) {
        self.ownerId = ownerId
        self.type = type.rawValue
        self.timestamp = timestamp
        self.sortValue = sortValue
        self.caption = caption
        self.attributes = attributes
    }
    
    init(ownerId: String, type: ItemType) {
        self.ownerId = ownerId
        self.type = type.rawValue
        self.timestamp = Date()
    }
    
    init(ownerId: String) {
        self.id = ownerId
        self.ownerId = ownerId
        self.type = ItemType.system.rawValue
        self.timestamp = Date()
        self.sortValue = "[user parameter]"
        self.caption = "[user parameter]"
    }
    
    func isEmpty() -> Bool {
        return caption.isEmpty
    }
}
