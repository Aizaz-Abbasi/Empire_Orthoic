
//
//  PatientProfileView.swift
//  EmpireScan
//
//  Created by MacOK on 27/03/2025.
//
import Foundation
import SwiftUI
struct PatientProfileView: View {
    
    @State var patient: PatientData
    @State private var patientData: OrderPatientProfile?
    @State private var scanList: [ScanFolderItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showOverlay = false
    @State private var selectedIndex: Int? = nil
    @State private var isShowingPDFForm = false
    @State private var isNotificationTriggered = false

    var onSOrderSubmitted: ((Int) -> Void)?
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    @State private var showScanView = false
    @State private var selectedScanObj: ScanFolderItem? = nil
 
    var body: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        PatientProfileHeaderView(patientData: patientData)
                            .frame(width: screenWidth, alignment: .top)
                            .ignoresSafeArea(edges: .top)
                        
                        generalInformationView
                        DividerView()
                        
                        practitionerInformationView
                        DividerView()
//                        if(self.patient.status == "Not Scanned"){
                            latestScansView
                            DividerView()
//                        }
                        Spacer().frame(height: 100)
                    }
                    .padding(.bottom, 20)
                    .onAppear {
                        print("scanUploaded--->|||")
                        fetchPatientProfile()
                        fetchScanList()
                    }
                    
                }
                if(self.patient.status == "Not Scanned"){
                    bottomButtons()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .scanUploadedSuccessfully)) { _ in
                print("scanUploaded--->")
                isNotificationTriggered = true
            }
            // ScanOverlayView on top of everything
            if showScanView && (selectedScanObj != nil){
                
                ScanOverlayView(
                    isPresented: $showScanView,
                    isEditable: .constant(self.patient.status == "Not Scanned"),
                    folderItem: $selectedScanObj,
                    patient:patient,
                    patientData: $patientData,
                    onDismiss: {item in
                        updateScanItem(updatedItem: item, profileData: nil,isSubmitted: false)
                    },
                    submitOrder:{item,data,op  in
                        updateScanItem(updatedItem: item,profileData:data, isSubmitted: true)
                    }
                )
                .transition(.move(edge: .bottom))
                .zIndex(1)
            }
        }
    }
    
    func scanUploaded() {
        selectedScanObj = scanList.last
        showScanView = true
        isNotificationTriggered = false
    }
    
    func updateScanItem(updatedItem: ScanFolderItem,profileData:PatientData?,isSubmitted:Bool) {
        if let index = scanList.firstIndex(where: { $0.id == updatedItem.id }) {
            scanList[index] = updatedItem
        }
        if(isSubmitted){
            self.isNotificationTriggered = false
            self.patient.status = "Pending"
            onSOrderSubmitted?(self.patient.id!)
            //self.patient.orderId = profileData?.orderId ?? 0
            fetchPatientProfile()
            fetchScanList()
        }
    }
   
    private var generalInformationView: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("General Information")
                .font(.headline)
                .padding(.bottom, 5)
            
            ProfileInfoRow(title: "Email", value: patientData?.email ?? "N/A")
            ProfileInfoRow(title: "Phone", value: patientData?.phone ?? "N/A")
            ProfileInfoRow(title: "Fax", value: patientData?.fax ?? "N/A")
            ProfileInfoRow(title: "Gender", value: patientData?.gender ?? "N/A")
            ProfileInfoRow(title: "Weight", value: patientData?.weight ?? "N/A")
            ProfileInfoRow(title: "Shoe Size", value: patientData?.shoeSize ?? "")
            ProfileInfoRow(title: "Address", value: patientData?.address ?? "")
        }
        .frame(width: screenWidth * 0.9, alignment: .leading)
        .padding(.vertical, 20)
    }
    
    private func DividerView() -> some View {
        Rectangle()
            .fill(Color.gray.opacity(0.2))
            .frame(height: 10)
            .padding(.horizontal, 0)
    }
    
    private var practitionerInformationView: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .leading, spacing: 15) {
                Text("Practitioner Information")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 5)
                
                ProfileInfoRow(title: "Email", value: patientData?.practitionerEmail ?? "N/A")
                ProfileInfoRow(title: "Name", value: patientData?.practitionerName ?? "N/A")
            }
            .frame(width: screenWidth * 0.9, alignment: .leading)
            .padding(.vertical, 20)
        }
    }
    
    private var latestScansView: some View {
        VStack(alignment: .leading, spacing: 15) {
                Text("Latest Scans")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 5)
            if !scanList.isEmpty {
                latestScanListView
            } else {
                Text("No scans available")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .frame(width: screenWidth * 0.9, alignment: .leading)
        .padding(.vertical, 20)
    }
    
    private var latestScanListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(scanList.indices, id: \.self) { index in
                    Button(action: {
                        selectedScanObj = scanList[index]
                        showScanView = true
                    }) {
                        scanItemView(for: index)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.vertical, 8)
        }
        .frame(maxHeight: 300)
    }

    
    private func scanItemView(for index: Int) -> some View {
        LatestScanItem(
            item: scanList[index],
            title: "123",
            date: "122324",
            isSelected: selectedIndex == index
        )
        .padding(.horizontal, 4)
        .onTapGesture {
            selectedIndex = selectedIndex == index ? nil : index
            selectedScanObj = scanList[index]
            showScanView.toggle()
        }
    }
    
    func hasBothScans(in folderItem: ScanFolderItem?) -> Bool {
        guard let scans = folderItem?.scans, !scans.isEmpty else { return false }
        let hasLeft = scans.contains { $0.footType?.lowercased() == "left" }
        let hasRight = scans.contains { $0.footType?.lowercased() == "right" }
        return hasLeft && hasRight
    }
    
    @ViewBuilder
    func bottomButtons() -> some View {
        let screenWidth = UIScreen.main.bounds.width
        let allComplete = !scanList.isEmpty && scanList.allSatisfy { hasBothScans(in: $0) }

        VStack(spacing: 0) {
            Button(action: {
                print("Scan Now")
                navigateToScannerVC()
            }) {
                HStack {
                    Image(systemName: "viewfinder")
                        .foregroundColor(Colors.primary)
                    Text("Scan now")
                }
                .font(.system(size: 16, weight: .bold))
                .frame(width: screenWidth * 0.9, height: 50)
                .background(Colors.white)
                .foregroundColor(Colors.primary)
                .overlay(
                    Capsule().stroke(Colors.primary, lineWidth: 2)
                )
                .clipShape(Capsule())
            }
            .padding(.top, 5)
            
            if(allComplete){
                Button(action: {
                    print("Saveee Profile Tapped")
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text("Submit order")
                    }
                    .font(.system(size: 16, weight: .bold))
                    .frame(width: screenWidth * 0.9, height: 50)
                    .background(Colors.primary)
                    .foregroundColor(Colors.white)
                    .clipShape(Capsule())
                }
                .padding(.top, 10)
            }
            Color.clear.frame(height: 10)
        }
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
    }
    
    //
    private func fetchPatientProfile() {
        print("fetchPatientProfile",patient.orderId,patient.status ?? "---")
        isLoading = true
        PatientsService.shared.getPatientProfile(orderId: patient.orderId, status: patient.status ?? "All") { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let response):
                    self.patientData = response.data
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func fetchScanList() {
        print("fetchScanList")
        isLoading = true
        if patient.orderId > 0 {
            let orderId = patient.orderId
            let searchRequest = ScanList(orderId: orderId, orderStatus: patient.status ?? "")
            PatientsService.shared.getScansList(requestBody: searchRequest) { result in
                switch result {
                case .success(let apiResponse):
                    self.scanList = apiResponse.data ?? []
                    if let scanList = apiResponse.data {
                                do {
                                    let jsonData = try JSONEncoder().encode(scanList)
                                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                                        print("Scan List JSON:\n\(jsonString)")
                                    }
                                    if(isNotificationTriggered){
                                        print("isNotificationTriggered")
                                        scanUploaded()
                                    }
                                } catch {
                                    print("Error encoding scanList to JSON: \(error)")
                                }
                            }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    print("fetchScanList Error: \(error.localizedDescription)")
                }
            }
        } else {
            print("Invalid Order ID!")
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
        // Cast to your actual view controller type and set the parameter
        if let footSelectionVC = scanVC as? FootSelectionVC {
            footSelectionVC.patient = patient
        }
        if let topViewController = window.rootViewController?.topMostViewController() {
            if let navigationController = topViewController.navigationController {
                DispatchQueue.main.async {
                    navigationController.pushViewController(scanVC, animated: true)
                }
            } else {
                print("Navigation controller not found")
            }
        } else {
            print("Top view controller not found")
        }
    }
}

struct PatientProfileHeaderView: View {
    
    var patientData: OrderPatientProfile?
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            // Top Bar
            HStack {
                Button(action: {
                    print("Back tapped")
                    presentationMode.wrappedValue.dismiss() // Dismiss the current view
                    
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.black)
                }
                
                Spacer()
                Text("Patient Profile")
                    .font(.headline)
                Spacer()
                Button(action: {
                    print("More options tapped")
                }) {
                    Image(systemName: "square.and.pencil")
                        .font(.title2)
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal)
            
            VStack {
                ZStack(alignment: .bottomLeading) {
                    // Background Gradient Banner
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [Color(red: 0.6, green: 0, blue: 0), Color(red: 0.3, green: 0, blue: 0)]),
                            startPoint: .top,
                            endPoint: .bottom))
                        .frame(height: screenHeight*0.10) // Adjust height
                    
                    // Profile Image (overlapping)
                    HStack {
                        VStack {
                            
                            if let imageUrl = patientData?.imageUrl, let url = URL(string: imageUrl) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: screenHeight*0.1, height: screenHeight*0.1)
                                        .clipShape(Circle())
                                        .overlay(Circle().stroke(Color.white, lineWidth: 3))
                                        .background(Color.gray)
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: screenHeight*0.1, height: screenHeight*0.1)
                                }
                                .cornerRadius(screenHeight*0.1/2)
                            } else {
                                Circle()
                                    .fill(Color.gray)
                                    .frame(width: screenHeight*0.1, height: screenHeight*0.1)
                            }
                        }
                        .padding(.horizontal, screenWidth*0.02)
                        
                        Spacer()
                        HStack {
                            HStack {
                                Image(systemName: patientData?.status == "Not Scanned" ? "xmark.circle.fill" : "checkmark.circle.fill")
                                    .foregroundColor(patientData?.status == "Not Scanned" ? .red : .green)
                                Text("\(patientData?.status ?? "")")
                                    .font(.caption)
                                    .foregroundColor(patientData?.status == "Not Scanned" ? .red : .green)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color(patientData?.status == "Not Scanned" ? .red : .green).opacity(0.2))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(patientData?.status == "Not Scanned" ? Color.red : Color.green, lineWidth: 1)
                            )
                            .offset(x: -10, y: 40)
                        }
                    }
                    .padding(.horizontal)
                    .offset(y: screenHeight*0.08/2)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Spacer()
                    
                    Text("\(patientData?.firstName ?? "") \(patientData?.lastName ?? "")")                                    .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Last scan: \(formattedDate(patientData?.lastScan))")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(width:screenWidth*0.9, alignment: .leading)
                //.background(Color.pink)
            }
            .edgesIgnoringSafeArea(.top)
            .frame(height: screenHeight * 0.20)
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 10)
                .padding(.horizontal,0)
        }
    }
}

struct FloatingButton: View {
    var action: () -> Void
    let screenHeight = UIScreen.main.bounds.height
    var body: some View {
        
        Button(action: action) {
            Text("Scan now")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            Image("scanBtn")
                .resizable()
                .scaledToFit()
                .frame(width: screenHeight * 0.04, height: screenHeight * 0.04)
        }
    }
}

struct ProfileInfoRow: View {
    var title: String
    var value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) { // Keep left alignment
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.gray)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.black)
        }
        .padding(.horizontal, 10)
    }
}
// Preview
struct PatientProfileView_Previews: PreviewProvider {
    static var previews: some View {
        PatientProfileView(patient: .previewData)
    }
}

extension PatientData {
    static var previewData: PatientData {
        PatientData(
            id: 1, // Corrected from from
            totalOrders: 0, // Required field
            imageUrl: nil,
            orderId: 1001, // Some dummy order ID
            entryDate: "2025-03-27",
            bld: nil,
            patientId: 123,
            shoeSize: "9 inch", // Matches struct
            date: nil,
            providerAccount: 567,
            officeLocation: "New York Clinic",
            isLeft: nil,
            isRight: nil,
            isBl: nil,
            other: nil,
            additionalInstructions: nil,
            completeDate: nil,
            status: "Pending",
            createdDate: "2025-03-27",
            createdBy: nil,
            modifyDate: nil,
            modifyBy: nil,
            patientLastName: "Smith",
            patientFirstName: "John", // Matches struct
            orderCreateBy: nil,
            completionDate: nil,
            practiceName: nil,
            trackingNumber: nil,
            shippedDate: nil,
            deliveryDate: nil,
            sex: "Male", // Corrected from gender
            foamCast: nil,
            note: nil,
            inComplete: nil,
            attachmentUrl: nil,
            notepad: nil,
            cfoplus: nil,
            noCharge: nil,
            cfoscanPlus: nil,
            physicianID: nil,
            doctorName: nil
        )
    }
}
