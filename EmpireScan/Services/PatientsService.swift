//
//  PatientsService.swift
//  EmpireScan
//
//  Created by MacOK on 26/03/2025.
//
import Foundation
import Alamofire
import SwiftUI

class PatientsService {
    
    static let shared = PatientsService()
    private init() {}
    
    func postSavePatient(requestBody: PatientRequest, completion: @escaping (Result<APIResponse<PatientData>, Error>) -> Void) {
        
        let dateStr = convertToDateOnly(from: requestBody.dob ?? "")
        
        var parameters: [String: String] = [
            "firstName": requestBody.firstName ?? "",
            "lastName": requestBody.lastName ?? "",
            "gender": requestBody.gender ?? "",
            "shoeSize": requestBody.shoeSize.map { String($0) } ?? ""
        ]
        if let shoeUom = requestBody.shoeUom, !shoeUom.isEmpty {
            parameters["shoeUom"] = shoeUom
        }
        if let email = requestBody.email, !email.isEmpty {
            parameters["email"] = email
        }
        if let phone = requestBody.phone, !phone.isEmpty {
            parameters["phone"] = phone
        }
        if let fax = requestBody.fax, !fax.isEmpty {
            parameters["fax"] = fax
        }
        if !dateStr.isEmpty {
            parameters["dob"] = dateStr
        }
        if let weight = requestBody.weight {
            parameters["weight"] = String(weight)
        }
        if let weightUom = requestBody.weightUom, !weightUom.isEmpty {
            parameters["weightUom"] = weightUom
        }
        if let practitionerId = requestBody.practitionerId, practitionerId > 0 {
            parameters["practitionerId"] = String(practitionerId)
        }
        if let street = requestBody.street, !street.isEmpty {
            parameters["street"] = street
        }
        if let city = requestBody.city, !city.isEmpty {
            parameters["city"] = city
        }
        if let state = requestBody.state, !state.isEmpty {
            parameters["state"] = state
        }
        if let country = requestBody.country, !country.isEmpty {
            parameters["country"] = country
        }
        if let zip = requestBody.zip, zip > 0 {
            parameters["zip"] = String(zip)
        }

        if let imageData = requestBody.image, !imageData.isEmpty {
            // Proceed with upload
        } else {
            print("No image data provided")
        }

        NetworkService.shared.upload(
            endpoint: PatientsEndpoints.PostPatient,
            parameters: parameters,
            fileData: requestBody.image ?? Data(),
            fileName:  "patient_profile.jpg",
            mimeType: "image/jpeg",
            docType: "image",
            completion: completion
        )
    }
    
    func getPatientProfile(orderId: Int,status:String, completion: @escaping (Result<APIResponse<OrderPatientProfile>, Error>) -> Void) {
        
        NetworkService.shared.get(endpoint: "\(PatientsEndpoints.GetPatientProfile)/\(orderId)/\(status)") { (result: Result<APIResponse<OrderPatientProfile>, Error>) in
            switch result {
            case .success(let apiResponse):
                //print("getPatientProfile Response:", apiResponse)
                completion(.success(apiResponse))
            case .failure(let error):
                //print("Error getPatientProfile:",error.localizedDescription)
                completion(.failure(error))
            }
        }
    }
    
    func getPatientList(requestBody:SearchOrdersRequest, completion: @escaping (Result<APIResponse<PaginatedData<PatientData>>, Error>) -> Void) {
        
        NetworkService.shared.post(endpoint:ScansEndpoints.SearchOrders, body: requestBody) { (result: Result<APIResponse<PaginatedData<PatientData>>, Error>) in
            switch result {
            case .success(let apiResponse):
                completion(.success(apiResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func getScansList(requestBody:ScanList, completion: @escaping (Result<APIResponseArray<ScanFolderItem>, Error>) -> Void) {
        NetworkService.shared.post(endpoint:"\(OrdersEndpoints.GetOrderAttachments)/\(requestBody.orderId)/\(requestBody.orderStatus)", body: requestBody) { (result: Result<APIResponseArray<ScanFolderItem>, Error>) in
            switch result {
            case .success(let apiResponse):
                completion(.success(apiResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    //"Orders/SubmitOrder"
    func postSubmitOrder(requestBody:SubmitOrder, completion: @escaping (Result<APIResponse<OrderPatientProfile>, Error>) -> Void) {
        NetworkService.shared.post(endpoint:"\(OrdersEndpoints.PostSubmitOrder)", body: requestBody) { (result: Result<APIResponse<OrderPatientProfile>, Error>) in
            switch result {
            case .success(let apiResponse):
                completion(.success(apiResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
