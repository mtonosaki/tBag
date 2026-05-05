//
//  ItemBuilder.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2026/05/04.
//

import Tono
import Foundation

extension ItemBuilder {
    
    static func build(fromTSecretClipboardJson jsonData: Data, ownerAccountId: String, myRsa: Rsa) throws -> Item {
        let clipboardJson = try JSONDecoder().decode(TSecretClipboardJSON.self, from: jsonData)
        let clipboardData = clipboardJson.universalData
        let salt = "\(ownerAccountId)/\(Info.encryptSalt)"
        
        let newItem = Item(ownerId: ownerAccountId, type: .password)
        newItem.id = clipboardJson.id
        newItem.caption = clipboardData.caption?.last?.value ?? ""
        newItem.sortValue = clipboardData.captionRubi?.last?.value ?? ""
        
        func copyHistory(_ key: Item.AttributeKeys, _ clipboardItems: [TSecretHistoryItem]?) {
            guard let clipboardItems = clipboardItems else {
                newItem.attributes[key.rawValue] = []
                return
            }
            let historyForNewItem = clipboardItems.map {
                let dateTime = (try? TSecretDateConverter.convert(from: $0.dateTime)) ?? Date()
                let sealedValue = try? CryptoService.shared.seal(plainText: $0.value, recipientPublicKey: myRsa.getMyPublicKey(), salt: salt)
                return AttributeData(createdAt: dateTime, encryptedValue: sealedValue ?? "")
            }.sorted { $0.updatedAt > $1.updatedAt }
            newItem.attributes[key.rawValue] = historyForNewItem
        }
        copyHistory(.accountId, clipboardData.accountId)
        copyHistory(.password, clipboardData.password)
        copyHistory(.email, clipboardData.email)
        copyHistory(.remarks, clipboardData.memo)
        
        // generate tag using last bools
        func getBool(_ history: [TSecretHistoryItem]?) -> Bool {
            let str = history?.sorted { $0.dateTime > $1.dateTime }.first?.value ?? "False"
            return Bool(str.lowercased()) ?? false
        }
        let isFilterHome = getBool(clipboardData.isFilterHome)
        let isFilterWork = getBool(clipboardData.isFilterWork)
        let isDeleted = getBool(clipboardData.isDeleted)
        var tags: [String] = []
        if isFilterHome {
            tags.append(TagGroups.home.rawValue)
        }
        if isFilterWork {
            tags.append(TagGroups.office.rawValue)
        }
        if isDeleted {
            tags.append(TagGroups.deleted.rawValue)
        }
        let plainTags = tags.joined(separator: ",")
        let sealedTag = try CryptoService.shared.seal(plainText: plainTags, recipientPublicKey: myRsa.getMyPublicKey(), salt: salt)
        newItem.attributes[Item.AttributeKeys.tags.rawValue] = [AttributeData(encryptedValue: sealedTag)]
                
        return newItem
    }
}

struct TSecretHistoryItem: Decodable {
    let value, dateTime: String
    
    enum CodingKeys: String, CodingKey { case value = "Value", dateTime = "DT" }
}

struct TSecretUniversalData: Decodable {
    let caption, captionRubi, accountId, email, password, memo, isFilterHome, isFilterWork, isDeleted: [TSecretHistoryItem]?
    
    enum CodingKeys: String, CodingKey {
        case caption = "Caption", captionRubi = "CaptionRubi", accountId = "AccountID", email = "Email", password = "Password", memo = "Memo"
        case isFilterHome, isFilterWork, isDeleted = "IsDeleted"
    }
}

struct TSecretClipboardJSON: Decodable {
    let id: String
    let universalData: TSecretUniversalData
    
    enum CodingKeys: String, CodingKey { case id = "ID", universalData = "UniversalData" }
}

struct TSecretDateConverter {
    private static let formatters: [DateFormatter] = {
        let formats = [
            "yyyy/MM/dd HH:mm:ss.SSS",
            "yyyy/MM/dd+HH:mm:ss",
            "yyyy/MM/dd HH:mm:ss"
        ]
        
        return formats.map { format in
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone.autoupdatingCurrent
            return formatter
        }
    }()
    
    static func convert(from dateString: String) throws -> Date {
        let trimmedString = dateString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedString.isEmpty else {
            throw DateParseError.empty
        }
        
        for formatter in formatters {
            if let date = formatter.date(from: trimmedString) {
                return date
            }
        }
        throw DateParseError.invalidFormat(dateString)
    }
}

enum DateParseError: Error, LocalizedError {
    case empty
    case invalidFormat(String)
    
    var errorDescription: String? {
        switch self {
        case .empty:
            return "Invalid format empty is not acceptable."
        
        case .invalidFormat(let string):
            return "Invalid format as Date: '\(string)'"
        }
    }
}
