//
//  ConfigManager.swift
//  EmpireScan
//
//  Created by MacOK on 29/05/2025.
//
import Foundation
import Alamofire

struct RemoteConfig: Decodable {
    let base_url: String
}

class ConfigManager {
    static let shared = ConfigManager()
    
    private init() {}
    
    var baseURL: String = "https://fallback.api.com" // fallback default
    func loadConfig(completion: @escaping (Bool) -> Void) {
        let configURL = "https://config.empireoplabs.com/env.json"
        
        AF.request(configURL)
            .validate()
            .responseDecodable(of: RemoteConfig.self) { response in
                switch response.result {
                case .success(let config):
                    self.baseURL = config.base_url
                    print("✅ Loaded baseURL from config: \(self.baseURL)")
                    completion(true)
                case .failure(let error):
                    print("❌ Failed to load config: \(error.localizedDescription)")
                    completion(false)
                }
            }
    }
}
