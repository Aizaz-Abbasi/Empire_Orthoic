//
//  SignupScreen.swift
//  EmpireScan
//
//  Created by MacOK on 12/03/2025.
//

import Foundation
import SwiftUI

struct SignupScreen: View {
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if #available(iOS 14.0, *) {
                    Image("backgroundImg")
                        .resizable()
                        .scaledToFill()
                        .ignoresSafeArea()
                }
                
                VStack(spacing: geometry.size.height * 0.02) {
                    Spacer(minLength: geometry.size.height * 0.09)

                    // Title
                    Text("Welcome back")
                        .font(.system(size: geometry.size.width * 0.08, weight: .bold)) // Dynamic font
                        .foregroundColor(.red)

                    Text("We're so excited to see you again!")
                        .font(.system(size: geometry.size.width * 0.04))
                        .foregroundColor(.black.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, geometry.size.width * 0.05)
                    
                    
                    CustomTextField(
                        title: "Email 1",
                        text: $email,
                        placeholder: "Enter your email",
                        isSecure: false,
                        screenWidth: geometry.size.width,
                        screenHeight:  geometry.size.height
                    )
            
                    // Password Field
                    PasswordTextField(
                        password: $password,
                        screenWidth: geometry.size.width,
                        screenHeight: geometry.size.height,
                        placeholder: "Enter Password"
                    )

                    // Error Message
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                            .padding(.top, 5)
                    }

                    // Login Button
                    Button(action: {
                        performLogin()
                    }) {
                        if isLoading {
                            if #available(iOS 14.0, *) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                        } else {
                            Text("Login")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(30)
                        }
                    }
                    .padding(.horizontal, geometry.size.width * 0.05)
                    .padding(.top, 10)
                    .disabled(isLoading)

                    Spacer()
                }
                .frame(maxWidth: 400) // Limits width for better layout on iPads
            }
            .navigationBarBackButtonHidden(true)
        }
    }


    // MARK: - Perform Login
    func performLogin() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Email and password cannot be empty."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        AuthService.shared.login(email: email, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    print("Login Success: Token - \(String(describing: response.data?.accessToken))")
                    switchToMainTabBar()
                    
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Switch to Main Tab Bar
    func switchToMainTabBar() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let tabBarVC = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController {
            window.rootViewController = tabBarVC
            window.makeKeyAndVisible()
        }
    }
}

#Preview {
    if #available(iOS 14.0, *) {
        LoginScreen()
    } else {
        // Fallback on earlier versions
    }
}

