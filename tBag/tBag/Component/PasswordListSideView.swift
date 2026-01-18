//
//  PasswordListSideView.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-07.
//

import SwiftUI

struct PasswordListSideView: View {
    @Binding var page: PageType
    @Binding var selectedItemId: String?
    @EnvironmentObject var appController: AppController
    @Environment(\.modelContext) private var modelContext
    var groupedItems: [String: [Item]]
    var sectionHeaders: [String]
    
    var body: some View {
        ScrollViewReader { proxy in
            List(selection: $selectedItemId) {
                ForEach(groupedItems.keys.sorted(), id: \.self) { firstLetter in
                    Section(header: Text(firstLetter)) {
                        ForEach((groupedItems[firstLetter]?.sorted(by: {$0.caption < $1.caption}) ?? [])) { item in
                            PasswordListRecord(item).tag(item.id)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        addItem()
                    }  label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
                ToolbarItem {
                    Button {
                        page = .sync
                    } label: {
                        Label("Sync", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                    }
                }
            }
            .overlay(alignment: .trailing) {
                VStack(spacing: 0) {
                    ForEach(sectionHeaders, id: \.self) { firstLetter in
                        ScrollLetter(firstLetter: firstLetter, proxy: proxy)
                    }
                }
#if os(macOS)
                .padding(.trailing, 8)
#endif
            }
        }
    }
    
    private func addItem() {
        let newItem = ItemBuilder.createNewPasswordItem(ownerAccountId: appController.accountId)
        withAnimation {
            modelContext.insert(newItem)
            selectedItemId = newItem.id
        }
    }
}
