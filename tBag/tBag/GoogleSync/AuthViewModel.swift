//
//  6751812175.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-02.
//

import Foundation
import GoogleSignIn
import GoogleSignInSwift
import GoogleAPIClientForREST_Drive

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userDisplayName: String?
    @Published var errorMessage: String?
    @Published var user: GIDGoogleUser?

    init() { }
    
    convenience init(userDisplayName: String?, errorMessage: String? = nil, user: GIDGoogleUser? = nil) {
        self.init()
        self.userDisplayName = userDisplayName
        self.errorMessage = errorMessage
        self.user = user
    }

    func signIn() async {
        configureSignIn()
        
#if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let presentingWindow = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            errorMessage = "Fatal error (13821)"
            return
        }
#elseif os(macOS)
        guard let presentingWindow = NSApplication.shared.keyWindow else {
            errorMessage = "Fatal error (23821)"
            return
        }
#endif
        do {
            let additionalScopes = [kGTLRAuthScopeDriveFile]
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingWindow, hint: nil, additionalScopes: additionalScopes )
            self.user = result.user
            self.userDisplayName = self.user?.profile?.name
            self.errorMessage = nil
            print("Signed in as \(userDisplayName ?? "Unknown")")
        } catch {
            self.errorMessage = "Sign-in error: \(error.localizedDescription)"
            print(self.errorMessage!)
        }
    }
    
    private func configureSignIn() {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String, !clientID.isEmpty else {
            self.errorMessage = "Fatal Error: GIDClientID not found in Info.plist"
            return
        }
        guard let hostedDomain = Bundle.main.object(forInfoDictionaryKey: "AuthenticationDomain") as? String, !clientID.isEmpty else {
            self.errorMessage = "Fatal Error: AuthenticationDomain not found in Info.plist"
            return
        }
                
        let config = GIDConfiguration(
            clientID: clientID,
            serverClientID: nil,
            hostedDomain: hostedDomain,
            openIDRealm: nil
        )
        GIDSignIn.sharedInstance.configuration = config
    }
    
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
        self.userDisplayName = nil
        self.errorMessage = nil
    }
}

