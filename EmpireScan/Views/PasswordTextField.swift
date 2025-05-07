//
//  PasswordTextField.swift
//  EmpireScan
//
//  Created by MacOK on 12/03/2025.
//

import Foundation
import SwiftUI

struct PasswordTextField: View {
    @Binding var password: String
    @State private var isPasswordVisible: Bool = false
    var screenWidth: CGFloat
    var screenHeight: CGFloat
    var placeholder: String


    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Password")
                .foregroundColor(.black)
                .fontWeight(.medium)
                .font(.system(size: screenWidth * 0.04)) // Responsive text size
            
            HStack {
                if isPasswordVisible {
                    TextField("Enter password", text: $password)
                        .modifier(CustomPlaceholderStyle(placeholder: placeholder, color:Colors.lightGray, text: $password ))

                } else {
                    SecureField("••••••••", text: $password)
                        .modifier(CustomPlaceholderStyle(placeholder: placeholder, color:Colors.lightGray, text: $password))

                }
                
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                        .foregroundColor(.gray)
                }
            }
            .frame(height: screenHeight * 0.02)
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1))
        }
        .padding(.horizontal, screenWidth * 0.05)
    }
}
