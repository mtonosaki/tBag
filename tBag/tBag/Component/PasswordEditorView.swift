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
    
    @State private var rubi: String
    @State private var caption: String
    @State private var accountId: String
    @State private var password: String
    @State private var isOpenPassword: Bool = false
    @State private var email: String
    @State private var filterHome: Bool
    @State private var filterOffice: Bool
    @State private var filterDeleted: Bool
    @State private var remarks: String
    
    init(_ item: Item) {
        self.item = item
        self.rubi  = item.sortKey
        self.caption = item.caption
        self.accountId = item.attributes["accountId"] ?? ""
        self.password = item.attributes["password"] ?? ""
        self.email = item.attributes["email"] ?? ""
        
        let tags = item.attributes["tags"] ?? ""
        self.filterHome = tags.contains("#home")
        self.filterOffice = tags.contains("#office")
        self.filterDeleted = tags.contains("#deleted")
        
        self.remarks = "\(item.attributes["remarks"] ?? "")."
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
                FormCard("AccountID", systemImage: "person.circle", copyText: { accountId }){
                    TextField("hoge123", text: $accountId)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .textContentType(.username)
                        .onChange(of: accountId, updateItem("accountId"))
                }
                FormCard("Password", systemImage: "lock.circle", copyText: { password }){
                    HStack {
                        if isOpenPassword {
                            TextField("password", text: $password)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.default)
                                .disableAutocorrection(true)
                                .textContentType(.password)
                                .font(.custom("Courier New", size: 23))
                                .bold()
                                .onChange(of: password, updateItem("password"))
                        } else {
                            SecureField("password", text: $password)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.default)
                                .disableAutocorrection(true)
                                .textContentType(.password)
                                .onChange(of: password, updateItem("password"))
                        }
                        Button{
                            isOpenPassword = !isOpenPassword
                        } label: {
                            Label("", systemImage: "eyes")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                FormCard("email", systemImage: "mail", copyText: { email }){
                    TextField("hoge @ example.com", text: $email)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .textContentType(.emailAddress)
                        .onChange(of: email, updateItem("email"))
                }
                FormCard("Tags", systemImage: "tag"){
                    FlowLayout(spacing: 24) {
                        Toggle(isOn: $filterHome){
                            Image(systemName: "house")
                        }
                        .onChange(of: filterHome, updateItemTags("#home"))
                        
                        Toggle(isOn: $filterOffice){
                            Image(systemName: "building.2")
                        }
                        .onChange(of: filterOffice, updateItemTags("#office"))
                        
                        Toggle(isOn: $filterDeleted){
                            Image(systemName: "trash")
                        }
                        .onChange(of: filterDeleted, updateItemTags("#deleted"))
                        
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                FormCard("Remarks", systemImage: "doc.plaintext"){
                    TextEditor(text: $remarks)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
                        .disableAutocorrection(true)
                        .frame(minHeight: 48)
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                        .onChange(of: remarks, updateItem("remarks"))
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.remarks = String(self.remarks.dropLast()) // auto rerender TextEditor to set proper height
            }
        }
    }
    
    func updateItem(_ key: String) -> (_ oldValue: String, _ newValue: String) -> Void {
        return { oldValue, newValue in
            self.item.attributes[key] = newValue
        }
    }
    
    func updateItemTags(_ key: String) -> (_ oldValue: Bool, _ newValue: Bool) -> Void {
        return { oldValue, newValue in
            let tagsString = self.item.attributes["tags"] ?? ""
            let tags = tagsString.split(separator: ",").map{ $0.trimmingCharacters(in: .whitespaces)}.filter{ $0 != key }
            let newTags = newValue ? tags + [key] : tags
            let newTagsString = newTags.joined(separator: ",")
            self.item.attributes["tags"] = newTagsString
        }
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
