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
    @Query(filter: #Predicate<Item>{ $0.type == "pw"}) private var items: [Item]

    private var groupedItems: [String: [Item]] {
        var grouped: [String: [Item]] = [:]
        for item in items {
            if let firstCharacter = item.caption.first {
                let key = String(firstCharacter).uppercased()
                grouped[key, default: []].append(item)
            } else {
                let key = "!"
                grouped[key, default: []].append(item)
            }
        }
        return grouped
    }
    
    private var sectionHeaders: [String] {
        groupedItems.keys.sorted()
    }
    
    var body: some View {
        NavigationSplitView {
            ScrollViewReader { proxy in
                List {
                    ForEach(groupedItems.keys.sorted(), id: \.self){ firstLetter in
                        Section(header: Text(firstLetter)){
                            ForEach((groupedItems[firstLetter]?.sorted(by: {$0.caption < $1.caption}) ?? [])) { item in
                                NavigationLink {
                                    PasswordEditorView(item)
                                } label: {
                                    PasswordListRecord(item)
                                }
                            }
                            .onDelete(perform: deleteItems)
                        }
                    }
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
                .overlay(alignment: .trailing) {
                    VStack(spacing: 0){
                        ForEach(sectionHeaders, id: \.self){ firstLetter in
                            Text(firstLetter)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical,2)
                                .background(Color.clear)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation {
                                        proxy.scrollTo(firstLetter, anchor: .top)
                                    }
                                }
                        }
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
