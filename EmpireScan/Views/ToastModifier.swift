//
//  ToastModifier.swift
//  EmpireScan
//
//  Created by MacOK on 21/04/2025.
//

import Foundation
import UIKit
import SwiftUICore

struct ToastModifier: ViewModifier {
    @Binding var isShowing: Bool
    let message: String

    func body(content: Content) -> some View {
        ZStack {
            content

            if isShowing {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.subheadline)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .padding(.bottom, 50)
                        .transition(.opacity)
                        .animation(.easeInOut, value: isShowing)
                }
            }
        }
    }
}

extension View {
    func toast(isShowing: Binding<Bool>, message: String) -> some View {
        self.modifier(ToastModifier(isShowing: isShowing, message: message))
    }
}
