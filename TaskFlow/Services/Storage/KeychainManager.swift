//
//  KeychainManager.swift
//  TaskFlow
//
//  Created by Miguel Mercado on 4/2/25.
//

import Security
import Foundation
import LocalAuthentication

enum KeychainError: Error {
    case itemNotFound
    case authenticationFailed
    case unexpectedStatus(OSStatus)
}

protocol SecureStorage {
    func save(_ data: Data, forKey key: String, syncToiCloud: Bool) throws
    func getData(forKey key: String, syncFromiCloud: Bool) async throws -> Data?
    func delete(forKey key: String, removeFromiCloud: Bool) throws
}


final class KeychainManager: SecureStorage {
    
    static let shared = KeychainManager()
    
    private init() {}
    
//    func save(_ data: Data, forKey key: String, syncToiCloud: Bool = false) throws {
//        guard let accessControl = SecAccessControlCreateWithFlags(
//            nil,
//            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
//            [.userPresence, .devicePasscode],
//            nil
//        ) else {
//            throw KeychainError.authenticationFailed
//        }
//         let query: [String: Any] = [
//            kSecClass as String: kSecClassGenericPassword,
//            kSecAttrAccount as String: key,
//            kSecValueData as String: data,
//            kSecAttrAccessControl as String: accessControl,
//            kSecAttrSynchronizable as String: (syncToiCloud ? kCFBooleanTrue : kCFBooleanFalse) as Any
//        ]
//        
//        SecItemDelete(query as CFDictionary)
//        
//        let status = SecItemAdd(query as CFDictionary, nil)
//        guard status == errSecSuccess else {
//            throw KeychainError.unexpectedStatus(status)
//        }
//    }
    
    func save(_ data: Data, forKey key: String, syncToiCloud: Bool = false) throws {
//        guard let accessControl = SecAccessControlCreateWithFlags(
//            nil,
//            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
//            [.userPresence, .devicePasscode],
//            nil
//        ) else {
//            throw KeychainError.authenticationFailed
//        }
        
        guard let accessControl = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly, // Changed accessibility
            .userPresence, // Removed .devicePasscode (this is often unnecessary)
            nil
        ) else {
            throw KeychainError.authenticationFailed
        }


        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessControl as String: accessControl,
            kSecAttrSynchronizable as String: (syncToiCloud ? kCFBooleanTrue : kCFBooleanFalse) as Any
        ]

        let updateQuery: [String: Any] = [
            kSecValueData as String: data
        ]

        // Check if the item already exists
        let status = SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)

        if status == errSecItemNotFound {
            // If not found, add it instead
            var addQuery = query
            addQuery[kSecValueData as String] = data
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(addStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }

    
    func getData(forKey key: String, syncFromiCloud: Bool = false) async throws -> Data? {
        let context = LAContext()
        context.localizedReason = "Authenticate to access your secure data"
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) else {
            throw KeychainError.authenticationFailed
        }
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: context.localizedReason) { success, error in
                guard success, error == nil else {
                     continuation.resume(throwing: KeychainError.authenticationFailed)
                    return
                }
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrAccount as String: key,
                    kSecReturnData as String: true,
                    kSecMatchLimit as String: kSecMatchLimitOne,
                    kSecUseAuthenticationContext as String: context,
                    kSecAttrSynchronizable as String: (syncFromiCloud ? kCFBooleanTrue : kCFBooleanFalse) as Any
                ]
                
                var result: AnyObject?
                let status = SecItemCopyMatching(query as CFDictionary, &result)
                if status == errSecSuccess, let data = result as? Data {
                    continuation.resume(returning: data)
                } else if status == errSecItemNotFound {
                    continuation.resume(throwing: KeychainError.itemNotFound)
                } else {
                    continuation.resume(throwing: KeychainError.unexpectedStatus(status))
                }
            }
     
        }
     
    }
    
    func delete(forKey key: String, removeFromiCloud: Bool = false) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrSynchronizable as String: (removeFromiCloud ? kCFBooleanTrue : kCFBooleanFalse) as Any
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
