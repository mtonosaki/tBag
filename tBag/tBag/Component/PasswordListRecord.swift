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
                VStack(alignment: .leading) {
                    
                }
            }
            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
        } else {
            HStack {
                Image("NoImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading) {
                    Text(item.caption)
                    HStack {
                        Text(item.attributes["accountId"] ?? "")
                            .foregroundColor(.passwordListSubCaption)
                            .font(.subheadline)
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview {
    let accountId = UUID().uuidString
    let items: [Item] = [
        Item(accountId: accountId, type: .Password, timestamp: Date(), sortKey: "", caption: "", attrubutes: [:]),
        Item(accountId: accountId, type: .Password, timestamp: Date(), sortKey: "hoge", caption: "HOGE", attrubutes: [
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
