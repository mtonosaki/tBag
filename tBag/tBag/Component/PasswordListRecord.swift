//
//  PasswordListRecord.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/27.
//

import SwiftUI

struct PasswordListRecord: View {
    let item: Item
    
    init(_ item: Item) {
        self.item = item
    }
    
    var body: some View {
        if item.caption.isEmpty {
            HStack {
                Image(systemName: "pencil.and.list.clipboard")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.blue)
                    .opacity(0.3)
                Text("New")
                    .foregroundColor(.blue)
                    .opacity(0.3)
                    .padding(.trailing)
                Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
            }
        } else {
            HStack {
                Image("NoImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading) {
                    Text(item.caption)
                        .font(.headline)
                    HStack {
                        Text(item.attributes["accountId"] ?? "")
                            .opacity(0.5)
                            .font(.subheadline)
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview {
    let ownerId = UUID().uuidString
    let items: [Item] = [
        Item(ownerId: ownerId, type: .Password, timestamp: Date(), sortKey: "", caption: "", attrubutes: [:]),
        Item(ownerId: ownerId, type: .Password, timestamp: Date(), sortKey: "hoge", caption: "HOGE", attrubutes: [
            "accountId": "hoge@example.com"
        ])
    ]
    
    List {
        ForEach(items) { item in
            NavigationLink {
                PasswordEditorView(item)
            } label: {
                PasswordListRecord(item)
            }
        }
    }
}
