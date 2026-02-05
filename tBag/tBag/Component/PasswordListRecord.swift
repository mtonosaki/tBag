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
    @State private var icon: Image = Image(.no)
    
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
                icon
                    .resizable()
                    .scaledToFit()
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
            .onAppear {
                guard let imageFileName = try? item.get(key: "iconFileName", myRsa: appController.myRsa) else { return }
                let image = ImageStore.load(fileName: imageFileName)
                if let image = image {
                    self.icon = image
                }
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
    
    List {
        ForEach(items) { item in
            NavigationLink {
                PasswordEditView(item)
            } label: {
                PasswordListRecord(item)
            }
        }
    }
}
