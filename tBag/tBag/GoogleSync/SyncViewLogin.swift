//
//  SyncView+Upload.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-09.
//

import SwiftUI
import SwiftData
import GoogleSignInSwift

struct SyncViewLogin: View {
    @ObservedObject var authViewModel: AuthViewModel

    var body: some View {
        VStack {
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
}

#Preview {
    SyncViewLogin(authViewModel: AuthViewModel(userDisplayName: "Hoge Taro"))
        .frame(width: 500, height: 300)
}
