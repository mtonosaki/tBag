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
    
    func searchFiles(folder: String) async throws -> [(String, Date)] {
        let folderId = try await findOrCreateFolder(named: folder)
        let query = "'\(folderId)' in parents and trashed = false"
        var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: "files(name, modifiedTime)"),
            URLQueryItem(name: "pageSize", value: "1000") // 必要に応じて調整
        ]
        
        guard let url = components.url else {
            throw DriveError.folderSearchFailed("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(user.accessToken.tokenString)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError.folderSearchFailed("HTTP Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }

        let result = try JSONDecoder().decode(DriveSearchFileList.self, from: data)
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let backupFormatter = ISO8601DateFormatter()
        
        return result.files.compactMap { file in
            guard let timeString = file.modifiedTime,
                  let date = formatter.date(from: timeString) ?? backupFormatter.date(from: timeString) else {
                return nil
            }
            return (file.name, date)
        }
    }
    
    func getLastModified(fileName: String, folder: String) async throws -> Date? {
        let folderId = try await findOrCreateFolder(named: folder)
        let query = "name = '\(fileName)' and '\(folderId)' in parents and trashed = false"
        var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: "files(id, name, modifiedTime)"),
            URLQueryItem(name: "pageSize", value: "1")
        ]
        guard let url = components.url else {
            throw DriveError.folderSearchFailed("Invalid URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(user.accessToken.tokenString)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }
        let result = try JSONDecoder().decode(DriveFileList.self, from: data)
        
        guard let modifiedTimeString = result.files.first?.modifiedTime else {
            return nil
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: modifiedTimeString) ?? ISO8601DateFormatter().date(from: modifiedTimeString)
    }
    
    func load(fileName: String, folder: String, callBack: (_ step: StorageHandlingSteps, _ remarks: String?) -> Void) async throws -> Data {
        let folderId = try await findOrCreateFolder(named: folder)
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
        folder: String,
        fileContent: Data,
        mimeType: String,
        isOverride: Bool
    ) async throws {
        let folderId = try await findOrCreateFolder(named: folder)
        var existingFileId: String?
        
        if isOverride {
            let query = "name = '\(fileName)' and '\(folderId)' in parents and trashed = false"
            let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let searchUrl = URL(string: "https://www.googleapis.com/drive/v3/files?q=\(encodedQuery)")!
            
            var searchRequest = URLRequest(url: searchUrl)
            searchRequest.setValue("Bearer \(user.accessToken.tokenString)", forHTTPHeaderField: "Authorization")
            
            let (data, _) = try await URLSession.shared.data(for: searchRequest)
            let result = try JSONDecoder().decode(DriveFileList.self, from: data)
            existingFileId = result.files.first?.id
        }

        let url: URL
        let httpMethod: String
        if let fileId = existingFileId {
            url = URL(string: "https://www.googleapis.com/upload/drive/v3/files/\(fileId)?uploadType=multipart")!
            httpMethod = "PATCH"
        } else {
            url = URL(string: "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")!
            httpMethod = "POST"
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod
        request.setValue("Bearer \(user.accessToken.tokenString)", forHTTPHeaderField: "Authorization")
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()

        // Part No.1 -- meta data
        var metadata: [String: Any] = ["name": fileName, "mimeType": mimeType]
        if existingFileId == nil {
            metadata["parents"] = [folderId]
        }
        let metadataData = try JSONSerialization.data(withJSONObject: metadata)
        body.append("--\(boundary)\r\n")
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n")
        body.append(metadataData)
        body.append("\r\n")
        
        // Part No.2 -- content body
        body.append("--\(boundary)\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(fileContent)
        body.append("\r\n")
        
        // Part No.3 -- Terminater
        body.append("--\(boundary)--\r\n")

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
    let modifiedTime: String?
}

private struct DriveSearchFileList: Codable {
    let files: [DriveSearchFile]
}

private struct DriveSearchFile: Codable {
    let name: String
    let modifiedTime: String?
}
