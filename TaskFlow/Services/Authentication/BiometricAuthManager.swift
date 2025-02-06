//
//  BiometricAuthManager.swift
//  TaskFlow
//
//  Created by Miguel Mercado on 5/2/25.
//

import Foundation
import LocalAuthentication

final class BiometricAuthManager {
    static let shared = BiometricAuthManager()
    private init() {}

    func authenticateUser(reason: String = "Authenticate to continue", completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?

        // Check if Face ID / Touch ID is available
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                DispatchQueue.main.async {
                    completion(success, authError)
                }
            }
        } else {
            DispatchQueue.main.async {
                completion(false, error)
            }
        }
    }
}

