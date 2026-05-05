//
//  PreviewData.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-09.
//

import SwiftData

#if DEBUG
func makeSampleAppController() -> AppController {
    let sampleAppController = AppController()
    sampleAppController.accountId = "111-preview-hoge-2222-3333-4444"
    return sampleAppController
}

@MainActor func makeSampleModelContainer() -> ModelContainer? {
    do {
        let schema = Schema([Item.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContainer.mainContext.insert(Item.makePasswordDummy("hoge"))
        modelContainer.mainContext.insert(Item.makePasswordDummy("fuga"))
        modelContainer.mainContext.insert(Item.makePasswordDummy("piyo"))
        return modelContainer
    } catch {
        print("ERROR-PREVIEW")
    }
    return nil
}

extension Item {
    static func makePasswordDummy(_ caption: String) -> Item {
        let item = Item(ownerId: "hoge-owner")
        item.caption = caption
        item.sortValue = caption
        item.type = ItemType.password.rawValue
        return item
    }
}
#endif
