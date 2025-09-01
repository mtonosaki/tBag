//
//  6751812175.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-02.
//

import Foundation
import GoogleSignIn
import GoogleSignInSwift

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userDisplayName: String?
    @Published var errorMessage: String?

    func signIn() async {
#if os(iOS)
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            errorMessage = "Fatal error: Could not find rootViewController."
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            handleSignInResult(result)
        } catch {
            handleSignInError(error)
        }

#else
        guard let presentingWindow = NSApplication.shared.keyWindow else {
            errorMessage = "Fatal error: Could not find keyWindow."
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow)
            handleSignInResult(result)
        } catch {
            handleSignInError(error)
        }
#endif
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        self.userDisplayName = nil
        self.errorMessage = nil
    }

    private func handleSignInResult(_ result: GIDSignInResult) {
        let user = result.user
        self.userDisplayName = user.profile?.name
        self.errorMessage = nil
        print("Signed in as \(user.profile?.name ?? "Unknown")")
    }
    
    private func handleSignInError(_ error: Error) {
        self.errorMessage = "Error: Sign-in failed: \(error.localizedDescription)"
        print(self.errorMessage ?? "Unknown error")
    }
}
