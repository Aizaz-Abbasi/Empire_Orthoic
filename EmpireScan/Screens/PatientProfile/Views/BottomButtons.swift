//
//  BottomButtons.swift
//  EmpireScan
//
//  Created by MacOK on 11/04/2025.
//

import Foundation
import SwiftUI
@ViewBuilder
public func bottomButtons() -> some View {
    let screenWidth = UIScreen.main.bounds.width
    VStack(spacing: 0) {
        Button(action: {
            print("Edit Profile Tapped")
        }) {
            HStack {
                Image(systemName: "square.and.pencil")
                Text("Edit Profile")
            }
            .font(.system(size: 16, weight: .bold))
            .frame(width: screenWidth * 0.9, height: 50)
            .background(Colors.white)
            .foregroundColor(Colors.primary)
            .overlay(
                Capsule().stroke(Colors.primary, lineWidth: 2)
            )
            .clipShape(Capsule())
        }
        .padding(.top, 0)
        
        Button(action: {
            print("Saveee Profile Tapped")
        }) {
            HStack {
                Image(systemName: "checkmark.circle")
                Text("Submit order")
            }
            .font(.system(size: 16, weight: .bold))
            .frame(width: screenWidth * 0.9, height: 50)
            .background(Colors.primary)
            .foregroundColor(Colors.white)
            .clipShape(Capsule())
        }
        .padding(.top, 10)

        Color.clear.frame(height: 10)
    }
    .padding(.bottom, 20)
    .frame(maxWidth: .infinity)
}
