//
//  PasswordItem.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2026-01-26.
//

import Tono
import Foundation

extension Item {
    func isHome(rsa: Rsa) -> Bool {
        containsTag(TagGroups.home.rawValue, rsa: rsa)
    }
    func isOffice(rsa: Rsa) -> Bool {
        containsTag(TagGroups.office.rawValue, rsa: rsa)
    }
    func isDeleted(rsa: Rsa) -> Bool {
        containsTag(TagGroups.deleted.rawValue, rsa: rsa)
    }
    
    private func containsTag(_ tag: String, rsa: Rsa) -> Bool {
        guard let attributeData = self.attributes[AttributeKeys.tags.rawValue] else { return false }
        guard attributeData.isEmpty == false else { return false }
        
        do {
            let tagsString = try CryptoService.shared.open(sealedString: attributeData[0].encryptedValue, myRsa: rsa)
            let tags = tagsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            return tags.contains(tag)
        } catch {
            return false
        }
    }
}
