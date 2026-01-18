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
    
    enum Steps {
        case foundFolder
        case foundDriveFileList
        case downloaded
    }

    init(user: GIDGoogleUser) {
        self.user = user
    }
    
    func load(fileName: String, callBack: (_ step: Steps, _ remarks: String?) -> Void) async throws -> Data {
        let folderId = try await findOrCreateFolder(named: "tbag")
        let query = "name = '\(fileName)' and '\(folderId)' in parents and trashed = false"
        var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: "files(id, name)"),
            URLQueryItem(name: "orderBy", value: "createdTime desc"),
            URLQueryItem(name: "pageSize", value: "1")
        ]
    
        guard let searchUrl = components.url else {
            throw DriveError.uploadFailed("Invalid URL")
        }
        
        var searchRequest = URLRequest(url: searchUrl)
        searchRequest.httpMethod = "GET"
        searchRequest.setValue("Bearer \(user.accessToken.tokenString)", forHTTPHeaderField: "Authorization")
        
        let (searchData, searchResponse) = try await URLSession.shared.data(for: searchRequest)
        
        guard let httpSearchResponse = searchResponse as? HTTPURLResponse,
              httpSearchResponse.statusCode == 200 else {
            throw DriveError.uploadFailed("Search failed: \((searchResponse as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        callBack(.foundFolder, nil)
        
        let fileList = try JSONDecoder().decode(DriveFileList.self, from: searchData)
        guard let fileId = fileList.files.first?.id else {
            throw DriveError.fileNotFound(fileName)
        }
        callBack(.foundDriveFileList, nil)
        
        let downloadUrl = URL(string: "https://www.googleapis.com/drive/v3/files/\(fileId)?alt=media")!
        var downloadRequest = URLRequest(url: downloadUrl)
        downloadRequest.httpMethod = "GET"
        downloadRequest.setValue("Bearer \(user.accessToken.tokenString)", forHTTPHeaderField: "Authorization")
        let (fileContent, downloadResponse) = try await URLSession.shared.data(for: downloadRequest)

        guard let httpDownloadResponse = downloadResponse as? HTTPURLResponse, httpDownloadResponse.statusCode == 200 else {
            throw DriveError.downloadFailed("Download failed: \((downloadResponse as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        callBack(.downloaded, nil)
        
        return fileContent
    }

    func save(
        fileName: String,
        fileContent: Data,
        mimeType: String,
    ) async throws {
        let url = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(user.accessToken.tokenString)", forHTTPHeaderField: "Authorization")
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()

        // Part No.1 -- meta data
        let folderId = try await findOrCreateFolder(named: "tbag")
        var metadata: [String: Any] = ["name": fileName, "mimeType": mimeType]
        metadata["parents"] = [folderId]
        guard let metadataData = try? JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted) else {
            throw DriveError.jsonSerializationFailed
        }
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Type: application/json; charset=UTF-8\r\n\r\n".utf8))
        body.append(metadataData)
        body.append(Data("\r\n".utf8))
        
        // Part No.2 -- content body
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
        body.append(fileContent)
        body.append(Data("\r\n".utf8))
        
        // Part No.3 -- Terminater
        body.append(Data("--\(boundary)--\r\n".utf8))

        request.httpBody = body
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError.uploadFailed("HTTP Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
    }
    
    private func findOrCreateFolder(named name: String) async throws -> String {
        if let existingFolderId = try await findFolder(named: name) {
            return existingFolderId
        } else {
            let newFolderId = try await createFolder(named: name)
            return newFolderId
        }
    }
    
    private func findFolder(named name: String) async throws -> String? {
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

        let result = try JSONDecoder().decode(DriveFileList.self, from: data)
        return result.files.first?.id
    }
    
    private func createFolder(named name: String) async throws -> String {
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
    case downloadFailed(String)
    case fileNotFound(String)
}

private struct DriveFileList: Codable {
    let files: [DriveFile]
}

private struct DriveFile: Codable {
    let id: String
    let name: String
}
