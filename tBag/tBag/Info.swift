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
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "(unknown)"
    }

    static var build: Any {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") ?? "(unknown)"
    }
 }
