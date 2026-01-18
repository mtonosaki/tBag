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
    @ObservedObject var authViewModel: AuthViewModel
    @EnvironmentObject var appController: AppController
    @StateObject private var viewConfig = ViewConfig()
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationStack {
            ZStack {
                if let displayName = authViewModel.userDisplayName {
                    SyncViewAuthed(authViewModel: authViewModel, displayName: displayName)
                    
                } else {
                    SyncViewLogin(authViewModel: authViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        authViewModel.signOut()
                        page = .password
                    } label: {
                        Text(viewConfig.cancelButtonTitle)
                    }
                    .padding(.horizontal, 6)
                }
            }
        }.environmentObject(viewConfig)
    }
}

class ViewConfig: ObservableObject {
    @Published var cancelButtonTitle: String = "← Cancel"
}

#Preview {
    SyncView(
        page: .constant(.password),
        authViewModel: AuthViewModel(userDisplayName: "Hoge Taro")
    )
    .frame(width: 500, height: 300)
    .modelContainer(makeSampleModelContainer()!)
    .environmentObject(makeSampleAppController())
}
