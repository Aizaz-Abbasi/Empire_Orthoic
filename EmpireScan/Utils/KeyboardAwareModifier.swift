//
//  KeyboardAwareModifier.swift
//  EmpireScan
//
//  Created by MacOK on 12/03/2025.
//
import Foundation
import SwiftUI

var isKeyboardVisible = false
struct KeyboardAwareModifier: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onAppear {
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        withAnimation {
                            keyboardHeight = keyboardFrame.height - 100 // Adjust padding
                            isKeyboardVisible = true
                            print("Show Keyboard")
                        }
                    }
                }

                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    withAnimation {
                        keyboardHeight = 0
                        isKeyboardVisible = false
                        print("Hide Keyboard")
                    }
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
                NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
            }
    }
}

extension View {
    func keyboardAware() -> some View {
        self.modifier(KeyboardAwareModifier())
    }
}
