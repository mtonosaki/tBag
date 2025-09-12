//
//  FilePack.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2025-09-12.
//

import Foundation

struct FilePackager {
    var items: [Item]
    
    enum Steps {
        case jsonStart
        case jsonEnd
        case zipCompressStart
        case zipCompressEnd
    }

    func start(callBack: (_ step: Steps, _ remarks: String?) -> Void) throws -> Data {
        callBack(.jsonStart, nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(items) as NSData
        callBack(.jsonEnd, "\(jsonData.length)")
        
        callBack(.zipCompressStart, nil)
        let compressedData = try (jsonData as NSData).compressed(using: .zlib) as Data

        callBack(.zipCompressEnd, "\(compressedData.count)")

        return compressedData
    }
}

enum FilePackagerError: Error {
    case parseString
}

