//
//  SyncService.swift
//  tBag
//
//  Created by Gemini CLI on 2026-02-16.
//

import Foundation
import GoogleSignIn
import Tono
import SwiftData

class SyncItemService {
    
    private let user: GIDGoogleUser
    
    init(user: GIDGoogleUser) {
        self.user = user
    }
    
    func backup(
        items: [Item],
        accountId: String,
        onUpdate: @escaping (_ progress: Double, _ status: String?) -> Void
    ) async throws {
        let stepProgresses: [FilePackager.PackSteps: Double] = [
            .jsonStart: 2.0,
            .zipStart: 5.0,
            .success: 10.0,
            .error: 0.0
        ]
        
        let filePackager = FilePackager()
        let compressedData = try filePackager.pack(items: items) { step, remarks in
            onUpdate(stepProgresses[step] ?? 0.0, remarks)
        }
        
        onUpdate(75.0, "Uploading to Google Drive...")
        
        let cloudDriveRepository = GoogleDriveRepository(user: user)
        let fileName = "\(accountId).bin"
        try await cloudDriveRepository.save(
            fileName: fileName,
            folder: "tbag-item",
            fileContent: compressedData,
            mimeType: "application/octet-stream",
            isOverride: false
        )
        
        onUpdate(100.0, "Saved as \(fileName)")
    }
    
    func restore(
        accountId: String,
        onUpdate: @escaping (_ progress: Double, _ status: String?) -> Void
    ) async throws -> [Item] {
        let stepProgresses: [AnyHashable: Double] = [
            StorageHandlingSteps.foundFolder: 7.0,
            StorageHandlingSteps.foundDriveFileList: 12.0,
            StorageHandlingSteps.downloaded: 75.0,
            FilePackager.PackSteps.unzipStart: 80.0,
            FilePackager.PackSteps.jsonStart: 90.0,
            FilePackager.PackSteps.success: 98.0,
            FilePackager.PackSteps.error: 0.0
        ]

        onUpdate(0.0, "Downloading from Google Drive...")
        
        let cloudDriveRepository = GoogleDriveRepository(user: user)
        let fileName = "\(accountId).bin"
        
        let data = try await cloudDriveRepository.load(fileName: fileName, folder: "tbag-item") { step, remarks in
            onUpdate(stepProgresses[step] ?? 0.0, remarks)
        }
        
        let filePackager = FilePackager()
        let loadedItems = try filePackager.unpack(data: data) { step, remarks in
            onUpdate(stepProgresses[step] ?? 0.0, remarks)
        }
        
        onUpdate(100.0, "Restored \(loadedItems.count) items from Google Drive successfully.")
        return loadedItems
    }
}
