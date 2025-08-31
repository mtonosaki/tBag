//
//  ContentView.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/07.
//

import SwiftUI
import SwiftData

struct PasswordListView: View {
    @Binding var page: PageType
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appController: AppController
    @Query(filter: #Predicate<Item>{ $0.type == "pw"}) private var items: [Item]
    @State private var selectedItemId: String?

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
                List(selection: $selectedItemId) {
                    ForEach(groupedItems.keys.sorted(), id: \.self){ firstLetter in
                        Section(header: Text(firstLetter)){
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
                    VStack(spacing: 0){
                        ForEach(sectionHeaders, id: \.self){ firstLetter in
                            ScrollLetter(firstLetter: firstLetter, proxy: proxy)
                        }
                    }
                }
            }
        } detail: {
            if let selectedId = selectedItemId {
                if let selectedItem = items.first(where: { $0.id == selectedId }){
                    PasswordEditorView(selectedItem)
                } else {
                    Text("Select an item")
                }
            } else {
                Text("Select an item")
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

struct ScrollLetter: View {
    let firstLetter: String
    let proxy: ScrollViewProxy

    @State var isHover = false
    
    var body: some View {
        Text(firstLetter)
            .font(.custom("Courier New", size: 12))
            .padding(.horizontal, 6)
            .padding(.vertical,4)
            .contentShape(Rectangle())
            .foregroundColor(isHover ?  Color.accentText :  Color.accentColor)
            .background(isHover ? Color.accentColor :  Color.clear)
            .offset(x: isHover ? -4 : 0, y: 0)
            .animation(.easeInOut(duration: 0.2), value: isHover)
            .onHover { isHover in
                withAnimation {
                    self.isHover = isHover
                }
            }
            .onTapGesture {
                withAnimation {
                    proxy.scrollTo(firstLetter, anchor: .top)
                }
            }
    }
}

#Preview {
    @Previewable @State var page: PageType = .password
    PasswordListView(page: $page)
        .modelContainer(for: Item.self, inMemory: true)
}
