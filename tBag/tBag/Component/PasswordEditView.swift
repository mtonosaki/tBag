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
    @Environment(\.cryptoService) var cryptoService
    
    @State private var viewModel: PasswordEditViewModel?
    @State private var isOpenPassword: Bool = false
    
    var item: Item
    
    init(_ item: Item) {
        self.item = item
    }
    
    var body: some View {
        if let viewModel = viewModel {
            renderContent(viewModel: viewModel)
        } else {
            ProgressView()
                .onAppear {
                    viewModel = PasswordEditViewModel(item: item, appController: appController, cryptoService: cryptoService)
                }
        }
    }
    
    @ViewBuilder
    func renderContent(viewModel: PasswordEditViewModel) -> some View {
        ScrollView(.vertical) {
            VStack {
                IconEditView(viewModel.item)
                    .padding(4)

                rubiSection(viewModel: viewModel)
                captionSection(viewModel: viewModel)
                accountIdSection(viewModel: viewModel)
                passwordSection(viewModel: viewModel)
                emailSection(viewModel: viewModel)
                tagsSection(viewModel: viewModel)
                remarksSection(viewModel: viewModel)
            }
            .padding(.leading)
            .padding(.trailing)
            
            itemIdButton(viewModel: viewModel)
        }
        .navigationTitle(viewModel.item.isEmpty() ? "New Item" : viewModel.item.caption)
        .background(BackgroundRasterLines())
    }

    @ViewBuilder
    private func rubiSection(viewModel: PasswordEditViewModel) -> some View {
        FormCard("Rubi", systemImage: "character.textbox.ja") {
            TextField("あいうえお", text: Bindable(viewModel.item).sortValue)
#if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.default)
#endif
                .disableAutocorrection(true)
                .textContentType(.name)
        }
    }

    @ViewBuilder
    private func captionSection(viewModel: PasswordEditViewModel) -> some View {
        FormCard("Caption", systemImage: "character.bubble") {
            TextField("item title", text: Bindable(viewModel.item).caption)
#if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.default)
#endif
                .textContentType(.name)
                .disableAutocorrection(true)
        }
    }

    @ViewBuilder
    private func accountIdSection(viewModel: PasswordEditViewModel) -> some View {
        @Bindable var item = viewModel.item
        let key = Item.AttributeKeys.accountId.rawValue
        FormCard("AccountID", systemImage: "person.circle", history: $item.attributes[key]) {
            TextField("hoge123", text: stringBinding(viewModel: viewModel, key: key))
#if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.default)
                .textContentType(.username)
#endif
                .disableAutocorrection(true)
        } copyText: {
            viewModel.getPlainValue(key: key)
        } decodeHistory: { sealedString in
            viewModel.getPlainValue(sealedString)
        }
    }

    @ViewBuilder
    private func passwordSection(viewModel: PasswordEditViewModel) -> some View {
        FormCard("Password", systemImage: "lock.circle") {
            HStack {
                if isOpenPassword {
                    TextField("password", text: stringBinding(viewModel: viewModel, key: Item.AttributeKeys.password.rawValue))
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.default)
#endif
                        .textContentType(.password)
                        .disableAutocorrection(true)
                        .font(.custom("Courier New", size: 23))
                        .bold()
                } else {
                    SecureField("password", text: stringBinding(viewModel: viewModel, key: Item.AttributeKeys.password.rawValue))
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
            viewModel.getPlainValue(key: Item.AttributeKeys.password.rawValue)
        }
    }

    @ViewBuilder
    private func emailSection(viewModel: PasswordEditViewModel) -> some View {
        FormCard("email", systemImage: "mail") {
            TextField("hoge @ example.com", text: stringBinding(viewModel: viewModel, key: Item.AttributeKeys.email.rawValue))
#if os(iOS)
                .textInputAutocapitalization(.never)
                .keyboardType(.default)
#endif
                .textContentType(.emailAddress)
                .disableAutocorrection(true)
        } copyText: {
            viewModel.getPlainValue(key: Item.AttributeKeys.email.rawValue)
        }
    }

    @ViewBuilder
    private func tagsSection(viewModel: PasswordEditViewModel) -> some View {
        FormCard("Tags", systemImage: "tag") {
            FlowLayout(spacing: 24) {
                Toggle(isOn: tagBinding(viewModel: viewModel, key: TagGroups.home.rawValue)) {
                    Image(systemName: "house")
                }
                Toggle(isOn: tagBinding(viewModel: viewModel, key: TagGroups.office.rawValue)) {
                    Image(systemName: "network")
                }
                Toggle(isOn: tagBinding(viewModel: viewModel, key: TagGroups.deleted.rawValue)) {
                    Image(systemName: "trash")
                }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func remarksSection(viewModel: PasswordEditViewModel) -> some View {
        FormCard("Remarks", systemImage: "doc.plaintext") {
            ZStack(alignment: .topLeading) {
                let textContent = viewModel.getPlainValue(key: Item.AttributeKeys.remarks.rawValue)
                Text(textContent.isEmpty ? " " : textContent)
                    .foregroundColor(.clear)
                    .padding(8)
                    .frame(maxWidth: .infinity, minHeight: 48, alignment: .topLeading)
                
                TextEditor(text: stringBinding(viewModel: viewModel, key: Item.AttributeKeys.remarks.rawValue))
#if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.default)
#endif
                    .disableAutocorrection(true)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(4)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.gray, lineWidth: 0.5)
            )
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    private func itemIdButton(viewModel: PasswordEditViewModel) -> some View {
        Button(viewModel.item.id) {
#if os(iOS)
            UIPasteboard.general.string = viewModel.item.id
#elseif os(macOS)
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(viewModel.item.id, forType: .string)
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

    func stringBinding(viewModel: PasswordEditViewModel, key: String) -> Binding<String> {
        return Binding(
            get: { viewModel.getPlainValue(key: key) },
            set: { viewModel.setPlainValue(key: key, value: $0) }
        )
    }
    
    func tagBinding(viewModel: PasswordEditViewModel, key: String) -> Binding<Bool> {
        return Binding(
            get: { viewModel.containsTag(key) },
            set: { _ in viewModel.toggleTag(key) }
        )
    }
}

#Preview {
    let sampleItem = Item(
        ownerId: UUID().uuidString,
        type: .password,
        createdAt: Date(),
        sortValue: "ほげたろう",
        caption: "ホゲ太郎",
        attributes: [:]
    )
    let fakeAppController = AppController()
    let fakeConfig = ViewConfig()
    PasswordEditView(sampleItem)
        .environmentObject(fakeAppController)
        .environmentObject(fakeConfig)
}
