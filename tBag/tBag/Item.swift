//
//  Item.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/07.
//

import Foundation
import SwiftData

@Model
final class Item {
    var accountId: String
    var type: String
    var timestamp: Date
    var sortKey: String = ""
    var caption: String = ""
    var attributes: Dictionary<String, String> = [:]
    
    init(accountId: String, type: ItemType, timestamp: Date, sortKey: String, caption: String, attrubutes: Dictionary<String,String>){
        self.accountId = accountId
        self.type = type.rawValue
        self.timestamp = timestamp
        self.sortKey = sortKey
        self.caption = caption
        self.attributes = attrubutes
    }
    
    init(cloneFrom: Item){
        self.accountId = cloneFrom.accountId
        self.type = cloneFrom.type
        self.timestamp = cloneFrom.timestamp
        self.sortKey = cloneFrom.sortKey
        self.caption = cloneFrom.caption
        self.attributes = cloneFrom.attributes
    }
    
    init(accountId: String, type: ItemType = .PlaneText) {
        self.accountId = accountId
        self.timestamp = Date()
        self.type = type.rawValue
    }
    
    func isEmpty() -> Bool {
        return caption.isEmpty
    }
    
    func containsTag(_ tag: String) -> Bool {
        guard let tagsString = attributes["tags"] else { return false }
        let tags = tagsString.split(separator: ",").map{ $0.trimmingCharacters(in: .whitespaces)}
        return tags.contains(tag)
    }
    
    func addTag(_ tag: String) {
        let tagsString = attributes["tags"] ?? ""
        let tags = tagsString.split(separator: ",").map{ $0.trimmingCharacters(in: .whitespaces)}.filter{ $0 != tag }
        let newTags = (tags + [tag]).sorted()
        let newTagsString = newTags.joined(separator: ",")
        attributes["tags"] = newTagsString
    }
    
    func removeTag(_ tag: String) {
        let tagsString = attributes["tags"] ?? ""
        let tags = tagsString.split(separator: ",").map{ $0.trimmingCharacters(in: .whitespaces)}.filter{ $0 != tag }
        let newTags = tags.sorted()
        let newTagsString = newTags.joined(separator: ",")
        attributes["tags"] = newTagsString
    }
}

public enum ItemType: String {
    case PlaneText = "text"
    case Password = "pw"

}
