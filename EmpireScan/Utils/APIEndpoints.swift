//
//  APIEndpoints.swift
//  EmpireScan
//
//  Created by MacOK on 10/03/2025.
//
import Foundation
struct APIEndpoints {
    static let login = "login"
    static let register = "auth/register"
    static let userProfile = "user/profile"
    static let posts = "posts"
}

struct HomeEndpoints {
    static let homeStats = "GetHomeScreenStats"
    static let getUserDetails = "GetUserDetails"
}

struct ScansEndpoints {
    static let Orders = "Orders/{pageNumber}/{pageSize}"
    static let SearchOrders = "Orders/SearchOrders"
    static let UploadScanAttachment = "Orders/UploadOrderAttachment"
    static let UpdateAttachmentDescription = "Orders/UpdateAttachmentDescription"
    static let DeleteAttachment = "Orders/DeleteOrderAttachments"
}

struct PatientsEndpoints {
    static let PostPatient = "Patient"
    static let GetPatientProfile = "Patient/getPatientByOrderIdAndStatus"
    //"Patient/getPatientByOrderId"
}

struct OrdersEndpoints {
    static let GetOrderAttachments = "Orders/GetOrderAttachments"
    static let PostSubmitOrder = "Orders/SubmitOrder"
    static let PostSubmitOrderDetails = "Orders/SubmitOrderDetails"
}
