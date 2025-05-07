//
//  FilterModalView.swift
//  EmpireScan
//
//  Created by MacOK on 20/03/2025.
//

import Foundation
import SwiftUI

struct FilterValues {
    var sortOption: String?
    var startDate: Date?
    var endDate: Date?
    var displayUploadedScans: Bool
}

struct FilterModalView: View {
    @Binding var isPresented: Bool
    var FromScreen: String
    var onApply: (FilterValues) -> Void
    @State private var selectedSortOption: String?
    @State private var searchText: String = ""
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var displayUploadedScans: Bool = false
    
    let sortOptions = ["Alphabetical", "Modified recently first", "Modified recently last", "Latest scan"]
    
    var body: some View {
        VStack(spacing: 16) {
            // Drag Handle
            RoundedRectangle(cornerRadius: 3)
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.5))
                .padding(.top, 10)
            
            // Sort Options
            VStack(alignment: .leading, spacing: 10) {
                Text("Sort by")
                    .font(.headline)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ForEach(sortOptions, id: \.self) { option in
                    Button(action: {
                        selectedSortOption = option
                    }) {
                        HStack {
                            Image(systemName: selectedSortOption == option ? "checkmark.square.fill" : "square")
                                .foregroundColor(Colors.darkGray)
                            Text(option)
                                .foregroundColor(.primary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 5)
                    }
                }
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width * 0.9, alignment: .leading)
            
            
            
            // Date Range
            VStack(alignment: .leading, spacing: 10) {
                Text("Select a date range (start to end)")
                    .font(.headline)
                    .bold()
                
                HStack {
                    if #available(iOS 14.0, *) {
                        DatePicker("", selection: Binding(
                            get: { startDate ?? Date() },
                            set: { startDate = $0 }
                        ), displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(CompactDatePickerStyle())
                        
                        DatePicker("", selection: Binding(
                            get: { endDate ?? Date() },
                            set: { endDate = $0 }
                        ), displayedComponents: .date)
                        .labelsHidden()
                        .datePickerStyle(CompactDatePickerStyle())
                    } else {
                        // Fallback on earlier versions
                    }
                }
            }
            .padding()
            .frame(width: UIScreen.main.bounds.width * 0.9, alignment: .leading)
            
            // Toggle Switch
            VStack(alignment: .leading, spacing: 5) {
                if #available(iOS 16.0, *) {
                    Toggle(isOn: $displayUploadedScans) {
                        Text("Display uploaded scans")
                            .font(.headline)
                            .bold()
                    }
                    .tint(Colors.primary)
                } else {
                    Toggle(isOn: $displayUploadedScans) {
                        Text("Display uploaded scans")
                            .font(.headline)
                            .bold()
                    }
                    .accentColor(Colors.primary)
                }
                
                Text("If disabled, previously uploaded scans will no longer appear in the patient's file.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal)
            .frame(width: UIScreen.main.bounds.width * 0.9, alignment: .leading)
            // Apply Filter Button
            Spacer()
            Button(action: {
                let filters = FilterValues(
                    sortOption: selectedSortOption,
                    startDate: startDate,
                    endDate: endDate,
                    displayUploadedScans: displayUploadedScans
                )
                onApply(filters)
                isPresented = false
            }) {
                Text("Apply filter")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(UIScreen.main.bounds.height*0.08)
            }
            .padding()
            
            
        }
        .padding(.bottom)
        .background(Color(UIColor.systemGroupedBackground))
        .cornerRadius(16)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

// Helper extension to bind optional Date values
extension Binding where Value == Date? {
    init(_ source: Binding<Date?>, replacingNilWith defaultValue: Date) {
        self.init(get: { source.wrappedValue ?? defaultValue }, set: { source.wrappedValue = $0 })
    }
}

// Main View with Modal Presentation
struct ContentView: View {
    @State private var isModalPresented = false
    
    var body: some View {
        ZStack {
            VStack {
                Button("Show Filter Modal") {
                    isModalPresented = true
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .blur(radius: isModalPresented ? 5 : 0)
            
            if isModalPresented {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture { isModalPresented = false }
                
                FilterModalView(
                    isPresented: $isModalPresented,
                    FromScreen: "MainView", // Example screen identifier
                    onApply: { filterValues in
                        // Handle filter application here
                        print("Applied filters: \(filterValues)")
                        isModalPresented = false
                    }
                )
                .transition(.move(edge: .bottom))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
