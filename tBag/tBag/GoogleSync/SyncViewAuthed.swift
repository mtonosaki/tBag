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
                            Task {
                                do {
                                    try await backupToCloud()
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
                            Task {
                                do {
                                    try await restoreFromCloud()
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
#if os(macOS)
                .frame(maxWidth: 400, maxHeight: .infinity)
#endif
                .padding()
                
                GroupBox {
                    HStack(spacing: 24) {
                        Button {
                            Task {
                                do {
                                    try await backupToCloud()
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
                            Task {
                                do {
                                    try await restoreFromCloud()
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
            }
        }
        .groupBoxStyle(GlassGroupBoxStyle())
        .background {
            GeometricBackground(pattern: .scatteredTriangles)
                .ignoresSafeArea()
        }
    }
    
    func backupToCloud() async throws {
        progressTotal = 100.0
        progressValue = 0.0
        let stepProgresses = [
            FilePackager.PackSteps.jsonStart: 2.0,
            FilePackager.PackSteps.zipStart: 5.0,
            FilePackager.PackSteps.success: 10.0
        ]
        let filePackager = FilePackager(items: self.items)
        let compressedData = try filePackager.pack { step, remarks in
            if let remarks = remarks {
                status = remarks
            }
            if let stepProgress = stepProgresses[step] {
                progressValue = stepProgress
            }
        }
        
        status = "Uploading to Google Drive..."
        progressValue = 75.0
        let cloudDriveRepository = GoogleDriveRepository(user: authViewModel.user!)
        try await cloudDriveRepository.save(
            fileName: makeFileName(),
            fileContent: compressedData,
            mimeType: "application/octet-stream"
        )
        
        status = "Saved as \(appController.accountId).bin"
        progressValue = 100.0
        viewConfig.cancelButtonTitle = "← Back"
    }
    
    func restoreFromCloud() async throws {
        progressTotal = 100.0
        progressValue = 0.0
        let stepProgresses = [
            GoogleDriveRepository.Steps.foundFolder: 7.0,
            GoogleDriveRepository.Steps.foundDriveFileList: 12.0,
            GoogleDriveRepository.Steps.downloaded: 75.0,
            FilePackager.PackSteps.success: 98.0
        ] as [AnyHashable: Double]

        status = "Downloading from Google Drive..."
        let cloudDriveRepository = GoogleDriveRepository(user: authViewModel.user!)
        let data = try await cloudDriveRepository.load(fileName: makeFileName()) { step, remarks in
            if let remarks = remarks {
                status = remarks
            }
            if let stepProgress = stepProgresses[step] {
                progressValue = stepProgress
            }
        }
        
        let filePackager = FilePackager(items: self.items)
        let loadedItems = try filePackager.unpack(data: data) { step, remarks in
            if let remarks = remarks {
                status = remarks
            }
            if let stepProgress = stepProgresses[step] {
                progressValue = stepProgress
            }
        }
        
        try? context.delete(model: Item.self)
        loadedItems.forEach {
            context.insert($0)
        }
        progressValue = 100.0
        status = "Restored \(loadedItems.count) items from Google Drive successfully."
    }
    
    func makeFileName() -> String {
        return "\(appController.accountId).bin"
    }
}

struct GeometricBackground: View {
    enum Pattern {
        case rasterLines
        case scatteredTriangles
    }
    
    var pattern: Pattern = .rasterLines
    
    var body: some View {
        Canvas { context, size in
            switch pattern {
            case .rasterLines:
                context.opacity = 0.1
                drawRasterLines(context: context, size: size)
            case .scatteredTriangles:
                drawTriangles(context: context, size: size)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private func drawRasterLines(context: GraphicsContext, size: CGSize) {
        let step: CGFloat = 8
        let width = size.width
        let height = size.height
        var path = Path()
        
        for xpos in stride(from: -height, to: width + height, by: step) {
            path.move(to: CGPoint(x: xpos, y: 0))
            path.addLine(to: CGPoint(x: xpos + height, y: height))
        }
        
        context.stroke(path, with: .color(.gray), lineWidth: 1)
    }
    
    private func drawTriangles(context: GraphicsContext, size: CGSize) {
        let symbolsCount = 1200
        let symbolSizeBase: CGFloat = 8.0
        var rng = SystemRandomNumberGenerator()
        
        for _ in 0..<symbolsCount {
            let xpos = CGFloat.random(in: 0...size.width, using: &rng)
            let ypos = CGFloat.random(in: 0...size.height, using: &rng)
            let angle = Angle.degrees(Double.random(in: 0..<360, using: &rng))
            let symbolSize: CGFloat = Double.random(in: 0.5...1.0, using: &rng) * symbolSizeBase
            let randomOpacity = Double.random(in: 0.05...0.15, using: &rng)
            let hue = Double.random(in: 0...1, using: &rng)
            let randomColor = Color(hue: hue, saturation: 0.9, brightness: 0.9)

            context.drawLayer { subContext in
                subContext.opacity = randomOpacity
                subContext.translateBy(x: xpos, y: ypos)
                subContext.rotate(by: angle)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: -symbolSize))
                path.addLine(to: CGPoint(x: -symbolSize/1.25, y: symbolSize/2))
                path.addLine(to: CGPoint(x: symbolSize/1.25, y: symbolSize/2))
                path.closeSubpath()
                subContext.stroke(path, with: .color(randomColor), lineWidth: 1.0)
            }
        }
    }
}

struct GlassGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
                .padding(.bottom, 4)
            
            configuration.content
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
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
