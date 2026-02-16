//
//  PasswordListRecord.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/27.
//

import SwiftUI
import Tono

struct PasswordListRecord: View {
    @EnvironmentObject var appController: AppController
    
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
                IconView(item)
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading) {
                    Text(item.caption)
                        .font(.headline)
                    HStack {
                        Text(item.get(key: "accountId", myRsa: try? appController.myRsa, defaultString: ""))
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
        Item(ownerId: ownerId, type: .password, timestamp: Date(), sortValue: "", caption: "", attrubutes: [:]),
        Item(ownerId: ownerId, type: .password, timestamp: Date(), sortValue: "hoge", caption: "HOGE", attrubutes: [
            "accountId": "hoge@example.com"
        ])
    ]
    let fakeAppController = AppController()
    let fakeConfig = ViewConfig()

    List {

        ForEach(items) { item in
            NavigationLink {
                PasswordEditView(item)
                    .environmentObject(fakeAppController)
                    .environmentObject(fakeConfig)
            } label: {
                PasswordListRecord(item)
                    .environmentObject(fakeAppController)
                    .environmentObject(fakeConfig)
            }
        }
    }
}
