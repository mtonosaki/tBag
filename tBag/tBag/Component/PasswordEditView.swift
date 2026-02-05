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
    @State private var selectedPhotoPickerItem: PhotosPickerItem?
    @State private var icon: Image?
    @State private var imageForHash: Image?
    
    init(_ item: Item) {
        self.item = item
    }
    
    var body: some View {
        ScrollView(.vertical) {
            VStack {
                if let imageForHash {
                    imageForHash
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                }
                
                PhotosPicker(selection: $selectedPhotoPickerItem, matching: .images) {
                    Group {
                        if let icon {
                            icon
                                .resizable()
                        } else {
                            Image("NoImage")
                                .resizable()
                        }
                    }
                    .scaledToFit()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .padding(4)
                .onChange(of: selectedPhotoPickerItem) { _, newItem in
                    Task {
                        await saveIconToLocal(from: newItem)
                    }
                }
                .onAppear {
                    guard let imageFileName = try? item.get(key: "iconFileName", myRsa: appController.myRsa) else { return }
#if os(iOS)
                    print("--- iOS : loading : icon filename = \(imageFileName)")
#else
                    print("--- macOS: loading : icon filename = \(imageFileName)")
#endif
                    let image = ImageStore.load(fileName: imageFileName)
                    self.icon = image
                }
                
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
}

extension PasswordEditView {
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

    @MainActor
    func saveIconToLocal(from photoItem: PhotosPickerItem?) async {
        guard let photoItem else { return }
        
        do {
            guard let originalImageData = try await photoItem.loadTransferable(type: Data.self)  else { return }
            var originalImage: Image?
#if os(macOS)
            if let nsImage = NSImage(data: originalImageData) {
                originalImage = Image(nsImage: nsImage)
            }
#else
            if let uiImage = UIImage(data: originalImageData) {
                originalImage = Image(uiImage: uiImage)
            }
#endif
            guard let originalImage else { return }
            
            let image = ImageUtil.resizeImage(originalImage, maxPixel: 96)
            guard let resizedImage = image?.image else { return }
            guard let resizedImageData = image?.data else { return }
            self.icon = resizedImage
            
            let normalizedImage: Image
            if let source = CGImageSourceCreateWithData(originalImageData as CFData, nil),
               let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                normalizedImage = Image(decorative: cgImage, scale: 1.0)
            } else {
                normalizedImage = originalImage
            }
            
            let imageHash = ImageHash.computeHashCode(normalizedImage)
            let fileName = "\(imageHash).png"
            
#if os(iOS)
            print("--- iOS 　: saving : icon filename = \(fileName)")
#else
            print("--- macOS: saving : icon filename = \(fileName)")
#endif
            
            ImageStore.save(data: resizedImageData, fileName: fileName)
            try item.set(key: "iconFileName", planeText: fileName, recipientPublicKey: appController.myPublicKey, owner: appController.accountId)
        } catch {
            toast?("Failed to set image: \(error.localizedDescription)")
        }
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
