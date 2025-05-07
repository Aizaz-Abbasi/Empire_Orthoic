//
//  CustomPlaceholderStyle.swift
//  EmpireScan
//
//  Created by MacOK on 12/03/2025.
//
import SwiftUI
struct CustomTextField: View {
    var title: String
    @Binding var text: String
    var placeholder: String
    var isSecure: Bool
    var screenWidth: CGFloat
    var screenHeight: CGFloat
    var isRequired: Bool = false // Default value set to false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 1) { // Adjust the spacing value as needed
                Text(title)
                    .foregroundColor(.black)
                    .fontWeight(.medium)
                    .font(.system(size: screenWidth * 0.04)) // Responsive text size
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.system(size: screenWidth * 0.04,weight: .bold))
                }
            }
            if isSecure {
                SecureField("", text: $text)
                    .modifier(CustomPlaceholderStyle(placeholder: placeholder, color: Colors.lightGray, text: $text))
                    .frame(height: screenHeight * 0.055) // Adjusted height
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1))
            } else {
                TextField("", text: $text)
                    .modifier(CustomPlaceholderStyle(placeholder: placeholder, color: Colors.lightGray, text: $text))
                    .frame(height: screenHeight * 0.055) // Adjusted height
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1))
            }
        }
        .padding(.horizontal, screenWidth * 0.05)
    }
}


struct CustomPlaceholderStyle: ViewModifier {
    var placeholder: String
    var color: Color
    @Binding var text: String
    
    func body(content: Content) -> some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundColor(color) // Placeholder color
                    .padding(.leading, 8)
            }
            content
                .foregroundColor(.black) // Text color
                .padding(8)
        }
    }
}

