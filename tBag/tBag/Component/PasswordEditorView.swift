//
//  PasswordEditorView.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/21.
//

import SwiftUI
import Tono

struct PasswordEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.displayToast) var toast
    
    @Bindable var item: Item
    
    @State private var isOpenPassword: Bool = false
        
    init(_ item: Item) {
        self.item = item
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                Button {
                } label: {
                    Image("NoImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                }
                FormCard("Rubi", systemImage: "character.textbox.ja"){
                    TextField("あいうえお", text: $item.sortKey)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .textContentType(.name)
                }
                FormCard("Caption", systemImage: "character.bubble") {
                    TextField("item title", text: $item.caption)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .textContentType(.name)
                }
                FormCard("AccountID", systemImage: "person.circle", copyText: { item.attributes["accountId"] }){
                    TextField("hoge123", text: Binding(
                        get: { item.attributes["accountId"] ?? "" },
                        set: { item.attributes["accountId"] = $0 }
                    ))
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .textContentType(.username)
                }
                FormCard("Password", systemImage: "lock.circle", copyText: { item.attributes["password"] }){
                    HStack {
                        if isOpenPassword {
                            TextField("password", text: Binding(
                                get: { item.attributes["password"] ?? "" },
                                set: { item.attributes["password"] = $0 }
                            ))
                                .textInputAutocapitalization(.never)
                                .keyboardType(.default)
                                .disableAutocorrection(true)
                                .textContentType(.password)
                                .font(.custom("Courier New", size: 23))
                                .bold()
                        } else {
                            SecureField("password", text: Binding(
                                get: { item.attributes["password"] ?? "" },
                                set: { item.attributes["password"] = $0 }
                            ))
                                .textInputAutocapitalization(.never)
                                .keyboardType(.default)
                                .disableAutocorrection(true)
                                .textContentType(.password)
                        }
                        Button{
                            isOpenPassword = !isOpenPassword
                        } label: {
                            Label("", systemImage: "eyes")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                FormCard("email", systemImage: "mail", copyText: { item.attributes["email"] }){
                    TextField("hoge @ example.com", text: Binding(
                        get: { item.attributes["email"] ?? ""},
                        set: { item.attributes["email"] = $0 }
                    ))
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .textContentType(.emailAddress)
                }
                FormCard("Tags", systemImage: "tag"){
                    FlowLayout(spacing: 24) {
                        Toggle(isOn: Binding(
                            get: { item.containsTag("#home")},
                            set: { $0 ? item.addTag("#home") : item.removeTag("#home") }
                        )){
                            Image(systemName: "house")
                        }
                        Toggle(isOn: Binding(
                            get: { item.containsTag("#office") },
                            set: { $0 ? item.addTag("#office") : item.removeTag("#office") }
                        )){
                            Image(systemName: "building.2")
                        }
                        Toggle(isOn: Binding(
                            get: { item.containsTag("#deleted") },
                            set: { $0 ? item.addTag("#deleted") : item.removeTag("#deleted") }
                        )){
                            Image(systemName: "trash")
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                FormCard("Remarks", systemImage: "doc.plaintext"){
                    TextEditor(text: Binding(
                        get: { item.attributes["remarks"] ?? "" },
                        set: { item.attributes["remarks"] = $0 },
                    ))
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .frame(minHeight: 48)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                }
                .padding(.bottom, 12)
            }
            .padding(.leading)
            .padding(.trailing)
            
            Button(item.accountId){
                UIPasteboard.general.string = item.accountId
                toast?("Copy item ID")
            }
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(.bottom)
        }
        .navigationTitle(item.isEmpty() ? "New Item" : item.caption)
        .background(Color.bgColorPassword)
    }
}




#Preview {
    PasswordEditorView(Item(
        accountId: UUID().uuidString,
        type: .Password,
        timestamp: Date(),
        sortKey: "ほげたろう",
        caption: "ホゲ太郎",
        attrubutes: [:]
    ))
}
