//
//  CheckBoxView.swift
//  OrderForm
//
//  Created by MacOK on 25/04/2025.
//
import Foundation
import SwiftUI
struct CheckboxView: View {
    @Binding var isChecked: Bool
    var label: String
    var size: CGFloat = 24

    var body: some View {
        Button(action: {
           // withAnimation(.easeInOut(duration: 0.2)) {
                isChecked.toggle()
          //  }
        }) {
            HStack(spacing: 8) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .resizable()
                    .frame(width: size, height: size)
                    .foregroundColor(isChecked ? Colors.primary : Color(hex: "#E9E9E9"))
                    .transition(.scale)
                
                if !label.isEmpty {
                    Text(label)
                        .foregroundColor(.primary)
                        .font(.system(size: 16, weight: .regular))
                }
            }
            //.contentShape(Rectangle()) // Keep only if label is clickable too
        }
        .buttonStyle(.plain)
        .padding(.vertical, 4) // Optional
    }
}
