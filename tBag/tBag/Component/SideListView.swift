//
//  PasswordListSideView.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-07.
//

import SwiftUI
import SwiftData
import Tono

struct SideListView: View {
    @Binding var page: PageType
    @Binding var selectedItemId: String?
    @EnvironmentObject var appController: AppController
    @Environment(\.modelContext) private var modelContext
    @Environment(\.displayToast) private var toast
    @Query(filter: #Predicate<Item>{ $0.type == "pw"}) private var items: [Item]
    
    @State private var isHome = true
    @State private var isOffice = true
    @State private var isDeleted = false
    @State private var searchText: String = ""
    
    @State private var showDeleteAlert = false
    @State private var itemsPendingDeletion: Set<String> = []
    
    private let timer = Timer.publish(every: 10, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ScrollViewReader { proxy in
            List(selection: $selectedItemId) {
                ForEach(groupedItems.keys.sorted(), id: \.self) { firstLetter in
                    Section(header: Text(firstLetter)) {
                        let sectionItems = groupedItems[firstLetter]?
                            .filter(isShowItem)
                            .sorted(by: {$0.sortValue < $1.sortValue})
                        ?? []
                        ForEach(sectionItems) { item in
                            SideListRecord(item).tag(item.id)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        requestDelete(ids: [item.id])
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                        .onDelete { indexSet in
                            requestDelete(offsets: indexSet, sectionItems: sectionItems)
                        }
                    }
                }
            }
            .searchable(text: $searchText, placement: .automatic, prompt: "keyword")
            .toolbar {
                ToolbarItem(placement: .navigation) {
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
#if os(iOS)
                let placement = ToolbarItemPlacement.automatic
#else
                let placement = ToolbarItemPlacement.navigation
#endif
                ToolbarItem(placement: placement) {
                    HStack {
                        Button {
                            addItem()
                        }  label: {
                            Label("Add Item", systemImage: "plus")
                        }
                        Button {
                            page = .sync
                        } label: {
                            Label("Sync", systemImage: "arrow.trianglehead.2.clockwise.rotate.90")
                        }
#if os(macOS)
                        Button {
                            addItemFromClipboard()
                        } label: {
                            Label("Restore from Clipboard", systemImage: "document.on.clipboard")
                        }
#endif
                    }
                }
            }
            .overlay(alignment: .trailing) {
                VStack(spacing: 0) {
                    ForEach(sectionHeaders, id: \.self) { firstLetter in
                        SideListTapScrollView(firstLetter: firstLetter, proxy: proxy)
                    }
                }
#if os(macOS)
                .padding(.trailing, 8)
#endif
            }
            .alert("Delete Item?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    itemsPendingDeletion = []
                }
                Button("Delete", role: .destructive) {
                    performDelete()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
        .onReceive(timer) { _ in
            auditItems()
        }
    }
    
    private var groupedItems: [String: [Item]] {
        var grouped: [String: [Item]] = [:]
        let filteredItems = items.filter(isShowItem)
        
        for item in filteredItems {
            if let firstCharacter = item.sortValue.first {
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
    
    func isShowItem(_ item: Item) -> Bool {
        let rsa = appController.myRsaNoThrow
        let isShow = [self.isHome, self.isOffice, self.isDeleted].allSatisfy({$0})
        || [!self.isHome, !self.isOffice, !self.isDeleted, !item.isHome(rsa: rsa), !item.isOffice(rsa: rsa), !item.isDeleted(rsa: rsa)].allSatisfy({$0})
        || self.isHome && item.isHome(rsa: rsa)
        || self.isOffice && item.isOffice(rsa: rsa)
        || self.isDeleted && item.isDeleted(rsa: rsa)
        if !isShow { return false }
        
        if searchText.isEmpty { return isShow }
        
        let searchTargets = [item.caption, item.sortValue]
        let keyword = Japanese.def.getKeyJp(searchText)
        let isHit = searchTargets.map { Japanese.def.getKeyJp($0).contains(keyword) }.contains(true)
        return isHit
    }
    
    private func addItem() {
        do {
            let rsa = try appController.myRsa
            let newItem = ItemBuilder.build(ownerAccountId: appController.accountId, myRsa: rsa)
            withAnimation {
                modelContext.insert(newItem)
                selectedItemId = newItem.id
            }
        } catch {
            print("Failed to add item: \(error)")
        }
    }
    
    private func addItemFromClipboard() {
#if os(macOS)
        let clipboardString = NSPasteboard.general.string(forType: .string)
#else
        let clipboardString = UIPasteboard.general.string
#endif
        
        guard let jsonString = clipboardString, let jsonData = jsonString.data(using: .utf8) else { return }
        
        do {
            let newItem = try ItemBuilder.build(
                fromTSecretClipboardJson: jsonData,
                ownerAccountId: appController.accountId,
                myRsa: appController.myRsa
            )
            withAnimation {
                modelContext.insert(newItem)
                selectedItemId = newItem.id
            }
        } catch {
            print("Failed to restore from clipboard: \(error)")
        }
    }
    
    private func requestDelete(ids: Set<String>) {
        guard !ids.isEmpty else { return }
        itemsPendingDeletion = ids
        showDeleteAlert = true
    }
    
    private func requestDelete(offsets: IndexSet, sectionItems: [Item]) {
        var deleteItems = Set<String>()
        for index in offsets {
            let itemToDelete = sectionItems[index]
            deleteItems.insert(itemToDelete.id)
        }
        itemsPendingDeletion = deleteItems
        showDeleteAlert = true
    }
    
    private func performDelete() {
        withAnimation {
            let itemMap = Dictionary(
                groupedItems.flatMap { $0.value }.map { ($0.id, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            for itemId in itemsPendingDeletion {
                if let item = itemMap[itemId] {
                    modelContext.delete(item)
                }
            }
            selectedItemId = nil
            itemsPendingDeletion = []
        }
    }
    
    private func auditItems() {
        guard let myRsa = try? appController.myRsa else {
            return
        }
        let noTagItems = findItemsWithoutTags(using: myRsa)
        guard !noTagItems.isEmpty else {
            return
        }
        withAnimation {
            applyDeletedTag(to: noTagItems, using: myRsa)
            try? modelContext.save()
        }
    }
    
    private func findItemsWithoutTags(using myRsa: Rsa) -> [Item] {
        return items.filter { item in
            guard let sealedTagsHistory = item.attributes[Item.AttributeKeys.tags.rawValue],
                  let latestTagHistory = sealedTagsHistory.first else {
                return true
            }
            
            let sealedLatestTags = latestTagHistory.encryptedValue
            guard let plainLatestTags = try? CryptoService.shared.open(sealedString: sealedLatestTags, myRsa: myRsa) else {
                return true
            }
            
            let hasAnyTag = TagGroups.allCases.contains { plainLatestTags.contains($0.rawValue) }
            return !hasAnyTag
        }
    }
    
    private func applyDeletedTag(to targetItems: [Item], using myRsa: Rsa) {
        let salt = "\(appController.accountId)/\(Info.encryptSalt)"
        guard let sealedTag = try? CryptoService.shared.seal(plainText: TagGroups.deleted.rawValue, recipientPublicKey: myRsa.getMyPublicKey(), salt: salt) else {
            return
        }
        
        let newHistory = AttributeData(encryptedValue: sealedTag)
        
        for item in targetItems {
            var newAttributes = item.attributes
            if var tagsHistory = newAttributes[Item.AttributeKeys.tags.rawValue], !tagsHistory.isEmpty {
                tagsHistory[0] = newHistory
                newAttributes[Item.AttributeKeys.tags.rawValue] = tagsHistory
            } else {
                newAttributes[Item.AttributeKeys.tags.rawValue] = [newHistory]
            }
            
            item.attributes = newAttributes
            print("add #deleted tag to \(item.caption)")
        }
    }
}
