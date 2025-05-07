//
//  NetworkService.swift
//  EmpireScan
//  Created by MacOK on 10/03/2025.
//
import Foundation
import Alamofire

class NetworkService {
    static let shared = NetworkService()
    private init() {}
    //private let baseURL = "http://66.109.28.157"
    private let baseURL = "http://empireapiv2.sjcomputers.com"
    private func request<T: Decodable, B: Encodable>(
        endpoint: String,
        method: HTTPMethod,
        body: B?,
        headers: HTTPHeaders = [:],
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let url = "\(baseURL)/\(endpoint)"
        print("url to pass",url, body?.asDictionary())
        var finalHeaders = headers
        finalHeaders.add(name: "Content-Type", value: "application/json")
        
        if let accessToken = TokenManager.shared.accessToken {
            finalHeaders.add(name: "Authorization", value: "Bearer \(accessToken)")
            print("Bearer \(accessToken)")
        }
        
        //       Encode body properly to include nil as null
        var requestBody: Data? = nil
        if let body = body {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // Optional: for readable logs
            do {
                requestBody = try encoder.encode(body)
                if let jsonString = String(data: requestBody!, encoding: .utf8) {
                    print("Request Body JSON:", jsonString)
                }
            } catch {
                print("Error encoding body:", error.localizedDescription)
                completion(.failure(error))
                return
            }
        }
        
        var urlRequest = URLRequest(url: URL(string: url)!)
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = finalHeaders.dictionary
        urlRequest.httpBody = requestBody
        
        AF.request(urlRequest)
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let data):
                    completion(.success(data))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        //
        //print("body?.asDictionary()",body?.asDictionary())
//        AF.request(url, method: method, parameters: body?.asDictionary(), encoding: JSONEncoding.default, headers: finalHeaders)
//            .validate()
//            .responseDecodable(of: T.self) { response in
//                //print("response req",response.result)
//                switch response.result {
//                case .success(let data):
//                    completion(.success(data))
//                case .failure(let error):
//                    completion(.failure(error))
//                }
//            }
    }
    
    func get<T: Decodable>(endpoint: String, headers: HTTPHeaders = [:], completion: @escaping (Result<T, Error>) -> Void) {
        request(endpoint: endpoint, method: .get, body: nil as String?, headers: headers, completion: completion)
    }
    
    func post<T: Decodable, B: Encodable>(endpoint: String, body: B, headers: HTTPHeaders = [:], completion: @escaping (Result<T, Error>) -> Void) {
        request(endpoint: endpoint, method: .post, body: body, headers: headers, completion: completion)
    }
    
    func put<T: Decodable, B: Encodable>(endpoint: String, body: B, headers: HTTPHeaders = [:], completion: @escaping (Result<T, Error>) -> Void) {
        request(endpoint: endpoint, method: .put, body: body, headers: headers, completion: completion)
    }
    
    func delete<T: Decodable>(endpoint: String, headers: HTTPHeaders = [:], completion: @escaping (Result<T, Error>) -> Void) {
        request(endpoint: endpoint, method: .delete, body: nil as String?, headers: headers, completion: completion)
    }
    
    func upload<T: Decodable>(
        endpoint: String,
        parameters: [String: String] = [:],
        fileData: Data,
        fileName: String,
        mimeType: String,
        headers: HTTPHeaders = [:],
        docType:String,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let url = "\(baseURL)/\(endpoint)"
        print("URL: \(url)")
        print("Parameters: \(parameters)")
        
        if fileData.isEmpty {
            print("Image data is empty")
        } else {
            print("Image size: \(fileData.count) bytes")
        }
        
        var finalHeaders = headers
        if let accessToken = TokenManager.shared.accessToken {
            finalHeaders.add(name: "Authorization", value: "Bearer \(accessToken)")
        }
        
        AF.upload(multipartFormData: { formData in
            for (key, value) in parameters {
                formData.append(Data(value.utf8), withName: key)
            }
            formData.append(fileData, withName: docType, fileName: fileName, mimeType: mimeType)
        }, to: url, headers: finalHeaders)
        .validate()
        .responseDecodable(of: T.self) { response in
            switch response.result {
            case .success(let data):
                print("✅ Success Response: \(data)")
                completion(.success(data))
               
            case .failure(let error):
                // ❌ Print debug info for better troubleshooting
                if let responseData = response.data, let errorMessage = String(data: responseData, encoding: .utf8) {
                    print("❌ Error Response: \(errorMessage)")
                }
                print("❌ Request Failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
}
    
//    func upload<T: Decodable>(
//        endpoint: String,
//        parameters: [String: String] = [:],
//        fileData: Data,
//        fileName: String,
//        mimeType: String,
//        headers: HTTPHeaders = [:],
//        completion: @escaping (Result<T, Error>) -> Void
//    ) {
//        let url = "\(baseURL)/\(endpoint)"
//        print("url-->",url)
//        print("fileData",fileData,fileName,mimeType)
//        print("parameters",parameters)
//
//        var finalHeaders = headers
//        finalHeaders.add(name: "Content-Type", value: "multipart/form-data")
//        
//        if let accessToken = TokenManager.shared.accessToken {
//            finalHeaders.add(name: "Authorization", value: "Bearer \(accessToken)")
//        }
//        
//        AF.upload(multipartFormData: { formData in
//            for (key, value) in parameters {
//                formData.append(Data(value.utf8), withName: key)
//            }
//            formData.append(fileData, withName: "image", fileName: fileName, mimeType: mimeType)
//        }, to: url, headers: finalHeaders)
//        .validate()
//        .responseDecodable(of: T.self) { response in
//            switch response.result {
//            case .success(let data):
//                completion(.success(data))
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }
//}
