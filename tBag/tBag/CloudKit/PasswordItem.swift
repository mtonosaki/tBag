//
//  PasswordFilter.swift
//  tBag
//
//  Created by Manabu Tonosaki on 2026-01-26.
//

import Tono

extension Item {
    public enum PasswordFilter: String {
        case home = "#home"
        case office = "#office"
        case deleted = "#deleted"
    }
    
    public enum PasswordAttributeKeys: String {
        case accountId
        case password
        case email
    }

    func isHome(rsa: Rsa) -> Bool {
        self.containsTag(PasswordFilter.home.rawValue, myRsa: rsa)
    }
    func isOffice(rsa: Rsa) -> Bool {
        self.containsTag(PasswordFilter.office.rawValue, myRsa: rsa)
    }
    func isDeleted(rsa: Rsa) -> Bool {
        self.containsTag(PasswordFilter.deleted.rawValue, myRsa: rsa)
    }
}

struct ItemBuilder {
    static func createNewPasswordItem(ownerAccountId: String, myRsa: Rsa) -> Item {
        let newItem = Item(ownerId: ownerAccountId, type: .password)
        newItem.addTag(Item.PasswordFilter.home.rawValue, myRsa: myRsa, owner: "HOGE-USER-ID")
        newItem.addTag(Item.PasswordFilter.office.rawValue, myRsa: myRsa, owner: "HOGE-USER-ID")
        return newItem
    }
}
