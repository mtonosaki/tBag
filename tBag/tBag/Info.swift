//
//  PropertyList.swift
//  Arenavi
//
//  Created by Manabu Tonosaki on 2025/01/07.
//

import Foundation
import Tono

struct Info {
    static var version: Any {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "?"
    }

    static var build: Any {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "?"
    }
    
    static var teamId: String {
        return Bundle.main.object(forInfoDictionaryKey: "TEAM_ID") as? String ?? "(not found TEAM_ID in Info.plist)"
    }

    static var masterSalt: String {
        return Bundle.main.object(forInfoDictionaryKey: "MASTER_SALT") as? String ?? "(not found MASTER_SALT in Info.plist)"
    }
 }
