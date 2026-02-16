//
//  FilePack.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-12.
//

import Foundation
import Tono

struct FilePackager {
    enum PackSteps {
        case jsonStart
        case zipStart
        case unzipStart
        case success
        case error
    }
    enum Exception: Error {
        case parseJsonData
        case compressionFailed
        case decompressionFailed
    }

    func unpack(data: Data, callBack: (_ step: PackSteps, _ remarks: String?) -> Void) throws -> [Item] {
        callBack(.unzipStart, nil)
        guard let jsonData = try? (data as NSData).decompressed(using: .zlib) as Data else {
            callBack(.error, "Decompression failed")
            throw Exception.decompressionFailed
        }
        
        callBack(.jsonStart, nil)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let loadedItems = try decoder.decode([Item].self, from: jsonData)
            callBack(.success, "\(loadedItems.count) items loaded")
            return loadedItems
            
        } catch {
            callBack(.error, "Parsing json failed: \(error.localizedDescription)")
            throw Exception.parseJsonData
        }
    }
    
    func pack(items: [Item], callBack: (_ step: PackSteps, _ remarks: String?) -> Void) throws -> Data {
        // JSON DATA PACKING
        callBack(.jsonStart, nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        guard let jsonData = try? encoder.encode(items) as NSData else {
            callBack(.error, "Parsing to json failed")
            throw Exception.parseJsonData
        }
        
        // ZIP COMPRESS
        callBack(.zipStart, nil)
        guard let compressedData = try? (jsonData as NSData).compressed(using: .zlib) as Data else {
            callBack(.error, "Compression failed")
            throw Exception.compressionFailed
        }
        
        callBack(.success, "\(compressedData.count) bytes")
        return compressedData
    }
}

extension FilePackager.Exception: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .parseJsonData:
            return "Error when parsing json data"
        case .compressionFailed:
            return "Error when compressing data"
        case .decompressionFailed:
            return "Error when decompressing data"
        }
    }
}
