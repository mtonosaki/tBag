//
//  Sync.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-08-24.
//

import SwiftUI
import SwiftData

struct Sync: View {
    @Binding var page: PageType
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appController: AppController
    @Query(filter: #Predicate<Item>{ $0.type == "pw"}) private var items: [Item]

    var body: some View {
        NavigationStack {
            VStack {
                Text("HOGE")
                Text("HOGE")
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back"){
                        page = .password
                    }
                }
            }
         }
    }
}

#Preview {
    Sync(page: .constant(.password))
}
