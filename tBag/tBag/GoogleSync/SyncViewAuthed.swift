//
//  SyncView+Upload.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-09.
//

import SwiftUI
import SwiftData
import Tono

struct SyncViewAuthed: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.modelContext) private var context

    var displayName: String
    
    @EnvironmentObject var appController: AppController
    @EnvironmentObject var viewConfig: ViewConfig
    @Environment(\.displayToast) var toast
    @State var status: String = ""
    @State var progressTotal: Double = 0.0
    @State var progressValue: Double = 0.0
    @Query private var items: [Item]
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    Text(displayName).font(.title2)
#if os(iOS)
                    Text("UserID").font(.caption2)
                    Text(appController.accountId).padding(.bottom, 8)
#elseif os(macOS)
                    HStack(spacing: 0) {
                        Text("UserID: ").font(.caption).foregroundColor(.gray)
                        Text(appController.accountId).font(.caption)
                    }.padding(.bottom, 8)
#endif
                    GroupBox {
                        Text("\(items.count) records")
                        
                        HStack(spacing: 24) {
                            Button {
                                withAnimation {
                                    proxy.scrollTo(Ids.progressBar, anchor: .bottom)
                                }
                                Task {
                                    do {
                                        try await backupItemsToCloud()
                                    } catch {
                                        toast?("Password backup error \(error)")
                                    }
                                }
                            } label: {
                                Label("SAVE", systemImage: "icloud.and.arrow.up")
                                    .padding()
                            }
                            .buttonStyle(.glassProminent)
                            .clipShape(Capsule())
                            .padding(.vertical)
                            .disabled(progressTotal > 0.0)
                            
                            Button {
                                withAnimation {
                                    proxy.scrollTo(Ids.progressBar, anchor: .bottom)
                                }
                                Task {
                                    do {
                                        try await restoreItemsFromCloud()
                                    } catch {
                                        toast?("Password resotre error \(error)")
                                    }
                                }
                                
                            } label: {
                                Label("LOAD", systemImage: "icloud.and.arrow.down")
                                    .padding()
                            }
                            .buttonStyle(.glassProminent)
                            .clipShape(Capsule())
                            .padding(.vertical)
                            .disabled(progressTotal > 0.0)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Text("tBag will backup and restore your passwords to/from your Google Drive.  To load from Google Drive, the all local data will be changed to the cloud version.  Undo is not available.").font(.footnote)
                    } label: {
                        Label("Password", systemImage: "text.pad.header").font(.headline).padding(.top)
                    }
                    .padding()
#if os(macOS)
                    .frame(maxWidth: 400, maxHeight: .infinity)
#endif
                    
                    GroupBox {
                        HStack(spacing: 24) {
                            Button {
                                withAnimation {
                                    proxy.scrollTo(Ids.progressBar, anchor: .bottom)
                                }
                                Task {
                                    do {
                                        try await saveIconsToCloud()
                                    } catch {
                                        toast?("Icon Upload error \(error)")
                                    }
                                }
                            } label: {
                                Label("SAVE", systemImage: "icloud.and.arrow.up")
                                    .padding()
                            }
                            .buttonStyle(.glassProminent)
                            .clipShape(Capsule())
                            .padding(.vertical)
                            .disabled(progressTotal > 0.0)
                            
                            Button {
                                withAnimation {
                                    proxy.scrollTo(Ids.progressBar, anchor: .bottom)
                                }
                                Task {
                                    do {
                                        try await loadIconsFromCloud()
                                    } catch {
                                        toast?("Icon load error \(error)")
                                    }
                                }
                                
                            } label: {
                                Label("LOAD", systemImage: "icloud.and.arrow.down")
                                    .padding()
                            }
                            .buttonStyle(.glassProminent)
                            .clipShape(Capsule())
                            .padding(.vertical)
                            .disabled(progressTotal > 0.0)
                        }
                        .frame(maxWidth: .infinity)
                        
                        Text("tBag will save and load icons to/from your Google Drive. To load icons, the cloud version will add to the local icon collection").font(.footnote)
                    } label: {
                        Label("Icons", systemImage: "photo.circle").font(.headline).padding(.top)
                    }
#if os(macOS)
                    .frame(maxWidth: 400, maxHeight: .infinity)
#endif
                    .padding()
                    
                    ProgressView(value: progressValue, total: progressTotal)
                        .padding(.horizontal, 20)
                        .opacity(progressTotal)
                    
                    Text(status).foregroundColor(.secondary)
                        .padding(.bottom, 8)
                        .id(Ids.progressBar)
                }
            }
            .groupBoxStyle(GlassGroupBoxStyle())
            .background {
                BackgroundScatteredTrianglesSpin()
                    .ignoresSafeArea()
            }
        }
    }

    enum Ids: Hashable {
        case progressBar
    }

    func backupItemsToCloud() async throws {
        guard let user = authViewModel.user else { return }
        progressTotal = 100.0
        progressValue = 0.0
        
        let syncService = SyncItemService(user: user)
        try await syncService.backup(items: self.items, accountId: appController.accountId) { progress, status in
            self.progressValue = progress
            if let status = status { self.status = status }
        }
        viewConfig.cancelButtonTitle = "← Back"
    }
    
    func restoreItemsFromCloud() async throws {
        guard let user = authViewModel.user else { return }
        progressTotal = 100.0
        progressValue = 0.0

        let syncService = SyncItemService(user: user)
        let loadedItems = try await syncService.restore(accountId: appController.accountId) { progress, status in
            self.progressValue = progress
            if let status = status { self.status = status }
        }
        
        try? context.delete(model: Item.self)
        loadedItems.forEach {
            context.insert($0)
        }
    }
    
    func saveIconsToCloud() async throws {
        guard let user = authViewModel.user else { return }
        progressTotal = 100.0
        progressValue = 0.0
        
        let syncService = SyncIconService(user: user)
        try await syncService.save { progress, status in
            self.progressValue = progress
            if let status = status { self.status = status }
        }
        viewConfig.cancelButtonTitle = "← Back"
    }

    func loadIconsFromCloud() async throws {
        guard let user = authViewModel.user else { return }
        progressTotal = 100.0
        progressValue = 0.0
        
        let syncService = SyncIconService(user: user)
        try await syncService.load(accountId: appController.accountId) { progress, status in
            self.progressValue = progress
            if let status = status { self.status = status }
        }
    }
}

#Preview {
    SyncViewAuthed(
        authViewModel: AuthViewModel(userDisplayName: "Hoge Taro"),
        displayName: "山田 太郎",
        status: "本日は晴天なり",
        progressTotal: 100.0,
    )
    .frame(width: 900, height: 300)
    .modelContainer(makeSampleModelContainer()!)
    .environmentObject(makeSampleAppController())
    .environmentObject(ViewConfig())
}
