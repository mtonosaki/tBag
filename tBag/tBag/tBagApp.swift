//
//  tBagApp.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025/07/07.
//

import SwiftUI
import SwiftData

@main
struct tBagApp: App {
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    @StateObject private var appController = AppController()
    @State private var toastHandler: ToastHandler = .init()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .displayToast(handledBy: toastHandler)
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(appController)
    }
}
