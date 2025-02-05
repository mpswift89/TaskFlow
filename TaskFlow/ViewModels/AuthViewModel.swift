//
//  AuthViewModel.swift
//  TaskFlow
//
//  Created by Miguel Mercado on 5/2/25.
//

import Foundation

final class AuthViewModel: ObservableObject {
    private let secureStorage: SecureStorage
    
    init(secureStorage: SecureStorage = KeychainManager.shared) {
        self.secureStorage = secureStorage
    }
    
    func login(email: String, password: String) async -> Bool {
        guard let credentials = "\(email):\(password)".data(using: .utf8) else {
            print("Error: Failed to encode credentials")
            return false
        }
        
        guard let encryptedCredentials = await CryptoHelper.encrypt(credentials) else {
            return false
        }
        
        do {
            try KeychainManager.shared.save(encryptedCredentials, forKey: "userCredentials", syncToiCloud: true)
            return true
        } catch {
            print("Keychain Error: \(error.localizedDescription)")
            return false
        }
    }
    
    func retrieveCredentials() async -> (email: String, password: String)? {
        do {
            guard let encryptedData = try await KeychainManager.shared.getData(forKey: "userCredentials"),
                  let decryptedData = await CryptoHelper.decrypt(encryptedData),
                  let credentialsString = String(data: decryptedData, encoding: .utf8) else {
                return nil
            }

            let components = credentialsString.split(separator: ":")
            guard components.count == 2 else { return nil }

            return (String(components[0]), String(components[1]))
        } catch {
            return nil
        }
    }

}
