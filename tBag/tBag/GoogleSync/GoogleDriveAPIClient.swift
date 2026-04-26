//
//  GoogleDriveAPIClient.swift
//  tBag
//
//  Created by Gemini CLI on 2026-04-26.
//

import Foundation
import GoogleSignIn

protocol GoogleDriveAPIClientProtocol {
    func getFiles(query: String, fields: String) async throws -> [DriveFile]
    func downloadFile(fileId: String) async throws -> Data
    func uploadFile(name: String, content: Data, mimeType: String, parents: [String]?, existingFileId: String?) async throws -> DriveFile
    func createFolder(name: String) async throws -> String
}

class GoogleDriveAPIClient: GoogleDriveAPIClientProtocol {
    let user: GIDGoogleUser
    private let baseUrl = "https://www.googleapis.com/drive/v3/files"
    private let uploadUrl = "https://www.googleapis.com/upload/drive/v3/files"

    init(user: GIDGoogleUser) {
        self.user = user
    }

    private func setupRequest(url: URL, method: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(user.accessToken.tokenString)", forHTTPHeaderField: "Authorization")
        return request
    }

    func getFiles(query: String, fields: String = "files(id, name, modifiedTime)") async throws -> [DriveFile] {
        var components = URLComponents(string: baseUrl)!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: fields),
            URLQueryItem(name: "pageSize", value: "1000")
        ]
        
        guard let url = components.url else { throw DriveError.folderSearchFailed("Invalid URL") }
        let request = setupRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError.folderSearchFailed("HTTP Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        
        let result = try JSONDecoder().decode(DriveFileList.self, from: data)
        return result.files
    }

    func downloadFile(fileId: String) async throws -> Data {
        let url = URL(string: "\(baseUrl)/\(fileId)?alt=media")!
        let request = setupRequest(url: url, method: "GET")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError.downloadFailed("HTTP Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        return data
    }

    func uploadFile(name: String, content: Data, mimeType: String, parents: [String]?, existingFileId: String?) async throws -> DriveFile {
        let url: URL
        let method: String
        if let fileId = existingFileId {
            url = URL(string: "\(uploadUrl)/\(fileId)?uploadType=multipart")!
            method = "PATCH"
        } else {
            url = URL(string: "\(uploadUrl)?uploadType=multipart")!
            method = "POST"
        }
        
        var request = setupRequest(url: url, method: method)
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        var metadata: [String: Any] = ["name": name, "mimeType": mimeType]
        if let parents = parents, existingFileId == nil {
            metadata["parents"] = parents
        }
        
        let metadataData = try JSONSerialization.data(withJSONObject: metadata)
        body.append("--\(boundary)\r\n")
        body.append("Content-Type: application/json; charset=UTF-8\r\n\r\n")
        body.append(metadataData)
        body.append("\r\n")
        body.append("--\(boundary)\r\n")
        body.append("Content-Type: \(mimeType)\r\n\r\n")
        body.append(content)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")
        request.httpBody = body
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError.uploadFailed("HTTP Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        
        return try JSONDecoder().decode(DriveFile.self, from: data)
    }

    func createFolder(name: String) async throws -> String {
        let url = URL(string: baseUrl)!
        var request = setupRequest(url: url, method: "POST")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let metadata: [String: Any] = [
            "name": name,
            "mimeType": "application/vnd.google-apps.folder"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: metadata)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw DriveError.folderCreationFailed("HTTP Status: \((response as? HTTPURLResponse)?.statusCode ?? 0)")
        }
        
        let newFolder = try JSONDecoder().decode(DriveFile.self, from: data)
        guard let folderId = newFolder.id else {
            throw DriveError.folderCreationFailed("Folder ID not returned")
        }
        return folderId
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

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

// Data models moved from Repository
struct DriveFileList: Codable {
    let files: [DriveFile]
}

struct DriveFile: Codable {
    let id: String?
    let name: String?
    let modifiedTime: String?
}
