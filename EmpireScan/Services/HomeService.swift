//
//  HomeService.swift
//  EmpireScan
//
//  Created by MacOK on 17/03/2025.
//

import Foundation
import Alamofire
import SwiftUI
struct HomeResponse: Codable {
    let token: String
    let userId: Int
}

class HomeService {
    
    static let shared = HomeService()
    var user: UserProfile?

    private init() {}
    
    func getStats(completion: @escaping (Result<APIResponse<UserStats>, Error>) -> Void) {
        
        NetworkService.shared.get(endpoint:HomeEndpoints.homeStats) { (result: Result<APIResponse<UserStats>, Error>) in
            switch result {
            case .success(let apiResponse):
                print("Login Response:", apiResponse)
                completion(.success(apiResponse))
            case .failure(let error):
                print("Error creating user:",error, error.localizedDescription)
                completion(.failure(error))
            }
        }
    }
    
    func getProfile(completion: @escaping (Result<APIResponse<UserProfile>, Error>) -> Void) {
        
        NetworkService.shared.get(endpoint:HomeEndpoints.getUserDetails) { (result: Result<APIResponse<UserProfile>, Error>) in
            switch result {
            case .success(let apiResponse):
                print("Login Response:", apiResponse)
                self.user = apiResponse.data
                completion(.success(apiResponse))
            case .failure(let error):
                print("Error creating user:",error.localizedDescription)
                if let afError = error as? AFError,
                   case .responseValidationFailed(let reason) = afError,
                   case .unacceptableStatusCode(let statusCode) = reason,
                   statusCode == 401 {
                    DispatchQueue.main.async {
                        let loginVC = UIHostingController(rootView: LoginScreen())
                        let navController = UINavigationController(rootViewController: loginVC)
                        UIApplication.shared.windows.first?.rootViewController = navController
                        UIApplication.shared.windows.first?.makeKeyAndVisible()
                    }
                    TokenManager.shared.clearTokens()
                }
                completion(.failure(error))
            }
        }
    }
}
