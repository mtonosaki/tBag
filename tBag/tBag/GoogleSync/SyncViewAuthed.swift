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
    @Query private var items: [Item]
    @Environment(\.modelContext) private var context
    @Environment(\.displayToast) var toast
    @Environment(\.syncServiceFactory) var syncServiceFactory
    
    @State private var viewModel: SyncViewModel
    var displayName: String
    
    init(authViewModel: AuthViewModel, appController: AppController, viewConfig: ViewConfig, displayName: String, syncServiceFactory: SyncServiceFactoryProtocol = SyncServiceFactory.shared) {
        self.displayName = displayName
        self._viewModel = State(wrappedValue: SyncViewModel(
            authViewModel: authViewModel,
            appController: appController,
            viewConfig: viewConfig,
            serviceFactory: syncServiceFactory
        ))
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack {
                    Text(displayName).font(.title2)
#if os(iOS)
                    Text("UserID").font(.caption2)
                    Text(viewModel.appAccountId).padding(.bottom, 8)
#elseif os(macOS)
                    HStack(spacing: 0) {
                        Text("UserID: ").font(.caption).foregroundColor(.gray)
                        Text(viewModel.appAccountId).font(.caption)
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
                                    await viewModel.backupItems(items: items, toast: toast)
                                }
                            } label: {
                                Label("SAVE", systemImage: "icloud.and.arrow.up")
                                    .padding()
                            }
                            .buttonStyle(.glassProminent)
                            .clipShape(Capsule())
                            .padding(.vertical)
                            .disabled(viewModel.isProcessing)
                            
                            Button {
                                withAnimation {
                                    proxy.scrollTo(Ids.progressBar, anchor: .bottom)
                                }
                                Task {
                                    await viewModel.restoreItems(context: context, toast: toast)
                                }
                                
                            } label: {
                                Label("LOAD", systemImage: "icloud.and.arrow.down")
                                    .padding()
                            }
                            .buttonStyle(.glassProminent)
                            .clipShape(Capsule())
                            .padding(.vertical)
                            .disabled(viewModel.isProcessing)
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
                                    await viewModel.saveIcons(toast: toast)
                                }
                            } label: {
                                Label("SAVE", systemImage: "icloud.and.arrow.up")
                                    .padding()
                            }
                            .buttonStyle(.glassProminent)
                            .clipShape(Capsule())
                            .padding(.vertical)
                            .disabled(viewModel.isProcessing)
                            
                            Button {
                                withAnimation {
                                    proxy.scrollTo(Ids.progressBar, anchor: .bottom)
                                }
                                Task {
                                    await viewModel.loadIcons(toast: toast)
                                }
                                
                            } label: {
                                Label("LOAD", systemImage: "icloud.and.arrow.down")
                                    .padding()
                            }
                            .buttonStyle(.glassProminent)
                            .clipShape(Capsule())
                            .padding(.vertical)
                            .disabled(viewModel.isProcessing)
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
                    
                    ProgressView(value: viewModel.progressValue, total: viewModel.progressTotal)
                        .padding(.horizontal, 20)
                        .opacity(viewModel.progressTotal > 0 ? 1 : 0)
                    
                    Text(viewModel.status).foregroundColor(.secondary)
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
}

#Preview {
    let authVM = AuthViewModel(userDisplayName: "Hoge Taro")
    let appCtrl = makeSampleAppController()
    let viewConf = ViewConfig()
    
    SyncViewAuthed(
        authViewModel: authVM,
        appController: appCtrl,
        viewConfig: viewConf,
        displayName: "山田 太郎"
    )
    .frame(width: 900, height: 300)
    .modelContainer(makeSampleModelContainer()!)
    .environmentObject(appCtrl)
    .environmentObject(viewConf)
}
