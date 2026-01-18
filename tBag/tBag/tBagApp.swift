//
//  tBagApp.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-01.
//

import SwiftUI
import SwiftData
import GoogleSignIn

@main
struct tBagApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self
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
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView()
                .displayToast(handledBy: toastHandler)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(appController)
        .commandsReplaced(content: {
            CommandGroup(
                replacing: .appInfo,
                addition: {
                    Button(
                        action: {
                            #if os(macOS)
                                openWindow(id: "about")
                            #endif
                        },
                        label: { Text("About tBag") }
                    )
                }
            )
        })

#if os(macOS)
    Settings {
        SettingView()
    }

    Window(
        "About tBag",
        id: "about",
        content: {
            AboutView()
                .toolbar(removing: .title)
                .toolbarBackground(.hidden, for: .windowToolbar)
                .containerBackground(.thickMaterial, for: .window)
                .windowMinimizeBehavior(.disabled)
                .frame(width: 640, height: 320)
        }
    )
    .windowResizability(.contentSize)
    .restorationBehavior(.disabled)
#endif
    }
}
