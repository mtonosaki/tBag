//
//  SyncIconService.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2026-02-16.
//

import Foundation
import GoogleSignIn
import Tono
import SwiftData

class SyncIconService {
    
    private let user: GIDGoogleUser
    
    init(user: GIDGoogleUser) {
        self.user = user
    }

    func save(onUpdate: @escaping (_ progress: Double, _ status: String?) -> Void) async throws {
        onUpdate(2.0, "Querying local icon files...")
        
        let left = 98.0
        var errorCount = 0
        var itemCount = 0.0
        var savedCount = 0
        var foundCount = 0
        let cloudDriveRepository = GoogleDriveRepository(user: user)
        let items = LocalImageStore.searchFileNames(folder: .icons)
        for (fileName, localTimeStamp) in items {
            if let imageData = LocalImageStore.loadData(folder: .icons, fileName: fileName) {
                do {
                    itemCount += 0.5
                    var progressValue = itemCount / Double(items.count) * left + (100.0 - left)
                    onUpdate(progressValue, "Uploading icon \(Int(itemCount)) of \(items.count)")
                    
                    if let cloudTimeStamp = try? await cloudDriveRepository.getLastModified(fileName: fileName, folder: "tbag-icon") {
                        print("--- Icon have not saved it found in Google Drive: \(fileName) saved at \(cloudTimeStamp)")
                        foundCount += 1
                        if foundCount > 2 {
                            break
                        }
                        continue
                    }
                    foundCount = 0
                    itemCount += 0.5
                    progressValue = itemCount / Double(items.count) * left + (100.0 - left)
                    onUpdate(progressValue, "Uploading icon \(Int(itemCount)) of \(items.count)")

                    try await cloudDriveRepository.save(
                        fileName: fileName,
                        folder: "tbag-icon",
                        fileContent: imageData,
                        mimeType: "image/png",
                        isOverride: true
                    )
                    savedCount += 1
                    print("--- Icon saved to Google Drive: \(fileName) createdAt: \(localTimeStamp)")
                } catch {
                    errorCount += 1
                }
            } else {
                errorCount += 1
            }
        }
        onUpdate(100.0, "\(savedCount) icons uploaded. | \(items.count - savedCount - errorCount) skipped. | \(errorCount) errors.")
    }
    
    func load(
        accountId: String,
        onUpdate: @escaping (_ progress: Double, _ status: String?) -> Void
    ) async throws {
        onUpdate(4.0, "Downloading icon files...")
        
        let cloudDriveRepository = GoogleDriveRepository(user: user)
        guard let items = try? await cloudDriveRepository.searchFiles(folder: "tbag-icon") else {
            onUpdate(6.0, "ERROR: Could not get icon names...")
            return
        }
        let left = 96.0
        var loadCount = 0.0
        var loadBytes = 0
        var skipCount = 0
        
        for (fileName, timeStamp) in items {
            loadCount += 1.0
            if LocalImageStore.isExisting(folder: .icons, fileName: fileName) {
                skipCount += 1
                continue
            }
            guard let data = try? await cloudDriveRepository.load(fileName: fileName, folder: "tbag-icon", callBack: {_, _ in }) else {
                continue
            }
            print("==== file = \(fileName) \(data.count)bytes, time = \(timeStamp)")
            LocalImageStore.save(data: data, folder: .icons, fileName: fileName)
            
            let progressValue = loadCount / Double(items.count) * left + (100.0 - left)
            loadBytes += data.count
            onUpdate(progressValue, "Icon #\(Int(loadCount))/\(items.count) loaded.")
        }
        let sizeString = ByteCountFormatter().string(fromByteCount: Int64(loadBytes))
        onUpdate(100.0, "\(items.count) icons loaded successfully. total size = \(sizeString) | \(skipCount) skipped.")
    }
}
