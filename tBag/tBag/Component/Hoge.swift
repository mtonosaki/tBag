//
//  Hoge.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/20.
//

import SwiftUI

struct Hoge : View {
    @EnvironmentObject var appController: AppController

    var body: some View {
        VStack {
            Text("HOGE")
            Text("Account ID: \(appController.accountId)")
        }
    }
}
