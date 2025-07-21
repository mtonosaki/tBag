//
//  ContentView.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/07.
//

import SwiftUI
import SwiftData

struct PasswordListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appController: AppController
    @Query(filter: #Predicate<Item>{ $0.type == "pw"}, sort: \Item.sortKey) private var items: [Item]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        PasswordEditorView(item)
                    } label: {
                        if item.caption.isEmpty {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        } else {
                            Text(item.caption)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(accountId: appController.accountId, type: .Password)
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}


#Preview {
    PasswordListView()
        .modelContainer(for: Item.self, inMemory: true)
}
