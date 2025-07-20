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
        ZStack {
            Hoge()
        }
        .onAppear {
            if appController.accountId.isEmpty {
                isAccountRequired = true
            }
        }
        .sheet(isPresented: $isAccountRequired){
            AccountView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppController.sample)
}
