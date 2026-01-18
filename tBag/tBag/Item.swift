//
//  Item.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/07.
//

import Foundation
import SwiftData

@Model
final class Item: Encodable, Hashable {
    var id: String = UUID().uuidString
    var ownerId: String = "no-id"
    var type: String = ItemType.planeText.rawValue
    var timestamp: Date = Date()
    var sortKey: String = ""
    var caption: String = ""
    var attributes: [String: String] = [:]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case ownerId
        case type
        case timestamp
        case sortKey
        case caption
        case attributes
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(ownerId, forKey: .ownerId)
        try container.encode(type, forKey: .type)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(sortKey, forKey: .sortKey)
        try container.encode(caption, forKey: .caption)
        try container.encode(attributes, forKey: .attributes)
    }

    init(ownerId: String, type: ItemType, timestamp: Date, sortKey: String, caption: String, attrubutes: [String: String]) {
        self.ownerId = ownerId
        self.type = type.rawValue
        self.timestamp = timestamp
        self.sortKey = sortKey
        self.caption = caption
        self.attributes = attrubutes
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
        self.sortKey = "[user parameter]"
        self.caption = "[user parameter]"
    }
    
    func isEmpty() -> Bool {
        return caption.isEmpty
    }
    
    func containsTag(_ tag: String) -> Bool {
        guard let tagsString = attributes["tags"] else { return false }
        let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces)}
        return tags.contains(tag)
    }
    
    func addTag(_ tag: String) {
        let tagsString = attributes["tags"] ?? ""
        let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces)}.filter { $0 != tag }
        let newTags = (tags + [tag]).sorted()
        let newTagsString = newTags.joined(separator: ",")
        attributes["tags"] = newTagsString
    }
    
    func removeTag(_ tag: String) {
        let tagsString = attributes["tags"] ?? ""
        let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces)}.filter { $0 != tag }
        let newTags = tags.sorted()
        let newTagsString = newTags.joined(separator: ",")
        attributes["tags"] = newTagsString
    }
}

public enum ItemType: String {
    case planeText = "text"
    case password = "pw"
    case system = "sys"
}

struct ItemBuilder {
    static func createNewPasswordItem(ownerAccountId: String) -> Item {
        let newItem = Item(ownerId: ownerAccountId, type: .password)
        newItem.addTag("#home")
        newItem.addTag("#office")
        return newItem
    }
}
