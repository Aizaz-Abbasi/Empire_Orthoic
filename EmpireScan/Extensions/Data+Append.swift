//
//  Data+Append.swift
//  EmpireScan
//
//  Created by MacOK on 09/04/2025.
//

import Foundation
import Foundation

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
