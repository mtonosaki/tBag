//
//  StorageRepository.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-12-30.
//


import SwiftUI

protocol StorageRepository {
    func save(
        fileName: String,
        fileContent: Data,
        mimeType: String
    ) async throws
}
