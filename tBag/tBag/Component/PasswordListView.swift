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
            PasswordListSideView(page: $page, selectedItemId: $selectedItemId, groupedItems: groupedItems, sectionHeaders: sectionHeaders)
            
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
