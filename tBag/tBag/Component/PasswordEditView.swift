//
//  PasswordEditorView.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/21.
//

import SwiftUI
import PhotosUI
import Tono
import ImageIO

struct PasswordEditView: View {
    @EnvironmentObject var appController: AppController
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
                IconEditView(item)
                    .padding(4)

                FormCard("Rubi", systemImage: "character.textbox.ja") {
                    TextField("あいうえお", text: $item.sortValue)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
#endif
                        .disableAutocorrection(true)
                        .textContentType(.name)
                }
                FormCard("Caption", systemImage: "character.bubble") {
                    TextField("item title", text: $item.caption)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
#endif
                        .textContentType(.name)
                        .disableAutocorrection(true)
                }
                FormCard("AccountID", systemImage: "person.circle") {
                    TextField("hoge123", text: stringBinding(Item.PasswordAttributeKeys.accountId.rawValue))
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
                        .textContentType(.username)
#endif
                        .disableAutocorrection(true)
                } copyText: {
                    item.get(key: "accountId", myRsa: try? appController.myRsa, defaultString: "" )
                }
                FormCard("Password", systemImage: "lock.circle") {
                    HStack {
                        if isOpenPassword {
                            TextField("password", text: stringBinding(Item.PasswordAttributeKeys.password.rawValue))
#if os(iOS)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.default)
#endif
                                .textContentType(.password)
                                .disableAutocorrection(true)
                                .font(.custom("Courier New", size: 23))
                                .bold()
                        } else {
                            SecureField("password", text: stringBinding(Item.PasswordAttributeKeys.password.rawValue))
#if os(iOS)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.default)
#endif
                                .font(.custom("Courier New", size: 23))
                                .textContentType(.password)
                                .disableAutocorrection(true)
                        }
                        Button {
                            isOpenPassword = !isOpenPassword
                        } label: {
                            Label("", systemImage: "eyes")
                                .foregroundColor(.secondary)
                        }
#if os(macOS)
                        .buttonStyle(.plain)
#endif
                    }
                } copyText: {
                    item.get(key: "password", myRsa: try? appController.myRsa, defaultString: "" )
                }
                FormCard("email", systemImage: "mail") {
                    TextField("hoge @ example.com", text: stringBinding(Item.PasswordAttributeKeys.email.rawValue))
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
#endif
                        .textContentType(.emailAddress)
                        .disableAutocorrection(true)
                } copyText: {
                    item.get(key: "email", myRsa: try? appController.myRsa, defaultString: "" )
                }
                FormCard("Tags", systemImage: "tag") {
                    FlowLayout(spacing: 24) {
                        Toggle(isOn: tagBinding(Item.PasswordFilter.home.rawValue)) {
                            Image(systemName: "house")
                        }
                        Toggle(isOn: tagBinding(Item.PasswordFilter.office.rawValue)) {
                            Image(systemName: "network")
                        }
                        Toggle(isOn: tagBinding(Item.PasswordFilter.deleted.rawValue)) {
                            Image(systemName: "trash")
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                FormCard("Remarks", systemImage: "doc.plaintext") {
                    TextEditor(text: stringBinding("remarks"))
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
#endif
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
            
            Button(item.id) {
#if os(iOS)
                UIPasteboard.general.string = item.id
#elseif os(macOS)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(item.id, forType: .string)
#endif
                toast?("Copy item ID")
            }
#if os(macOS)
            .buttonStyle(.plain)
#endif
            .font(.footnote)
            .foregroundColor(.secondary)
            .padding(.bottom)
        }
        .navigationTitle(item.isEmpty() ? "New Item" : item.caption)
        .background(Color.bgColorPassword)
    }

    func stringBinding(_ key: String) -> Binding<String> {
        return Binding(
            get: {
                let value = item.get(key: key, myRsa: try? appController.myRsa, defaultString: "")
                return value
            },
            set: {
                try? item
                    .set(key: key, planeText: $0, recipientPublicKey: try appController.myPublicKey, owner: appController.accountId)
            }
        )
    }
    
    func tagBinding(_ key: String) -> Binding<Bool> {
        return Binding(
            get: {
                guard let myRsa = try? appController.myRsa else {
                    return false
                }
                return item.containsTag(key, myRsa: myRsa)
            },
            set: {
                do {
                    let myRsa = try appController.myRsa
                    if $0 {
                        item.addTag(key, myRsa: myRsa, owner: appController.accountId)
                    } else {
                        item.removeTag(key, myRsa: myRsa, owner: appController.accountId)
                    }
                } catch {
                    toast?("Cannot access the tag \(key)")
                }
            }
        )
    }
}

#Preview {
    PasswordEditView(Item(
        ownerId: UUID().uuidString,
        type: .password,
        timestamp: Date(),
        sortValue: "ほげたろう",
        caption: "ホゲ太郎",
        attrubutes: [:]
    ))
}
