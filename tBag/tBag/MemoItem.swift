//
//  Item.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/07.
//

import Foundation
import SwiftData

@Model
final class MemoItem: Hashable {
    var id: String
    var createdAt: Date
    var timestamp: Date
    
    init() {
        self.id = UUID().uuidString
        self.createdAt = Date()
        self.timestamp = Date()
    }
    static func == (lhs: MemoItem, rhs: MemoItem) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
