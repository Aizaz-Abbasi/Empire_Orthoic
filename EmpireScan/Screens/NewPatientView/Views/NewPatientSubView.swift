//
//  NewPatientSubView.swift
//  EmpireScan
//
//  Created by MacOK on 25/03/2025.
//
import Foundation
import SwiftUI

struct CustomPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    var width: CGFloat? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            //            if !title.isEmpty {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
            //            }
            if #available(iOS 14.0, *) {
                if #available(iOS 15.0, *) {
                    Picker("", selection: $selection) {
                        ForEach(options, id: \.self) { option in
                            HStack {
                                Text(option)
                                    .foregroundColor(.red) // Change text color
                                Spacer() // Creates space between text and icon
                            }
                            .tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .tint(.black)
                    .frame(height: UIScreen.main.bounds.height * 0.055) // Fixed height
                    .frame(maxWidth: width ?? .infinity)
                    .padding(.horizontal)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                } else {
                    // Fallback on earlier versions
                }
            } else {
                // Fallback on earlier versions
            }
        }
    }
}

struct GenderButton: View {
    let title: String
    @Binding var selectedGender: String
    
    var body: some View {
        Button(action: {
            selectedGender = title
        }) {
            HStack {
                Image(systemName: selectedGender == title ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(selectedGender == title ? .red : .gray)
                Text(title)
                    .foregroundColor(.black)
            }
            .padding()
        }
    }
}

struct CustomTextFieldSmall: View {
    let title: String
    @Binding var text: String
    var width: CGFloat? = nil
    var isRequired: Bool = false // Indicates if the field is required

    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 1) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                if isRequired {
                    Text("*")
                        .foregroundColor(.red)
                        .font(.system(size: 16, weight: .bold))
                }
            }
            TextField("", text: $text)
                .keyboardType(.numberPad)
                .padding()
                .frame(height: UIScreen.main.bounds.height * 0.055) // Fixed height
                .frame(maxWidth: width ?? screenWidth * 0.9) // Uses full width if not specified
                .background(Color.white)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
        }
    }
}


struct SectionHeader: View {
    let title: String
    
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .padding(.vertical, 10)
                .padding(.horizontal, screenWidth * 0.05)
            Spacer() // Push text to the left
        }
    }
}

// MARK: - Hide Keyboard Extension
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
