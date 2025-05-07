//
//  NewPatientView.swift
//  EmpireScan
//
//  Created by MacOK on 20/03/2025.
//

import SwiftUI

@available(iOS 15.0, *)
struct NewPatientView: View {
    @Environment(\.dismiss) private var dismiss
    var dismissAction: ((PatientData) -> Void)?
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var fax: String = ""
    @State private var gender: String = ""
    @State private var dateOfBirth = Date()
    @State private var weight = ""
    @State private var selectedWeightUnit = "lbs"
    @State private var shoeSize = ""
    @State private var selectedShoeUnit = "US"
    @State private var selectedPractitioner = "Select"
    
    @State private var street: String = ""
    @State private var city: String = ""
    @State private var country: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    
    @State private var isShowingImagePicker = false
    @State private var selectedImage: UIImage? = nil
    @FocusState private var focusedField: FocusedField?
    @State private var validationMessage: String? = nil
    
    let weightUnits = [ "lbs","kg"]
    let shoeUnits = ["US"]
    let practitioners = [HomeService.shared.user?.firstName ?? "" + " " + (HomeService.shared.user?.lastName ?? "") ]
    
    enum FocusedField {
        case firstName, lastName, email, phone, fax
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.black)
                                .font(.title2)
                        }
                        .padding(.leading, 16)
                        Spacer()
                        Text("New Patient")
                            .font(.title)
                            .bold()
                        Spacer()
                    }
                    .padding(.top, 10)
                    
                    // Personal Information
                    SectionHeader(title: "Personal Information")
                    CustomTextField(title: "First Name", text: $firstName,placeholder: "",
                                    isSecure: false,
                                    screenWidth: geometry.size.width,
                                    screenHeight: UIScreen.main.bounds.height,isRequired: true)
                    CustomTextField(title: "Last Name", text: $lastName,placeholder: "",
                                    isSecure: false,
                                    screenWidth: geometry.size.width,
                                    screenHeight: UIScreen.main.bounds.height,
                                    isRequired: true)
                    
                    // Image Upload
                    HStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                        }
                        
                        Button(action: {
                            isShowingImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "icloud.and.arrow.up")
                                    .foregroundColor(.red)
                                Text("Upload Photo")
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 8).stroke(Color.red, lineWidth: 1))
                        }
                        .sheet(isPresented: $isShowingImagePicker) {
                            ImagePicker(sourceType: .photoLibrary,selectedImage: $selectedImage)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, UIScreen.main.bounds.width * 0.05)

                    // General Information
                    SectionHeader(title: "General Information")
                    CustomTextField(title: "Email", text: $email,placeholder: "",
                                    isSecure: false,
                                    screenWidth: geometry.size.width,
                                    screenHeight: UIScreen.main.bounds.height)
                    CustomTextField(title: "Phone", text: $phone,placeholder: "",
                                    isSecure: false,
                                    screenWidth: geometry.size.width,
                                    screenHeight: UIScreen.main.bounds.height)
                    CustomTextField(title: "Fax", text: $fax,placeholder: "",
                                    isSecure: false,
                                    screenWidth: geometry.size.width,
                                    screenHeight: UIScreen.main.bounds.height)
                    
                    VStack {
                        VStack(alignment: .leading, spacing: 0) {
                            
                            HStack(spacing: 1) {
                                Text("Gender")
                                    .font(.system(size: 16, weight: .semibold))
                               
                                    Text("*")
                                        .foregroundColor(.red)
                                        .font(.system(size: 16, weight: .bold))

                            }
                            HStack(spacing: 8) {
                                GenderButton(title: "Male", selectedGender: $gender)
                                GenderButton(title: "Female", selectedGender: $gender)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Date of Birth")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                                    .background(Color.white)
                                    .frame(height:  UIScreen.main.bounds.height * 0.055) // Match text field height
                                
                                DatePicker("", selection: $dateOfBirth, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity) // Expand to full size
                                    .padding(.horizontal, 10)
                                    .background(Color.white)
                                
                            }
                            .frame(height:  UIScreen.main.bounds.height * 0.055) // Ensures consistent height
                        }
                        
                        // Weight & Shoe Size
                        HStack(alignment: .bottom) {
                            CustomTextFieldSmall(title: "Weight", text: $weight,width: geometry.size.width * 0.70)
                            CustomPicker(title: "", selection: $selectedWeightUnit, options: weightUnits, width: geometry.size.width * 0.30)
                        }
                        
                        HStack(alignment:.bottom, spacing: 16) {
                            CustomTextFieldSmall(title: "Shoe Size", text: $shoeSize,width: geometry.size.width * 0.70,isRequired: true)
                            CustomPicker(title: "", selection: $selectedShoeUnit, options: shoeUnits, width: geometry.size.width * 0.30)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Practitioner")
                                .foregroundColor(.black)
                                .fontWeight(.medium)
                                .font(.system(size: geometry.size.width * 0.04))
                            
                            Text(practitioners[0])
                                .foregroundColor(.black)
                                .fontWeight(.medium)
                                .font(.system(size: geometry.size.width * 0.04))
                                .frame(maxWidth: .infinity, minHeight: UIScreen.main.bounds.height * 0.055) // Ensuring full width
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1))
                        }
                        .frame(maxWidth: .infinity) // Ensures VStack takes full width
                        //.padding(.horizontal, geometry.size.width * 0.05)
                        
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, UIScreen.main.bounds.width * 0.05)
                    //.padding(.bottom,UIScreen.main.bounds.height * 0.1)
                    
                    
                    SectionHeader(title: "Address")
                    CustomTextField(title: "Street#", text: $street,placeholder: "",
                                    isSecure: false,
                                    screenWidth: geometry.size.width,
                                    screenHeight: UIScreen.main.bounds.height)
                    CustomTextField(title: "City", text: $city,placeholder: "",
                                    isSecure: false,
                                    screenWidth: geometry.size.width,
                                    screenHeight: UIScreen.main.bounds.height)
                    CustomTextField(title: "Country", text: $country,placeholder: "",
                                    isSecure: false,
                                    screenWidth: geometry.size.width,
                                    screenHeight: UIScreen.main.bounds.height)
                    CustomTextField(title: "State / Province", text: $state,placeholder: "",
                                    isSecure: false,
                                    screenWidth: geometry.size.width,
                                    screenHeight: UIScreen.main.bounds.height)
                        CustomTextField(title: "Zip Code", text: $zipCode,placeholder: "",
                                    isSecure: false,
                                    screenWidth: geometry.size.width,
                                    screenHeight: UIScreen.main.bounds.height)

                    }
                    .padding(.bottom,UIScreen.main.bounds.height*0.3)
                    .keyboardAware()
                }
                if let validationMessage = validationMessage {
                    Text(validationMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                Spacer()
                // Save Button
                Button(action: {
                    savePatientData()
                }) {
                    Text("Save")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: geometry.size.width * 0.9, height: 50)
                        .background(Colors.primary)
                        .cornerRadius(25)
                }
                .padding(.bottom, 10)
                .background(Colors.white)
            }
            .onTapGesture {
                hideKeyboard()
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
    
    func navigateToScannerVC() {        
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            print("Window not found")
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let scanVC = storyboard.instantiateViewController(withIdentifier: "FootSelectionVC")
        if let topViewController = window.rootViewController?.topMostViewController() {
            print("navigateToScannerVC: Presenting on \(topViewController)")
            //topViewController.present(scanVC, animated: true, completion: nil)
            DispatchQueue.main.async {
                scanVC.modalPresentationStyle = .fullScreen
                topViewController.present(scanVC, animated: true, completion: nil)
            }
        } else {
            print("Top view controller not found")
        }
    }


    
    private func savePatientData() {
        guard validateForm() else { return }
        var imageData: Data?
        var fileName: String = ""
        var mimeType: String = ""
    
        if let selectedImage = selectedImage, let jpegData = selectedImage.jpegData(compressionQuality: 0.7) {
            imageData = jpegData
            fileName = "patient_profile.jpg"
            mimeType = "image/jpeg"
        }
        
        let requestBody = PatientRequest(
            //ssn: ssn,
            firstName: firstName,
            lastName: lastName,
            email: email,
            phone: phone,
            fax: fax,
            gender: gender,
            dob: ISO8601DateFormatter().string(from: dateOfBirth),
            weight: Double(weight),
            weightUom: selectedWeightUnit,
            shoeSize:Double(shoeSize),
            shoeUom: selectedShoeUnit,
            practitionerId:5002,//id
            street: street,
            city: city,
            state: state,
            zip: Int(zipCode),
            image: imageData
        )

        PatientsService.shared.postSavePatient(requestBody: requestBody) { result in
            switch result {
            case .success(let response):
                print("Patient saved successfully:", response.data)
                if response.success, let patientData = response.data {
                            dismiss()
                            dismissAction?(patientData)
                        } else {
                            print("❌ Patient save response missing data")
                        }
            case .failure(let error):
                print("Error saving patient:", error.localizedDescription)
            }
        }
    }

    private func validateForm() -> Bool {
        if firstName.isEmpty {
            validationMessage = "First name is required."
            return false
        }

        if lastName.isEmpty {
            validationMessage = "Last name is required."
            return false
        }

        if shoeSize.isEmpty {
            validationMessage = "Shoe size is required."
            return false
        }
        
        if gender.isEmpty {
            validationMessage = "Gender is required."
            return false
        }
        validationMessage = nil
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = "^[0-9]{10,15}$"
        return NSPredicate(format: "SELF MATCHES %@", phoneRegex).evaluate(with: phone)
    }
}

#Preview {
    if #available(iOS 15.0, *) {
        NewPatientView(dismissAction: nil)
    } else {
        // Fallback on earlier versions
    }
}
