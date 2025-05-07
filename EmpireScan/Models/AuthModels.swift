//
//  AuthModels.swift
//  EmpireScan
//
//  Created by MacOK on 11/03/2025.
//
import Foundation

struct NilParam: Codable {
}

struct LoginUser: Codable {
    let email: String
    let password: String
}

struct SearchOrdersRequest: Encodable {
    var searchText: String?
    var status: String?
    var practitionerId: Int?
    var startDate: String?
    var endDate: String?
    var sortBy: String
    var pageNumber: Int
    var pageSize: Int

    enum CodingKeys: String, CodingKey {
        case searchText, status, practitionerId, startDate, endDate, sortBy, pageNumber, pageSize
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(searchText, forKey: .searchText)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(practitionerId, forKey: .practitionerId)
        try container.encodeIfPresent(startDate, forKey: .startDate) // Ensures null instead of omission
        try container.encodeIfPresent(endDate, forKey: .endDate) // Ensures null instead of omission
        try container.encode(sortBy, forKey: .sortBy)
        try container.encode(pageNumber, forKey: .pageNumber)
        try container.encode(pageSize, forKey: .pageSize)
    }
}

struct ScanRequest: Encodable {

    var orderId: Int?
    var description: String?
    var footType: String?
    var scanType: String?
    var folderId: Int? // This is already optional, so it can be `null`
    var attachment: URL?

    enum CodingKeys: String, CodingKey {
        case orderId, description, folderId, footType, scanType, attachment
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encoding optional properties, with encodeIfPresent to allow null values
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(orderId, forKey: .orderId)
        try container.encodeIfPresent(folderId, forKey: .folderId)  // This allows folderId to be null
        try container.encodeIfPresent(footType, forKey: .footType)
        try container.encodeIfPresent(scanType, forKey: .scanType)
        try container.encodeIfPresent(attachment, forKey: .attachment)
    }
}

struct ScanList: Encodable {

    var orderId: Int
    var orderStatus:String
    enum CodingKeys: String, CodingKey {
        case orderId,orderStatus
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(orderId, forKey: .orderId)
        try container.encodeIfPresent(orderStatus, forKey: .orderStatus)
    }
}

struct SubmitOrder: Encodable {

    var orderId: Int
    enum CodingKeys: String, CodingKey {
        case orderId
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(orderId, forKey: .orderId)
    }
}
