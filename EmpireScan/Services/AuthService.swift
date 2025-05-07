//
//  AuthService.swift
//  EmpireScan
//
//  Created by MacOK on 11/03/2025.
//
import Foundation

struct LoginResponse: Codable {
    let token: String
    let userId: Int
}

class AuthService {
    
    static let shared = AuthService()
    private init() {}
    
    func login(email: String, password: String, completion: @escaping (Result<APIResponse<LoginData>, Error>) -> Void) {
        
        let newUser = LoginUser(email:email, password: password) // Ensure `User` conforms to `Encodable`
        NetworkService.shared.post(endpoint:APIEndpoints.login, body: newUser) { (result: Result<APIResponse<LoginData>, Error>) in
            switch result {
            case .success(let apiResponse):
                TokenManager.shared.accessToken = apiResponse.data?.accessToken
                TokenManager.shared.refreshToken = apiResponse.data?.refreshToken
                //print("Login Response:", apiResponse)
                completion(.success(apiResponse))
            case .failure(let error):
                print("Error creating user:",error, error.localizedDescription)
                completion(.failure(error))
            }
        }
    }
}
