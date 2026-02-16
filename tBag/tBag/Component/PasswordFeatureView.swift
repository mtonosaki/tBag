//
//  ContentView.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/07.
//

import SwiftUI
import SwiftData

struct PasswordFeatureView: View {
    @Binding var page: PageType
    @Query(filter: #Predicate<Item>{ $0.type == "pw"}) private var items: [Item]
    @State private var selectedItemId: String?

    var body: some View {
        NavigationSplitView {
            PasswordListSideView(page: $page, selectedItemId: $selectedItemId)
            
        } detail: {
            if let selectedId = selectedItemId {
                if let selectedItem = items.first(where: { $0.id == selectedId }) {
                    PasswordEditView(selectedItem)
                        .id(selectedItem.id)
                } else {
                    Text("Select an item")
                }
            } else {
                Text("Select an item")
            }
        }
    }
}

#Preview {
    @Previewable @State var page: PageType = .password
    PasswordFeatureView(page: $page)
        .modelContainer(for: Item.self, inMemory: true)
}
