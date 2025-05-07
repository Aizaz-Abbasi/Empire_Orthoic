

import SwiftUI

struct ScrollableTabView: View {
    let options: [String]
    let onTabSelected: (String) -> Void  // ✅ Callback for notifying parent
    
    @State private var selectedOption: String = "All"  // ✅ Local state for selection

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        selectedOption = option  // ✅ Update local selection
                        onTabSelected(option)   // ✅ Notify ScansVC
                    }) {
                        Text(option)
                            .font(.system(size: 16, weight: .medium))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 15)
                            .background(selectedOption == option ? Color.black : Color.white)
                            .foregroundColor(selectedOption == option ? Color.white : Color.black)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                    }
                }
            }
            .padding()
        }
    }
}


//import SwiftUI
//
//struct ScrollableTabView: View {
//    @Binding var selectedOption: String  // Use Binding to update parent
//    let options: [String]
//
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 10) {
//                ForEach(options, id: \.self) { option in
//                    Button(action: {
//                        selectedOption = option  // ✅ Updates `ScansVC`
//                    }) {
//                        Text(option)
//                            .font(.system(size: 16, weight: .medium))
//                            .padding(.vertical, 8)
//                            .padding(.horizontal, 15)
//                            .background(selectedOption == option ? Color.black : Color.white)
//                            .foregroundColor(selectedOption == option ? Color.white : Color.black)
//                            .clipShape(Capsule())
//                            .overlay(
//                                Capsule()
//                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
//                            )
//                    }
//                }
//            }
//            .padding()
//        }
//    }
//}





////
////  ScrollableTabView.swift
////  EmpireScan
////
////  Created by MacOK on 17/03/2025.
////
//
//import Foundation
//import SwiftUI
//
//struct ScrollableTabView: View {
//    @State private var selectedOption = "Sent"
//    
//    let options = ["All", "In-Progress", "Completed", "Pending", "Patients not scan yet"]
//    
//    var body: some View {
//        ScrollView(.horizontal, showsIndicators: false) {
//            HStack(spacing: 10) {
//                ForEach(options, id: \.self) { option in
//                    Button(action: {
//                        selectedOption = option
//                    }) {
//                        Text(option)
//                            .font(.system(size: 16, weight: .medium))
//                            .padding(.vertical, 8)
//                            .padding(.horizontal, 15)
//                            .background(selectedOption == option ? Color.black : Color.white)
//                            .foregroundColor(selectedOption == option ? Color.white : Color.black)
//                            .clipShape(Capsule())
//                            .overlay(
//                                Capsule()
//                                    .stroke(Color(hex: "#E9E9E9"), lineWidth: 1)
//                            )
//                    }
//                    .background(Color.clear)
//                    .foregroundColor(Color.clear)
//                }
//            }
//            .padding()
//            .background(Color.white)
//            .foregroundColor(Color.white)
//
//        }
//    }
//}
