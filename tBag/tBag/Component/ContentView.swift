//
//  ContentView.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-01.
//

import SwiftUI
import SwiftData

public enum PageType {
    case password
    case sync
}

struct ContentView: View {
    @EnvironmentObject var appController: AppController
    @State private var isAccountRequired: Bool = false
    @State private var page: PageType = .password
    @State private var authViewModel = AuthViewModel()
    
    var body: some View {
        VStack {
            switch page {
            case .password:
                PasswordListView(page: $page)
            case .sync:
                SyncView(page: $page, authViewModel: authViewModel)
            }
        }
        .transition(.move(edge: .bottom))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            if appController.accountId.isEmpty {
                isAccountRequired = true
            }
        }
        .sheet(isPresented: $isAccountRequired){
            AccountView()
                .presentationDetents([.height(240)])
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppController.sampleNoAccount)
}
