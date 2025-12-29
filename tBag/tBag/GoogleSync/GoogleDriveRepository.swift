//
//  GoogleDriveUploader.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-07.
//

import SwiftUI
import GoogleSignIn
import GoogleAPIClientForREST_Drive

class GoogleDriveRepository: StorageRepository {
    var user: GIDGoogleUser
    
    init(user: GIDGoogleUser) {
        self.user = user
    }

    func save(
        fileName: String,
        fileContent: Data,
        mimeType: String,
    ) async throws -> Void {
        let url = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("Bearer \(user.accessToken.tokenString)", forHTTPHeaderField: "Authorization")
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var body = Data()
        
        // Part No.1 -- meta data
        let folderId = try await findOrCreateFolder(named: "tbag", user: user)
        var metadata: [String: Any] = ["name": fileName, "mimeType": mimeType]
        metadata["parents"] = [folderId]
        guard let metadataData = try? JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted) else {
            throw DriveError.jsonSerializationFailed
        }
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        body.append(metadataData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Part No.2 -- content body
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileContent)
        body.append("\r\n".data(using: .utf8)!)
        
        // Part No.3 -- Terminater
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError.uploadFailed("HTTP Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
    }
    
    private func findOrCreateFolder(named name: String, user: GIDGoogleUser) async throws -> String {
        if let existingFolderId = try await findFolder(named: name, user: user) {
            return existingFolderId
        } else {
            let newFolderId = try await createFolder(named: name, user: user)
            return newFolderId
        }
    }
    
    private func findFolder(named name: String, user: GIDGoogleUser) async throws -> String? {
        let query = "name = '\(name)' and mimeType = 'application/vnd.google-apps.folder' and trashed = false"
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.googleapis.com/drive/v3/files?q=\(encodedQuery)") else {
            throw DriveError.folderSearchFailed("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(user.accessToken.tokenString)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError.folderSearchFailed("HTTP Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }

        let result = try JSONDecoder().decode(FileListResponse.self, from: data)
        return result.files.first?.id
    }
    
    private func createFolder(named name: String, user: GIDGoogleUser) async throws -> String {
        let url = URL(string: "https://www.googleapis.com/drive/v3/files")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(user.accessToken.tokenString)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let metadata: [String: Any] = [
            "name": name,
            "mimeType": "application/vnd.google-apps.folder"
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: metadata) else {
            throw DriveError.jsonSerializationFailed
        }
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError.folderCreationFailed("HTTP Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        
        let newFolder = try JSONDecoder().decode(DriveFile.self, from: data)
        return newFolder.id
    }

}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

enum DriveError: Error {
    case accessTokenNotFound
    case folderSearchFailed(String)
    case folderCreationFailed(String)
    case jsonSerializationFailed
    case uploadFailed(String)
}

struct DriveFile: Codable {
    let id: String
    let name: String
}

struct FileListResponse: Codable {
    let files: [DriveFile]
}

