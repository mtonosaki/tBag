//
//  ContentView.swift
//  MsalSample
//
//  Created by Kazunori Kimura on 2024/01/30.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appController: AppController
    @State private var isAccountRequired: Bool = false
    
    var body: some View {
        VStack {
            PasswordListView()
        }
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
