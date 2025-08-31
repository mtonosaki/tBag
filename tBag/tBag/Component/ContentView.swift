//
//  ContentView.swift
//  MsalSample
//
//  Created by Kazunori Kimura on 2024/01/30.
//

import SwiftUI

public enum PageType {
    case password
    case sync
}

struct ContentView: View {
    @EnvironmentObject var appController: AppController
    @State private var isAccountRequired: Bool = false
    @State private var page: PageType = .password
    
    var body: some View {
        VStack {
            switch page {
            case .password:
                PasswordListView(page: $page)
            case .sync:
                Sync(page: $page)
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
