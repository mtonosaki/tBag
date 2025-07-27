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
                            .foregroundColor(Color.accentColor)
                            .font(.subheadline)
                    }
                }
                Spacer()
            }
        }
    }
}

#Preview {
    PasswordListRecord(Item(accountId: UUID().uuidString, type: .Password, timestamp: Date(), sortKey: "hoge", caption: "HOGE", attrubutes: [:]))
}
