//
//  AppController.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/20.
//


import SwiftUI
import SwiftData

class AppController: ObservableObject {
    @Published var accountId: String = ""
    @Published var path = NavigationPath()
    
    static let sample = AppController(accountId: "ffffffff-1111-2222-3333-444455556666")
    
    init(){}
    
    init(accountId: String) {
        self.accountId = accountId
    }
}
