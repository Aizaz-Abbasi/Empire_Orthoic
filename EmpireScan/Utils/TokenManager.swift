//
//  TokenManager.swift
//  EmpireScan
//
//  Created by MacOK on 14/03/2025.
//
import Foundation
import KeychainAccess
class TokenManager {
    static let shared = TokenManager()
    private let keychain = Keychain(service: "com.yourapp.empirescan")
    
    private let accessTokenKey = "accessToken"
    private let refreshTokenKey = "refreshToken"
    
    var accessToken: String? {
        get {
            return try? keychain.get(accessTokenKey)
        }
        set {
            if let token = newValue {
                try? keychain.set(token, key: accessTokenKey)
            } else {
                try? keychain.remove(accessTokenKey)
            }
        }
    }
    
    var refreshToken: String? {
        get {
            return try? keychain.get(refreshTokenKey)
        }
        set {
            if let token = newValue {
                try? keychain.set(token, key: refreshTokenKey)
            } else {
                try? keychain.remove(refreshTokenKey)
            }
        }
    }
    
    func clearTokens() {
        accessToken = nil
        refreshToken = nil
        try? keychain.remove(accessTokenKey)
    }
}
