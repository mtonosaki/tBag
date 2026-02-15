//
//  ImageStore.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2026-02-01.
//

import SwiftUI

struct LocalImageStore {
    enum Folders: String {
        case icons
    }
    
    private static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    static func searchFileNames(folder: Folders) -> [String] {
        let targetDirectory = documentsDirectory.appendingPathComponent(folder.rawValue)
        if !FileManager.default.fileExists(atPath: targetDirectory.path) {
            return []
        }
        do {
            let resourceKeys: [URLResourceKey] = [.contentModificationDateKey]
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: targetDirectory,
                includingPropertiesForKeys: resourceKeys,
                options: .skipsHiddenFiles
            )
            let sortedURLs = fileURLs.sorted { urlLeft, urlRight in
                let timeStampLeft = (try? urlLeft.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                let timeStampRight = (try? urlRight.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? Date.distantPast
                
                return timeStampLeft > timeStampRight
            }
            return sortedURLs.map { $0.lastPathComponent }
        } catch {
            return []
        }
    }
    
    static func save(data: Data, folder: Folders, fileName: String) {
        let targetDirectory = documentsDirectory.appendingPathComponent(folder.rawValue)
        if !FileManager.default.fileExists(atPath: targetDirectory.path) {
            try? FileManager.default.createDirectory(at: targetDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        let url = targetDirectory.appendingPathComponent(fileName)
        try? data.write(to: url)
    }
    
    static func loadData(folder: Folders, fileName: String) -> Data? {
        let targetDirectory = documentsDirectory.appendingPathComponent(folder.rawValue)
        if !FileManager.default.fileExists(atPath: targetDirectory.path) {
            return nil
        }
        
        let url = documentsDirectory.appendingPathComponent(fileName)
        guard let data = try? Data(contentsOf: url) else { return nil }
        
        return data
    }
    
    static func loadImage(folder: Folders, fileName: String) -> Image? {
        guard let data = loadData(folder: folder, fileName: fileName) else { return nil }
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
