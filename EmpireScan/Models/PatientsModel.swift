//
//  PatientsModel.swift
//  EmpireScan
//  Created by MacOK on 26/03/2025.
//

struct PatientRequest: Codable {
    var ssn: String?
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var fax: String?
    var gender: String?
    var dob: String?
    var weight: Double?
    var weightUom: String?
    var shoeSize: Double?
    var shoeUom: String?
    var practitionerId: Int?
    var street: String?
    var city: String?
    var state: String?
    var zip: Int?
    var country: String?
    var image: Data? // For binary image data

    enum CodingKeys: String, CodingKey {
        case ssn, firstName, lastName, email, phone, fax, gender, dob, weight, weightUom
        case shoeSize, shoeUom, practitionerId, street, city, state, zip, country, image
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(ssn, forKey: .ssn)
        try container.encode(firstName, forKey: .firstName)
        try container.encode(lastName, forKey: .lastName)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(fax, forKey: .fax)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(dob, forKey: .dob)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(weightUom, forKey: .weightUom)
        try container.encode(shoeSize, forKey: .shoeSize)
        try container.encodeIfPresent(shoeUom, forKey: .shoeUom)
        try container.encodeIfPresent(practitionerId, forKey: .practitionerId)
        try container.encodeIfPresent(street, forKey: .street)
        try container.encodeIfPresent(city, forKey: .city)
        try container.encodeIfPresent(state, forKey: .state)
        try container.encodeIfPresent(zip, forKey: .zip)
        try container.encodeIfPresent(country, forKey: .country)

        // Encode image as Base64 if present
        if let imageData = image {
            let base64String = imageData.base64EncodedString()
            try container.encode(base64String, forKey: .image)
        }
    }
}

struct OrderPatientProfile: Codable {
    let orderHeaderId: Int?
    let patientId: Int?
    let imageUrl: String?
    let firstName: String?
    let lastName: String?
    let status: String?
    let lastScan: Date?
    let email: String?
    let phone: String?
    let fax: String?
    let gender: String?
    let dob: Date?
    let weight: String?
    let shoeSize: String?
    let address: String?
    let practitionerId: Int?
    let practitionerName: String?
    let practitionerEmail: String?
    let practitionerPhone: String?
    let practitionerFax: String?
    
    // Custom Date Decoding
    private enum CodingKeys: String, CodingKey {
        case orderHeaderId, patientId, imageUrl, firstName, lastName, status
        case lastScan, email, phone, fax, gender, dob, weight, shoeSize, address
        case practitionerId, practitionerName, practitionerEmail, practitionerPhone, practitionerFax
    }
    
    // Date Formatter
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSX"
        return formatter
    }()
    
    // Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        orderHeaderId = try container.decodeIfPresent(Int.self, forKey: .orderHeaderId)
        patientId = try container.decodeIfPresent(Int.self, forKey: .patientId)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        firstName = try container.decodeIfPresent(String.self, forKey: .firstName)
        lastName = try container.decodeIfPresent(String.self, forKey: .lastName)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        fax = try container.decodeIfPresent(String.self, forKey: .fax)
        gender = try container.decodeIfPresent(String.self, forKey: .gender)
        weight = try container.decodeIfPresent(String.self, forKey: .weight)
        shoeSize = try container.decodeIfPresent(String.self, forKey: .shoeSize)
        address = try container.decodeIfPresent(String.self, forKey: .address)
        practitionerId = try container.decodeIfPresent(Int.self, forKey: .practitionerId)
        practitionerName = try container.decodeIfPresent(String.self, forKey: .practitionerName)
        practitionerEmail = try container.decodeIfPresent(String.self, forKey: .practitionerEmail)
        practitionerPhone = try container.decodeIfPresent(String.self, forKey: .practitionerPhone)
        practitionerFax = try container.decodeIfPresent(String.self, forKey: .practitionerFax)
        
        // Decode Dates
        if let lastScanString = try container.decodeIfPresent(String.self, forKey: .lastScan) {
            lastScan = OrderPatientProfile.dateFormatter.date(from: lastScanString)
        } else {
            lastScan = nil
        }
        
        if let dobString = try container.decodeIfPresent(String.self, forKey: .dob) {
            dob = OrderPatientProfile.dateFormatter.date(from: dobString)
        } else {
            dob = nil
        }
    }
    
    // Custom Encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(orderHeaderId, forKey: .orderHeaderId)
        try container.encodeIfPresent(patientId, forKey: .patientId)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(firstName, forKey: .firstName)
        try container.encodeIfPresent(lastName, forKey: .lastName)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(fax, forKey: .fax)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(weight, forKey: .weight)
        try container.encodeIfPresent(shoeSize, forKey: .shoeSize)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(practitionerId, forKey: .practitionerId)
        try container.encodeIfPresent(practitionerName, forKey: .practitionerName)
        try container.encodeIfPresent(practitionerEmail, forKey: .practitionerEmail)
        try container.encodeIfPresent(practitionerPhone, forKey: .practitionerPhone)
        try container.encodeIfPresent(practitionerFax, forKey: .practitionerFax)
        
        // Encode Dates as Strings
        if let lastScan = lastScan {
            try container.encode(OrderPatientProfile.dateFormatter.string(from: lastScan), forKey: .lastScan)
        }
        
        if let dob = dob {
            try container.encode(OrderPatientProfile.dateFormatter.string(from: dob), forKey: .dob)
        }
    }
}
