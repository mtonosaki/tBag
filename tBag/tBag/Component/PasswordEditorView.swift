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
                    TextField("hoge123", text: StringBinding("accountId"))
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .textContentType(.username)
                }
                FormCard("Password", systemImage: "lock.circle", copyText: { item.attributes["password"] }){
                    HStack {
                        if isOpenPassword {
                            TextField("password", text: StringBinding("password"))
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
                    TextField("hoge @ example.com", text: StringBinding("email"))
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .textContentType(.emailAddress)
                }
                FormCard("Tags", systemImage: "tag"){
                    FlowLayout(spacing: 24) {
                        Toggle(isOn: TagBinding("#home")){
                            Image(systemName: "house")
                        }
                        Toggle(isOn: TagBinding("#office")){
                            Image(systemName: "building.2")
                        }
                        Toggle(isOn: TagBinding("#deleted")){
                            Image(systemName: "trash")
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                FormCard("Remarks", systemImage: "doc.plaintext"){
                    TextEditor(text: StringBinding("remarks"))
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
    
    func StringBinding(_ key: String) -> Binding<String> {
        return Binding(
            get: { item.attributes[key] ?? "" },
            set: { item.attributes[key] = $0 }
        )
    }

    func TagBinding(_ key: String) -> Binding<Bool> {
        return Binding(
            get: { item.containsTag(key) },
            set: { $0 ? item.addTag(key) : item.removeTag(key) }
        )
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
