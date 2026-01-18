//
//  FilePack.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-12.
//

import Foundation
import Tono

struct FilePackager {
    let items: [Item]
    
    enum Steps {
        case jsonStart
        case zipStart
        case success
        case error
    }
    enum Exception: Error {
        case parseJsonData
        case compressionFailed
    }
    
    func start(callBack: (_ step: Steps, _ remarks: String?) -> Void) throws -> Data {
        // JSON DATA PACKING
        callBack(.jsonStart, nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        guard let jsonData = try? encoder.encode(items) as NSData else {
            callBack(.error, "Parsing to json failed")
            throw Exception.parseJsonData
        }
        
#if DEBUG
        if let jsonString = String(data: jsonData as Data, encoding: .utf8)  {
            print(jsonString)
        }
#endif
        
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
        }
    }
}
