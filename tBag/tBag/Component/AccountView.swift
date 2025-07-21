//
//  AccountView.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/20.
//

import SwiftUI
import Tono

struct AccountView: View {
    @AppStorage("isResetLocalDataAtNextLaunch") private var isResetLocalDataAtNextLaunch = false
    @AppStorage("latestAccountId") private var latestAccountId = ""
    
    @EnvironmentObject var appController: AppController
    @Environment(\.dismiss) var dismiss
    @Environment(\.displayToast) var toast
    @Environment(\.modelContext) private var context
        
    @State private var accountIdEdit: String = ""
    @State private var isGenerated: Bool = false
    @State private var isAutoRestoring = true
    
    var body: some View {
        ZStack{
            VStack{
                Form {
                    Section(header: Text("Account ID")) {
                        TextField("Account ID", text: $accountIdEdit, prompt: Text("uuid"), axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .padding(.trailing)
                            .disabled(isGenerated)
                    }
                    .padding(.leading)
                    .padding(.top)

                    HStack {
                        Button {
                            guard KeychainStore.shared.set("accountId", accountIdEdit) else {
                                toast?("Keychain access error")
                                return
                            }
                            appController.accountId = accountIdEdit
                            latestAccountId = accountIdEdit
                            dismiss()
                        } label: {
                            if isGenerated {
                                Label("Save", systemImage: "square.and.arrow.up")

                            } else {
                                Label("Restore", systemImage: "square.and.arrow.down")
                            }
                        }
                            .buttonStyle(.borderedProminent)
                            .disabled(!isUserId(id: accountIdEdit))
                        
                        Spacer()
                        
                        ZStack {
                            Button {
                                accountIdEdit = UUID().uuidString.lowercased()
                                isGenerated = true
                            } label: {
                                Label("Generate", systemImage: "person.crop.circle.badge.plus")
                            }
                                .opacity(isGenerated ? 0 : 1)
                            
                            Button {
                                isGenerated = false
                                accountIdEdit = ""
                            } label: {
                                Label("Reset", systemImage: "arrow.counterclockwise")
                            }
                                .opacity(isGenerated ? 1 : 0)
                        }
                    }
                    .padding()
                }
                .formStyle(.columns)
                .background(Color(.systemBackground))
                .padding()

                Spacer()
            }.opacity(isAutoRestoring ? 0 : 1)
            
            ProgressView("Loading...")
                .progressViewStyle(CircularProgressViewStyle())
                .opacity(isAutoRestoring ? 1 : 0)

        }
        .background(Color(.systemGray6))
        .onAppear {
            
            if isResetLocalDataAtNextLaunch {
                _ = KeychainStore.shared.delete(key: "accountId")
                try? context.delete(model: Item.self)
                isResetLocalDataAtNextLaunch = false
            }
            guard let savedId = KeychainStore.shared.get("accountId") else {
                isAutoRestoring = false
                return
            }
            appController.accountId = savedId
            latestAccountId = savedId
            dismiss()
        }
    }
}

func isUserId(id: String) -> Bool {
    return StrUtil.isUuid(id)
}

#Preview {
    AccountView()
}
