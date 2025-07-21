//
//  PasswordEditorView.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/21.
//

import SwiftUI

struct PasswordEditorView: View {
    @Environment(\.displayToast) var toast
    
    private let initialItem: Item
    @State var item: Item
    @State var accountId: String = ""
    @State var password: String = ""
    @State var isOpenPassword: Bool = false
    @State var email: String = ""
    @State var filterHome = true
    @State var filterOffice = true
    @State var filterDelete = false
    @State var remarks: String = ""
    
    init(_ item: Item) {
        self.initialItem = item
        self.item = Item(cloneFrom: item)
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                Button {} label: {
                    Image("NoImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                }
                FormCard("Rubi", systemImage: "character.textbox.ja"){
                    TextField("あいうえお", text: $item.sortKey)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                HStack {
                    FormCard("Caption", systemImage: "character.bubble") {
                        TextField("item title", text: $item.caption)
                    }
                }
                FormCard("Account ID", systemImage: "person.circle", copyText: { return "HOGE" }){
                    TextField("your account", text: $accountId)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: accountId, updateAndSave("accountId"))
                }
                FormCard("Password", systemImage: "lock.circle"){
                    HStack {
                        if isOpenPassword {
                            TextField("password", text: $password)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .font(.custom("Courier New", size: 23))
                                .bold()
                                .onChange(of: password, updateAndSave("password"))
                        } else {
                            SecureField("password", text: $password)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: password, updateAndSave("password"))
                        }
                        Button{
                            isOpenPassword = !isOpenPassword
                        } label: {
                            Label("", systemImage: "eyes")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                FormCard("email", systemImage: "mail"){
                    TextField("hoge @ example.com", text: $email)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .onChange(of: email, updateAndSave("email"))
                }
                FormCard("Tags", systemImage: "tag"){
                    HStack {
                        Toggle(isOn: $filterHome){
                            Image(systemName: "house")
                        }
                        .padding(.trailing)
                        Toggle(isOn: $filterOffice){
                            Image(systemName: "building.2")
                        }
                        .padding(.trailing)
                        Toggle(isOn: $filterDelete){
                            Image(systemName: "trash")
                        }
                        .padding(.trailing)
                    }
                }
                FormCard("Remarks", systemImage: "doc.plaintext"){
                    TextEditor(text: $remarks)
                        .autocapitalization(.none)
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
    
    func updateAndSave(_ key: String) -> (_ oldValue: String, _ newValue: String) -> Void {
        return { oldValue, newValue in
            self.item.attributes[key] = newValue
        }
    }
}




#Preview {
    PasswordEditorView(Item(
        accountId: "de305d54-75b4-431b-adb2-eb6b9e546013",
        type: .Password,
        timestamp: Date(),
        sortKey: "ほげたろう",
        caption: "ホゲ太郎",
        attrubutes: [:]
    ))
}
