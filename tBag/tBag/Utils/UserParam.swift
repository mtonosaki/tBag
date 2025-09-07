//
//  UserParam.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-07.
//

import SwiftData

struct UserParam {
    static func get(modelContext: ModelContext, items: [Item], ownerId: String) -> Item {
        guard let item = items.first(where: {$0.id == ownerId}) else {
            let userParam = Item(ownerId: ownerId)
            modelContext.insert(userParam)
            return userParam
        }
        return item
    }
}
