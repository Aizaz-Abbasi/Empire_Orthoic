//
//  Encodable+Dictionary.swift
//  EmpireScan
//
//  Created by MacOK on 10/03/2025.
//

import Foundation

//extension Encodable {
//    func asDictionary() -> [String: Any]? {
//        guard let data = try? JSONEncoder().encode(self) else { return nil }
//        return (try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)) as? [String: Any]
//    }
//}

extension Encodable {
    func asDictionary() -> [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        guard let dictionary = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else { return nil }
        
        // Convert missing keys to NSNull (for `nil` values)
        return dictionary.mapValues { $0 is NSNull ? nil : $0 }
    }
}

