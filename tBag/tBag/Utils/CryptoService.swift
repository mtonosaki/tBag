//
//  CryptoService.swift
//  tBag
//
//  Created by Gemini CLI on 2026-04-26.
//

import Foundation
import Tono
import SwiftUI

protocol CryptoServiceProtocol {
    func seal(plainText: String, recipientPublicKey: Base64String, salt: String) throws -> SealedEnvelopeBase64String
    func open(sealedString: SealedEnvelopeBase64String, myRsa: Rsa) throws -> String
}

class CryptoService: CryptoServiceProtocol {
    static let shared = CryptoService()
    
    func seal(plainText: String, recipientPublicKey: Base64String, salt: String) throws -> SealedEnvelopeBase64String {
        return try DigitalEnvelope.seal(plainText: plainText, recipientPublicKeyBase64: recipientPublicKey, salt: salt)
    }
    
    func open(sealedString: SealedEnvelopeBase64String, myRsa: Rsa) throws -> String {
        return try DigitalEnvelope.open(sealedString: sealedString, myRsa: myRsa)
    }
}

private struct CryptoServiceKey: EnvironmentKey {
    static let defaultValue: CryptoServiceProtocol = CryptoService.shared
}

extension EnvironmentValues {
    var cryptoService: CryptoServiceProtocol {
        get { self[CryptoServiceKey.self] }
        set { self[CryptoServiceKey.self] = newValue }
    }
}
