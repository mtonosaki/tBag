//
//  SyncServiceFactory.swift
//  tBag
//
//  Created by Gemini CLI on 2026-04-26.
//

import Foundation
import GoogleSignIn
import SwiftUI

protocol SyncServiceFactoryProtocol {
    func makeSyncItemService(user: GIDGoogleUser) -> SyncItemService
    func makeSyncIconService(user: GIDGoogleUser) -> SyncIconService
}

class SyncServiceFactory: SyncServiceFactoryProtocol {
    static let shared = SyncServiceFactory()
    
    func makeSyncItemService(user: GIDGoogleUser) -> SyncItemService {
        return SyncItemService(user: user)
    }
    
    func makeSyncIconService(user: GIDGoogleUser) -> SyncIconService {
        return SyncIconService(user: user)
    }
}

private struct SyncServiceFactoryKey: EnvironmentKey {
    static let defaultValue: SyncServiceFactoryProtocol = SyncServiceFactory.shared
}

extension EnvironmentValues {
    var syncServiceFactory: SyncServiceFactoryProtocol {
        get { self[SyncServiceFactoryKey.self] }
        set { self[SyncServiceFactoryKey.self] = newValue }
    }
}
