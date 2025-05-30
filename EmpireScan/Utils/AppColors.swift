//
//  AppColors.swift
//  EmpireScan
//
//  Created by MacOK on 12/03/2025.
//
import Foundation
import SwiftUI

struct Colors {
    static let white = Color(hex: "#FFFFFF")
    static let offWhite = Color(hex: "#F9F9F9")
    
    static let primaryText = Color(hex: "#02030E")
    static let primary = Color(hex: "#CA3438")

    static let darkGray = Color(hex: "#636670")
    static let bodyText = Color(hex: "#687078")
    static let border = Color(hex: "#E9E9E9")
    static let lightGray = Color(hex: "#9AA2AB")
    static let grayBG = Color(hex: "#F5F5F5")
}

extension Color {
    var uiColor: UIColor {
        UIColor(self)
    }
}
