//
//  SyncViewModel.swift
//  tBag
//
//  Created by Gemini CLI on 2026-04-26.
//

import SwiftUI
import SwiftData
import GoogleSignIn

@Observable
class SyncViewModel {
    var status: String = ""
    var progressTotal: Double = 0.0
    var progressValue: Double = 0.0
    var isProcessing: Bool { progressTotal > 0.0 }
    
    var appAccountId: String {
        appController.accountId
    }
    
    private let authViewModel: AuthViewModel
    private let appController: AppController
    private let viewConfig: ViewConfig
    private let serviceFactory: SyncServiceFactoryProtocol
    
    init(authViewModel: AuthViewModel, appController: AppController, viewConfig: ViewConfig, serviceFactory: SyncServiceFactoryProtocol = SyncServiceFactory.shared) {
        self.authViewModel = authViewModel
        self.appController = appController
        self.viewConfig = viewConfig
        self.serviceFactory = serviceFactory
    }
    
    @MainActor
    func backupItems(items: [Item], toast: ((String) -> Void)?) async {
        do {
            guard let user = authViewModel.user else { return }
            progressTotal = 100.0
            progressValue = 0.0
            
            let syncService = serviceFactory.makeSyncItemService(user: user)
            try await syncService.backup(items: items, accountId: appController.accountId) { progress, status in
                self.progressValue = progress
                if let status = status { self.status = status }
            }
            viewConfig.cancelButtonTitle = "← Back"
        } catch {
            toast?("Password backup error \(error)")
            progressTotal = 0.0
        }
    }
    
    @MainActor
    func restoreItems(context: ModelContext, toast: ((String) -> Void)?) async {
        do {
            guard let user = authViewModel.user else { return }
            progressTotal = 100.0
            progressValue = 0.0

            let syncService = serviceFactory.makeSyncItemService(user: user)
            let loadedItems = try await syncService.restore(accountId: appController.accountId) { progress, status in
                self.progressValue = progress
                if let status = status { self.status = status }
            }
            
            print("Successfully restored items from Google Drive. Count: \(loadedItems.count)")
            
            let fetchDescriptor = FetchDescriptor<Item>()
            let existingItems = try context.fetch(fetchDescriptor)
            var existingDict = [String: Item]()
            for item in existingItems {
                existingDict[item.id] = item
            }
            
            for loadedItem in loadedItems {
                if let existing = existingDict[loadedItem.id] {
                    // Update existing item to preserve its CloudKit identity
                    existing.ownerId = loadedItem.ownerId
                    existing.type = loadedItem.type
                    existing.timestamp = loadedItem.timestamp
                    existing.sortValue = loadedItem.sortValue
                    existing.caption = loadedItem.caption
                    existing.iconFileName = loadedItem.iconFileName
                    existing.attributes = loadedItem.attributes
                    existing.attributeHistories = loadedItem.attributeHistories
                    existingDict.removeValue(forKey: loadedItem.id)
                } else {
                    // Insert if it does not exist locally
                    context.insert(loadedItem)
                }
            }
            
            // Delete any local items that are not present in the restored data
            for (_, itemToDelete) in existingDict {
                context.delete(itemToDelete)
            }
            
            print("Successfully merged items into context.")
            viewConfig.cancelButtonTitle = "← Back"
        } catch {
            print("Restore error encountered: \(error)")
            if let localizedError = error as? LocalizedError {
                print("Localized description: \(localizedError.errorDescription ?? "nil")")
            }
            toast?("Password restore error \(error.localizedDescription)")
            progressTotal = 0.0
        }
    }
    
    @MainActor
    func saveIcons(toast: ((String) -> Void)?) async {
        do {
            guard let user = authViewModel.user else { return }
            progressTotal = 100.0
            progressValue = 0.0
            
            let syncService = serviceFactory.makeSyncIconService(user: user)
            try await syncService.save { progress, status in
                self.progressValue = progress
                if let status = status { self.status = status }
            }
            viewConfig.cancelButtonTitle = "← Back"
        } catch {
            toast?("Icon Upload error \(error)")
            progressTotal = 0.0
        }
    }

    @MainActor
    func loadIcons(toast: ((String) -> Void)?) async {
        do {
            guard let user = authViewModel.user else { return }
            progressTotal = 100.0
            progressValue = 0.0
            
            let syncService = serviceFactory.makeSyncIconService(user: user)
            try await syncService.load(accountId: appController.accountId) { progress, status in
                self.progressValue = progress
                if let status = status { self.status = status }
            }
            viewConfig.cancelButtonTitle = "← Back"
        } catch {
            toast?("Icon load error \(error)")
            progressTotal = 0.0
        }
    }
}
