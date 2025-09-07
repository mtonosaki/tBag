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
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    
    private let uploader = GoogleDriveUploader()

    var body: some View {
        NavigationStack {
            VStack {
                if let displayName = authViewModel.userDisplayName {
                    Text("Hi, \(displayName) !").padding(.bottom, 8)
                    Text("UserID = \(appController.accountId)")
                    Text("\(items.count) records")
                    
                    Button {
                        Task {
                            do {
                                try await uploader.uploadFile(
                                    fileName: "hoge.txt",
                                    fileContent: "これはテストのファイルです。\(Date())",
                                    mimeType: "text/plain",
                                    user: authViewModel.user!
                                )
                                print("SUCCESS UPLOADED!")
                            }
                            catch {
                                print("ERROR 222：\(error.localizedDescription)")

                            }
                        }
                    } label: {
                        Label("UPLOAD NOW", systemImage: "icloud.and.arrow.up")
                    }

                } else {
                    Text("To sign in, tap the button below.")
                        .font(.headline)

                    GoogleSignInButton(viewModel: GoogleSignInButtonViewModel(scheme: .dark, style: .wide, state: .normal)) {
                        Task {
                            await authViewModel.signIn()
                        }
                    }
                    .frame(width: 250, height: 50)

                    if let errorMessage = authViewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        authViewModel.signOut()
                        page = .password
                    } label: {
                        Text("← Cancel")
                    }
                    .buttonStyle(.borderless)
                }
            }
         }
    }
}

#Preview {
    SyncView(
        page: .constant(.password),
        authViewModel: AuthViewModel(userDisplayName: "Hoge Taro")
    )
    .frame(width: 500, height: 500)
    .modelContainer(makeSampleModelContainer()!)
    .environmentObject(makeSampleAppController())
}

func makeSampleAppController() -> AppController {
    let sampleAppController = AppController()
    sampleAppController.accountId = "preview-hoge-2222-3333-4444"
    return sampleAppController
}

@MainActor func makeSampleModelContainer() -> ModelContainer? {
    do {
        let schema = Schema([Item.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContainer.mainContext.insert(Item.makePasswordDummy("hoge"))
        modelContainer.mainContext.insert(Item.makePasswordDummy("fuga"))
        modelContainer.mainContext.insert(Item.makePasswordDummy("piyo"))
        return modelContainer
    }
    catch {
        print("ERROR-PREVIEW")
    }
    return nil
}
