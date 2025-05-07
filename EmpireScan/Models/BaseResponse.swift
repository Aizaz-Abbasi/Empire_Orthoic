//
//  BaseResponse.swift
//  EmpireScan
//  Created by MacOK on 11/03/2025.
//
import Foundation

struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let message: String
    let data: T?
    let errors: [APIError]?
}

struct APIResponseArray<T: Codable>: Codable {
    let success: Bool
    let message: String
    let data: [T]?
    let errors: [APIError]?
}

struct APIError: Codable {
    let code: String
    let description: String
}

struct APICallResponse :Codable {
    let success: Bool
    let message: String
    let errors: [APIError]?
}

struct PaginatedData<T: Codable>: Codable  {
    let totalItems: Int
    let pageNumber: Int
    let pageSize: Int
    let totalPages: Int
    let hasPreviousPage: Bool
    let hasNextPage: Bool
    let items: [T]
}

// Example of LoginResponse Data Structure
struct LoginData: Codable {
    let accessToken: String
    let refreshToken: String
}

struct UserStats: Codable {
    let userId: Int
    let practitionerId: Int
    let firstName: String
    let lastName: String
    let profileImageUrl: String
    let practitioners: Int
    let patients: Int
    let totalScans: Int
    let pendingScans: Int
    let notScanYet: Int
    let submissionError: Int
}

struct UserProfile: Codable {
    let id: Int
    let userId: Int
    let firstName: String
    let lastName: String
    let title: String
    let email: String
    let phone: String
    let fax: String
    let speciality1: String
    let speciality2: String
    let speciality3: String
    let gender: String
    let uom: String
    let dob: String?
    let shippingAddress: String
    let billingAddress: String
}

struct Patient: Identifiable {
    let id: Int
    let name: String
    let lastScan: String
    let status: String
    let image: UIImage
    var isSelected: Bool
}

struct PatientData: Identifiable, Equatable,  Codable{
    var id: Int?
    let totalOrders: Int?
    let imageUrl: String?
    var orderId: Int
    let entryDate: String?
    let bld: Bool?
    let patientId: Int?
    let shoeSize: String?
    let date: String?
    let providerAccount: Int?
    let officeLocation: String?
    let isLeft: Bool?
    let isRight: Bool?
    let isBl: Bool?
    let other: String?
    let additionalInstructions: String?
    let completeDate: String?
    var status: String?
    let createdDate: String?
    let createdBy: String?
    let modifyDate: String?
    let modifyBy: String?
    let patientLastName: String?
    let patientFirstName: String?
    let orderCreateBy: String?
    let completionDate: String?
    let practiceName: String?
    
    let trackingNumber: String?
    let shippedDate: String?
    let deliveryDate: String?
    let sex: String?
    let foamCast: Bool?
    let note: String?
    let inComplete: Bool?
    let attachmentUrl: String?
    let notepad: String?
    let cfoplus: Bool?
    let noCharge: Bool?
    let cfoscanPlus: Bool?
    let physicianID: Int?
    let doctorName: String?
}

struct ScanFolderItem: Codable, Identifiable {
    var id: Int { folderId }
    let folderId: Int
    var documents: [OrderScans]
    var images: [OrderScans]
    var scans: [OrderScans]
}

struct OrderScans: Codable, Identifiable {
    var id: Int { documentId }

    let documentId: Int
    let description: String
    let attachmentUrl: String
    let footType: String?
    let scanType: String?
    let createDate: String
    let documentType: String
}

struct WorkOrder: Codable {
    var orderId: Int
    var orderStatus: String
    var notes:String
    var orderDetails: [WorkOrderOption]
}

struct WorkOrderOption: Codable, Identifiable {
    var id = UUID()
    var optionName: String
    var isLeft: Bool
    var isRight: Bool
    var isBL: Bool
    var isEmpty:Bool
    var isCustom: Bool
    var customValue: String
}
