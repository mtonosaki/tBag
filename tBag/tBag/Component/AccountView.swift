//
//  AccountView.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/20.
//

import SwiftUI
import Tono

struct AccountView: View {
    @EnvironmentObject var appController: AppController
    @Environment(\.dismiss) var dismiss
    @State private var accountIdEdit: String = ""
    @State private var isGenerated: Bool = false
    
    var body: some View {
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
                        appController.accountId = accountIdEdit
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
            
        }
        .background(Color(.systemGray6))
        .navigationTitle("Account")
    }
}

func isUserId(id: String) -> Bool {
    return StrUtil.isUuid(id)
}

#Preview {
    AccountView()
}
