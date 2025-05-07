//
//  ScansService.swift
//  EmpireScan
//
//  Created by MacOK on 18/03/2025.
//
import Foundation
import Alamofire
import SwiftUI
class ScansService {
    
    static let shared = ScansService()
    private init() {}
    
    func getScansOrder(requestBody:SearchOrdersRequest, completion: @escaping (Result<APIResponse<PaginatedData<PatientData>>, Error>) -> Void) {
        
        NetworkService.shared.post(endpoint:ScansEndpoints.SearchOrders, body: requestBody) { (result: Result<APIResponse<PaginatedData<PatientData>>, Error>) in
            switch result {
            case .success(let apiResponse):
                completion(.success(apiResponse))
            case .failure(let error):
                print("getScansOrder====>",error)
                completion(.failure(error))
            }
        }
    }
    
    func uploadScanResult(
        orderId: Int,
        description: String,
        footType: String,
        scanType: String,
        folderId: Int?,
        orderStatus:String,
        meshFileURL: URL,
        completion: @escaping (Result<APIResponse<OrderScans>, Error>) -> Void
    ) {
        guard let fileData = try? Data(contentsOf: meshFileURL) else {
            print("❌ Error: Unable to read mesh file at path \(meshFileURL.path)")
            completion(.failure(NSError(domain: "FileError", code: -1, userInfo: [NSLocalizedDescriptionKey: "File not found"])))
            return
        }
        
        var parameters: [String: String] = [
            "orderId": "\(orderId)",
            "description": description,
            "footType": footType,
            "scanType": scanType,
            "documentType":"scan",
            "orderStatus":orderStatus
        ]

        if let folderId = folderId {
            parameters["folderId"] = "\(folderId)"
        }

        NetworkService.shared.upload(
            endpoint: ScansEndpoints.UploadScanAttachment,
            parameters: parameters,
            fileData: fileData,
            fileName: meshFileURL.lastPathComponent,
            mimeType: "application/zip",
            docType: "attachment",
            completion: completion
        )
    }
    
    func uploadOrderDocument(
        orderId: Int,
        folderId: Int? = nil,
        documentId:Int? = nil,
        orderStatus: String,
        fileURL: URL,
        documentType: String = "document", // e.g., "scan", "image", "attachment"
        completion: @escaping (Result<APIResponse<OrderScans>, Error>) -> Void
    ) {
        guard let fileData = try? Data(contentsOf: fileURL) else {
            print("❌ Error: Unable to read file at path \(fileURL.path)")
            completion(.failure(NSError(domain: "FileError", code: -1, userInfo: [NSLocalizedDescriptionKey: "File not found"])))
            return
        }
        let mimeType = mimeType(for: fileURL)
        var parameters: [String: String] = [
            "orderId": "\(orderId)",
            "documentType": documentType,
            "orderStatus": orderStatus
        ]

        if let folderId = folderId {
            parameters["folderId"] = "\(folderId)"
        }
        if let documentId = documentId {
            parameters["documentId"] = "\(documentId)"
        }

        NetworkService.shared.upload(
            endpoint: ScansEndpoints.UploadScanAttachment,
            parameters: parameters,
            fileData: fileData,
            fileName: fileURL.lastPathComponent,
            mimeType: mimeType,
            docType:"attachment",
            completion: completion
        )
    }
    
    func updateAttachmentDescription(
            documentId: Int,
            orderStatus: String,
            description: String,
            completion: @escaping (Result<APIResponse<OrderScans>, Error>) -> Void
        ) {
            let endpoint = "\(ScansEndpoints.UpdateAttachmentDescription)/\(documentId)/\(orderStatus)"
            let body = UpdateAttachmentDescriptionRequest(description: description)
            
            NetworkService.shared.put(endpoint: endpoint, body: body, completion: completion)
        }
    
    func deleteAttachment(
        documentId: Int,
        orderStatus: String,
        completion: @escaping (Result<APIResponse<String>, Error>) -> Void
    ) {
        let endpoint = "\(ScansEndpoints.DeleteAttachment)/\(documentId)/\(orderStatus)"
        NetworkService.shared.delete(endpoint: endpoint, completion: completion)
    }
    
    func postOrderFormCustom(requestBody:[WorkOrderOption],notes:String,orderId:Int,orderStatus:String, completion: @escaping (Result<APIResponse<String>, Error>) -> Void) {
        let workOrderBody = WorkOrder(orderId: orderId, orderStatus: orderStatus, notes: notes, orderDetails: requestBody)
        NetworkService.shared.post(endpoint:"\(OrdersEndpoints.PostSubmitOrderDetails)", body: workOrderBody) { (result: Result<APIResponse<String>, Error>) in
            switch result {
            case .success(let apiResponse):
                completion(.success(apiResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

}

struct UpdateAttachmentDescriptionRequest: Encodable {
    let description: String
}

func generateMeshFileName(extension ext: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmmss" // Format: YYYYMMDD_HHMMSS
    let timestamp = formatter.string(from: Date())
    return "Model_\(timestamp).\(ext)"
}
