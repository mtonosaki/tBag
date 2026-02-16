//
//  StorageRepository.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-12-30.
//

import SwiftUI

protocol StorageRepository {
    func save(fileName: String, folder: String, fileContent: Data, mimeType: String, isOverride: Bool) async throws
    func load(fileName: String, folder: String, callBack: (_ step: StorageHandlingSteps, _ remarks: String?) -> Void) async throws -> Data
    func getLastModified(fileName: String, folder: String) async throws -> Date?
    func searchFiles(folder: String) async throws -> [(String, Date)]
}

enum StorageHandlingSteps {
    case foundFolder
    case foundDriveFileList
    case downloaded
}
