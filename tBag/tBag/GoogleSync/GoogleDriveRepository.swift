//
//  GoogleDriveRepository.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-07.
//

import SwiftUI
import GoogleSignIn

class GoogleDriveRepository: StorageRepository {
    private let apiClient: GoogleDriveAPIClientProtocol
    
    init(user: GIDGoogleUser) {
        self.apiClient = GoogleDriveAPIClient(user: user)
    }
    
    init(apiClient: GoogleDriveAPIClientProtocol) {
        self.apiClient = apiClient
    }
    
    func searchFiles(folder: String) async throws -> [(String, Date)] {
        let folderId = try await findOrCreateFolder(named: folder)
        let query = "'\(folderId)' in parents and trashed = false"
        let files = try await apiClient.getFiles(query: query, fields: "files(name, modifiedTime)")
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let backupFormatter = ISO8601DateFormatter()
        
        return files.compactMap { file in
            guard let name = file.name,
                  let timeString = file.modifiedTime,
                  let date = formatter.date(from: timeString) ?? backupFormatter.date(from: timeString) else {
                return nil
            }
            return (name, date)
        }
    }
    
    func getLastModified(fileName: String, folder: String) async throws -> Date? {
        let folderId = try await findOrCreateFolder(named: folder)
        let query = "name = '\(fileName)' and '\(folderId)' in parents and trashed = false"
        let files = try await apiClient.getFiles(query: query, fields: "files(id, name, modifiedTime)")
        
        guard let firstFile = files.first, let modifiedTimeString = firstFile.modifiedTime else { return nil }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: modifiedTimeString) ?? ISO8601DateFormatter().date(from: modifiedTimeString)
    }
    
    func load(fileName: String, folder: String, callBack: (_ step: StorageHandlingSteps, _ remarks: String?) -> Void) async throws -> Data {
        let folderId = try await findOrCreateFolder(named: folder)
        let query = "name = '\(fileName)' and '\(folderId)' in parents and trashed = false"
        let files = try await apiClient.getFiles(query: query, fields: "files(id, name)")
        
        callBack(.foundFolder, nil)
        
        guard let firstFile = files.first, let fileId = firstFile.id else {
            throw DriveError.fileNotFound(fileName)
        }
        callBack(.foundDriveFileList, nil)
        
        let data = try await apiClient.downloadFile(fileId: fileId)
        callBack(.downloaded, nil)
        
        return data
    }
    
    func save(fileName: String, folder: String, fileContent: Data, mimeType: String, isOverride: Bool) async throws {
        let folderId = try await findOrCreateFolder(named: folder)
        var existingFileId: String?
        
        if isOverride {
            let query = "name = '\(fileName)' and '\(folderId)' in parents and trashed = false"
            let files = try await apiClient.getFiles(query: query, fields: "files(id)")
            existingFileId = files.first?.id.flatMap { $0 }
        }

        _ = try await apiClient.uploadFile(
            name: fileName,
            content: fileContent,
            mimeType: mimeType,
            parents: existingFileId == nil ? [folderId] : nil,
            existingFileId: existingFileId
        )
    }
    
    private func findOrCreateFolder(named name: String) async throws -> String {
        let query = "name = '\(name)' and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
        let files = try await apiClient.getFiles(query: query, fields: "files(id)")
        
        if let firstFile = files.first, let folderId = firstFile.id {
            return folderId
        } else {
            return try await apiClient.createFolder(name: name)
        }
    }
}
