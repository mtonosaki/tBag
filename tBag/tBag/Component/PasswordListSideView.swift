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
    
    @State private var isHome = true
    @State private var isOffice = true
    @State private var isDeleted = false
    
    var body: some View {
        let rsa = appController.myRsaNoThrow
        ScrollViewReader { proxy in
            List(selection: $selectedItemId) {
                ForEach(groupedItems.keys.sorted(), id: \.self) { firstLetter in
                    Section(header: Text(firstLetter)) {
                        let sectionItems = groupedItems[firstLetter]?
                            .filter({
                                [!self.isHome, !self.isOffice, !self.isDeleted, !PasswordFilter.isHome($0, rsa: rsa), !PasswordFilter.isOffice($0, rsa: rsa), !PasswordFilter.isDeleted($0, rsa: rsa)].allSatisfy({$0})
                                || [self.isHome, self.isOffice, self.isDeleted].allSatisfy({$0})
                                || self.isHome && PasswordFilter.isHome($0, rsa: rsa)
                                || self.isOffice && PasswordFilter.isOffice($0, rsa: rsa)
                                || self.isDeleted && PasswordFilter.isDeleted($0, rsa: rsa)
                            })
                            .sorted(by: {$0.caption < $1.caption})
                        ?? []
                        ForEach(sectionItems) { item in
                            PasswordListRecord(item).tag(item.id)
                        }
                        .onDelete { indexSet in
                            deleteItems(offsets: indexSet, sectionItems: sectionItems)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem {
                    HStack {
                        Toggle(isOn: $isHome) {
                            Image(systemName: isHome ? "house" : "house.slash")
                        }
                        Toggle(isOn: $isOffice) {
                            Image(systemName: isOffice ? "network" : "network.slash")
                        }
                        Toggle(isOn: $isDeleted) {
                            Image(systemName: isDeleted ? "trash" : "trash.slash")
                        }
                    }
                }
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
        do {
            let rsa = try appController.myRsa
            let newItem = ItemBuilder.createNewPasswordItem(ownerAccountId: appController.accountId, myRsa: rsa)
            withAnimation {
                modelContext.insert(newItem)
                selectedItemId = newItem.id
            }
        } catch {
            print("Failed to add item: \(error)")
        }
    }
    
    private func deleteItems(offsets: IndexSet, sectionItems: [Item]) {
        withAnimation {
            for index in offsets {
                let itemToDelete = sectionItems[index]
                if selectedItemId == itemToDelete.id {
                    selectedItemId = nil
                }
                modelContext.delete(itemToDelete)
            }
        }
    }
}
