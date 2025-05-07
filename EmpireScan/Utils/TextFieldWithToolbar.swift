//
//  TextFieldWithToolbar.swift
//  EmpireScan
//
//  Created by MacOK on 28/04/2025.
//

import Foundation
import SwiftUI

// UIViewRepresentable wrapper for UITextField with a Done toolbar
struct TextFieldWithToolbar: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var keyboardType: UIKeyboardType
    var onDone: (() -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.borderStyle = .roundedRect
        textField.inputAccessoryView = makeToolbar(context: context)
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    private func makeToolbar(context: Context) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .done,
            target: context.coordinator,
            action: #selector(Coordinator.doneTapped)
        )
        
        toolbar.setItems([doneButton], animated: false)
        return toolbar
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject {
        var parent: TextFieldWithToolbar

        init(_ parent: TextFieldWithToolbar) {
            self.parent = parent
        }

        @objc func doneTapped() {
            self.parent.onDone?()  // Call the onDone callback when done is tapped
        }
    }
}
