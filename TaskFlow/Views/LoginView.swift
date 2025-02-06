//
//  LoginView.swift
//  TaskFlow
//
//  Created by Miguel Mercado on 5/2/25.
//

import Foundation
import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack {
            if viewModel.isAuthenticated {
                Text("✅ You are logged in!")
                    .font(.title)
                    .padding()
                Button("Log out") {
                    Task {
                        await viewModel.logout()
                       
                    }
                }
                    .buttonStyle(.borderedProminent)
                
            } else {
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Login") {
                    Task {
                        let success = await viewModel.login(email: email, password: password)
                        if !success { print("Login failed") }
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding()

                Button("Login with Face ID / Touch ID") {
                    viewModel.loginWithBiometrics()
                }
                .buttonStyle(.bordered)
                .padding()
            }
        }
        .padding()
    }
}
