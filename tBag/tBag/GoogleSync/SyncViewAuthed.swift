//
//  SyncView+Upload.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-09.
//

import SwiftUI
import SwiftData

struct SyncViewAuthed: View {
    @ObservedObject var authViewModel: AuthViewModel
    var displayName: String
    
    @EnvironmentObject var appController: AppController
    @EnvironmentObject var viewConfig: ViewConfig
    @State var status: String = ""
    @State var progressTotal: Double = 0.0
    @State var progressValue: Double = 0.0
    @Query private var items: [Item]
    
    var body: some View {
        VStack {
            Text("Name: \(displayName)").font(.title2)
#if os(iOS)
            Text("UserID")
            Text(appController.accountId).padding(.bottom, 8)
#elseif os(macOS)
            HStack(spacing: 0) {
                Text("UserID: ").font(.caption).foregroundColor(.gray)
                Text(appController.accountId).font(.caption)
            }.padding(.bottom, 8)
#endif
            Text("\(items.count) records")
            
            HStack(spacing: 24) {
                Button {
                    backupToCloud()
                } label: {
                    VStack(spacing: 0){
                        Label("BACKUP", systemImage: "icloud.and.arrow.up")
                        Text("to Google Drive")
                    }.padding()
                }
                .buttonStyle(.glassProminent)
                .padding(.vertical)
                .disabled(progressTotal > 0.0)
                
                Button {
                    
                } label: {
                    VStack(spacing: 0){
                        Label("RESTORE", systemImage: "icloud.and.arrow.down")
                        Text("local data will be removed")
                    }.padding()
                }
                .buttonStyle(.glassProminent)
                .padding(.vertical)
                .disabled(progressTotal > 0.0)
            }
            
            ProgressView(value: progressValue, total: progressTotal)
                .padding(.horizontal, 20)
                .opacity(progressTotal)
            Text(status).foregroundColor(.secondary)
                .padding(.bottom, 8)
        }
    }
    
    
    func backupToCloud(){
        Task {
            do {
                progressTotal = 100.0
                progressValue = 0.0
                var originalSize = 0.0
                var fileInfo: String = ""
                let pack = FilePackager(items: self.items)
                let compressedData = try pack.start(){ step, remarks in
                    switch step {
                    case .jsonEnd:
                        progressValue = 5.0
                        originalSize = Double(remarks!)!
                        status = "Json data: \(remarks!) bytes"
                        break
                    case .zipCompressEnd:
                        let compressedSize = Double(remarks!)!
                        fileInfo = "Zip data: \(remarks!) bytes as \(String(format: "%.0f", compressedSize / originalSize * 100))%"
                        status = fileInfo
                        progressValue = 10.0
                        break
                    default:
                        break
                    }
                }
                
                status = "\(fileInfo) | Uploading to Google Drive..."
                progressValue = 75.0
                let uploader = GoogleDriveRepository(user: authViewModel.user!)
                try await uploader.save(
                    fileName: "\(appController.accountId).bin",
                    fileContent: compressedData,
                    mimeType: "application/octet-stream"
                )
                
                status = "\(fileInfo) | Saved as \(appController.accountId).bin"
                progressValue = 100.0
                viewConfig.cancelButtonTitle = "← Back"
            }
            catch {
                self.status = "ERROR 222：\(error.localizedDescription)"                
                return
            }
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
    .frame(width: 500, height: 300)
    .modelContainer(makeSampleModelContainer()!)
    .environmentObject(makeSampleAppController())
    .environmentObject(ViewConfig())
}
