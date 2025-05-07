//
//  Functions.swift
//  EmpireScan
//
//  Created by MacOK on 07/04/2025.
//
import Foundation

public func formattedDate(_ date: Any?) -> String {
    // If the input is nil, return "N/A"
    guard let inputDate = date else { return "N/A" }

    let inputFormatter = DateFormatter()
    inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS" // Updated format without 'Z'
    inputFormatter.locale = Locale(identifier: "en_US_POSIX")
    inputFormatter.timeZone = TimeZone(abbreviation: "UTC") // Ensure UTC interpretation
    
    var dateToFormat: Date?
    
    // Check if the input is a String or Date
    if let dateString = inputDate as? String, !dateString.isEmpty {
        // Convert the string to Date
        dateToFormat = inputFormatter.date(from: dateString)
    } else if let date = inputDate as? Date {
        // Use the Date directly
        dateToFormat = date
    }
    
    // If the date is successfully parsed or passed, format it
    if let date = dateToFormat {
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MM/dd/yyyy - hh:mm a" // Desired format
        outputFormatter.amSymbol = "am"
        outputFormatter.pmSymbol = "pm"
        outputFormatter.timeZone = TimeZone.current // Convert to local time
        return outputFormatter.string(from: date)
    } else {
        return "Invalid date"
    }
}

public func convertToDateOnly(from dateString: String) -> String {
    // Step 1: Parse the string into a Date object
    let inputFormatter = DateFormatter()
    inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // Input format with 'Z' for UTC
    inputFormatter.locale = Locale(identifier: "en_US_POSIX")
    inputFormatter.timeZone = TimeZone(abbreviation: "UTC") // Ensure UTC interpretation
    
    guard let date = inputFormatter.date(from: dateString) else {
        return "Invalid date format"
    }
    
    // Step 2: Format the Date object into the desired format (only date part)
    let outputFormatter = DateFormatter()
    outputFormatter.dateFormat = "yyyy-MM-dd" // Desired format (e.g., "2025-04-10")
    outputFormatter.timeZone = TimeZone.current // Convert to local time if needed
    
    return outputFormatter.string(from: date)
}

public func convertToDateOnlyWithoutZ(from dateString: String) -> String {
    let inputFormatter = DateFormatter()
    inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS" // <- Updated
    inputFormatter.locale = Locale(identifier: "en_US_POSIX")
    inputFormatter.timeZone = TimeZone(abbreviation: "UTC")
    
    guard let date = inputFormatter.date(from: dateString) else {
        return "Invalid date format"
    }

    let outputFormatter = DateFormatter()
    outputFormatter.dateFormat = "yyyy-MM-dd"
    outputFormatter.timeZone = TimeZone.current
    
    return outputFormatter.string(from: date)
}

