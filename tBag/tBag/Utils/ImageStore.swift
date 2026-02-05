//
//  ImageStore.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2026-02-01.
//

import SwiftUI

struct ImageStore {
    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static func save(data: Data, fileName: String) {
        let url = documentsDirectory.appendingPathComponent(fileName)
        try? data.write(to: url)
    }
    
    static func load(fileName: String) -> Image? {
        let url = documentsDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        
#if os(macOS)
        if let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
#else
        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
#endif
        return nil
    }
}
