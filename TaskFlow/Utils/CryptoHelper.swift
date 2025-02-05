//
//  CryptoHelper.swift
//  TaskFlow
//
//  Created by Miguel Mercado on 5/2/25.
//

import CryptoKit
import Foundation

struct CryptoHelper {
    private static let keyTag = "com.TaskFlow.app.encryptionKey"
    
    private static func getSymmetricKey() async -> SymmetricKey? {
        do {
            if let keyData = try await KeychainManager.shared.getData(forKey: keyTag) {
                return SymmetricKey(data: keyData)
            }
            
            let newKey = SymmetricKey(size: .bits256)
            let keyData = newKey.withUnsafeBytes { Data($0) }
            
            try KeychainManager.shared.save(keyData, forKey: keyTag)
            return newKey
        } catch {
            print("Failed to retrieve or save symmetric key: \(error)")
            return nil
        }
    }
    
    /// Encrypts data using AES-GCM
    static func encrypt(_ data: Data) async -> Data? {
        guard let key = await getSymmetricKey() else { return nil }
        
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined
        } catch {
            print("Encryption Error: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Decrypts AES-GCM encrypted data
    static func decrypt(_ encryptedData: Data) async -> Data? {
        guard let key = await getSymmetricKey() else { return nil }
        
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            print("Decryption Error: \(error.localizedDescription)")
            return nil
        }
    }
}



