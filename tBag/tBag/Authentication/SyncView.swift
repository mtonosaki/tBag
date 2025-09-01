//
//  Sync.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-08-24.
//

import SwiftUI
import SwiftData
import GoogleSignInSwift

struct SyncView: View {
    @Binding var page: PageType
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appController: AppController
    @Query(filter: #Predicate<Item>{ $0.type == "pw"}) private var items: [Item]
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        NavigationStack {
            VStack {
                if let displayName = authViewModel.userDisplayName {
                    Text("Hi, \(displayName) !")
                    .font(.largeTitle)

                    Button("Sign-out") {
                        authViewModel.signOut()
                    }
                } else {
                    Text("To sign in, tap the button below.")
                        .font(.headline)

                    GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                        Task {
                            await authViewModel.signIn()
                        }
                    }
                    .frame(width: 250, height: 50)

                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        page = .password
                    } label: {
                        Text("← Cancel")
                            
                    }
                    .buttonStyle(.borderless)
                }
            }
         }
    }
}

#Preview {
    SyncView(page: .constant(.password))
        .frame(width: 500, height: 500)
}
