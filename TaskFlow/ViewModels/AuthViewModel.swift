//
//  AuthViewModel.swift
//  TaskFlow
//
//  Created by Miguel Mercado on 5/2/25.
//

import Foundation
@MainActor
final class AuthViewModel: ObservableObject {
    private let secureStorage: SecureStorage
    @Published var isAuthenticated = false
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
            try KeychainManager.shared.save(encryptedCredentials, forKey: "userCredentials", syncToiCloud: false)
            await MainActor.run { self.isAuthenticated = true }
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
            await MainActor.run { self.isAuthenticated = true }
            return (String(components[0]), String(components[1]))
        } catch {
            print("error: \(error.localizedDescription)")
            return nil
        }
    }
    
    func loginWithBiometrics() {
        BiometricAuthManager.shared.authenticateUser { [weak self] success, error in
            guard success, error == nil else {
                print("Biometric Authentication Failed: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            Task {
                await self?.retrieveCredentials()
            }
        }
    }
    
    func logout() async {
        do {
            try secureStorage.delete(forKey: "userCredentials", removeFromiCloud: true)
            await MainActor.run { self.isAuthenticated = false }
        } catch {
            print("Keychain Delete Error: \(error)")
        }
    }

}
