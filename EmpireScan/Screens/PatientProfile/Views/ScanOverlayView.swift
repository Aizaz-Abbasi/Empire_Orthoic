//  ScanOverlayView.swift
//  EmpireScan
//  Created by MacOK on 09/04/2025.
import Foundation
import SwiftUI
import PhotosUI
struct ScanOverlayView: View {
    
    @Binding var isPresented: Bool
    @Binding var isEditable: Bool
    @Binding var folderItem: ScanFolderItem?
    @State var patient: PatientData?
    @Binding var patientData: OrderPatientProfile?
    
    @State private var rightPreviewURL: URL?
    @State private var leftPreviewURL: URL?
    @State private var rightMeshURL: URL?
    @State private var leftMeshURL: URL?
    @State var shouldAutoSubmit: Bool = false
    
    @State private var rightStlURL: URL?
    @State private var leftStlURL: URL?
    var onDismiss: ((ScanFolderItem) -> Void)? = nil
    var submitOrder: ((ScanFolderItem,PatientData?,Bool) -> Void)? = nil
    @State private var showPDF = false
    @State private var selectedPDF: PDFSelection?
    @State private var isImageFullScreen = false
    @State private var isLoading = true
    @State private var didLoadRight = false
    @State private var didLoadLeft = false
    
    //IMAGE UPLOAD
    @State private var showPicker = false
    @State private var selectedImage: UIImage?
    @State private var sourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedItem: PhotosPickerItem?
    @State private var isToastVisible = false
    @State private var toastMessage = ""
    
    //ORDER FORM
    @State private var showOrthoticWorkOrder = false
    @State private var prefilledCheckBoxes: [String: String]? = nil
    
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    
    struct PDFSelection {
        let url: URL
        let documentId: Int
    }
    
    var _meshViewController: MeshViewController!
    var _options = Options()
    
    @State private var pdfDocument: PDFDocument = {
        if let url = Bundle.main.url(forResource: "blank_order_form", withExtension: "pdf") {
            print("Document found")
            return PDFDocument(url: url)!
        }
        print("Document not found")
        fatalError("PDF document could not be loaded")
    }()
    
    var body: some View {
        
        return ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                
                VStack(alignment: .leading, spacing: 20) {
                    headerView
                        .id(folderItem?.scans.count)
                    picturesSection
                    orderFormsSection
                }
                .background(Color.black)
                
                .padding(.bottom, 20)
                .padding()
            }
            .cornerRadius(20)
            .toast(isShowing: $isToastVisible, message: toastMessage)
            if isLoading {
                if shouldAutoSubmit{
                    loadingOverlay(text: "Submitting order. This may take a moment...")
                }else{
                    loadingOverlay()
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .transition(.move(edge: .bottom))
        .animation(.easeInOut, value: isPresented)
        .zIndex(999)
        .sheet(isPresented: $showPicker) {
            ImagePicker(sourceType: sourceType, selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                handleSelectedImage(image) // your function
            }
        }
        .fullScreenCover(isPresented: $showPDF) {
            Group {
                if selectedPdfUrl == nil {
                    PDFFormViewer(
                        document:  $pdfDocument,
                        isPresented: $showPDF,
                        patient: $patient,
                        patientData: $patientData,
                        folderItem: $folderItem,
                        footImage: .constant(nil),
                        heelLiftText: .constant(nil),
                        notes:.constant(nil),
                        prefilledCheckBoxes: $prefilledCheckBoxes,
                        onClose: { pdfItem, code,isChaged  in
                            if  let pdfItem = pdfItem{
                                handlePDFFormClosed(pdfItem: pdfItem, isUpdated: code)
                            }
                            selectedPdfUrl = nil
                            selectedDocumentId = nil
                        }
                    )
                } else {
                    PDFFormViewer(
                        document: $pdfDocument,
                        isPresented: $showPDF,
                        patient: $patient,
                        patientData: $patientData,
                        folderItem: $folderItem,
                        footImage: .constant(nil),
                        heelLiftText: .constant(nil),
                        notes:.constant(nil),
                        prefilledCheckBoxes: $prefilledCheckBoxes,
                        selectedDocumentId: selectedDocumentId,
                        documentURL: selectedPdfUrl,
                        onClose: { pdfItem, code,isChaged  in
                            if  let pdfItem = pdfItem{
                                handlePDFFormClosed(pdfItem: pdfItem, isUpdated: code)
                            }
                            selectedPdfUrl = nil
                            selectedDocumentId = nil
                        }
                    )
                }
            }.id(selectedPDF?.documentId)
        }
        .onReceive(NotificationCenter.default.publisher(for: .scanUploadedSuccessfully)) { notification in
            if let newScan = notification.object as? OrderScans {
                print("📦 Received scanUploadedSuccessfully with data:", newScan)
                if var folder = folderItem {
                    if let index = folder.scans.firstIndex(where: { $0.footType == newScan.footType }) {
                        folder.scans[index] = newScan
                    } else {
                        folder.scans.append(newScan)
                    }
                    folderItem = folder
                }
            } else {
                print("⚠️ Failed to cast notification object to OrderScans")
            }
        }
    }
    
    private func handlePDFFormClosed(pdfItem: OrderScans, isUpdated: Bool) {
        if !isUpdated {
            appendPdf(pdfItem: pdfItem)
        } else {
            updateSelectedPdf(pdfItem: pdfItem)
        }
    }
    
    private func appendPdf(pdfItem: OrderScans) {
        guard var item = folderItem else { return }
        item.documents.append(pdfItem)
        folderItem = item
        print("✅ Appended new document: \(pdfItem)")
    }
    
    private func updateSelectedPdf(pdfItem: OrderScans) {
        guard var item = folderItem else { return }
        if let index = item.documents.firstIndex(where: { $0.documentId == pdfItem.documentId }) {
            item.documents[index] = pdfItem
            folderItem = item
            print("🔁 Updated existing document at index \(index): \(pdfItem)")
        } else {
            print("⚠️ Document to update not found. Consider appending it instead.")
        }
    }
    func handleSelectedImage(_ image: UIImage) {
        print("Image selected or captured!")
        saveImage(image)
    }
    
    private var headerView: some View {
        
        //        return
        VStack {
            let rightScan = folderItem?.scans.first { $0.footType?.lowercased() == "right" }
            let leftScan = folderItem?.scans.first { $0.footType?.lowercased() == "left" }
            
            HStack(alignment: .top) {
                // Left Side: Title and Scan Items
                VStack(alignment: .leading, spacing: 16) {
                    Text("Scans")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(.leading)
                    
                    HStack(spacing: 20) {
                        // Right Scan
                        ScanItem(
                            title: "Right",
                            image: rightPreviewURL == nil ? "Right_Foot" : nil,
                            imageURL: rightPreviewURL,
                            showDescriptionIcon: rightScan?.description != nil && !rightScan!.description.isEmpty,
                            onButtonClick: {
                                print("Right Button was clicked!")
                                navigateToScanner(footType: "Right")
                            }
                        )
                        .onAppear {
                            DispatchQueue.main.async {
                                isLoading = true
                                didLoadRight = false
                                if let rightScan = rightScan {
                                    downloadAndExtractPreview(from: rightScan.attachmentUrl, identifier: "left_model") { url, meshUrl, stlUrl in
                                        self.rightPreviewURL = url
                                        print("left---->",stlUrl)
                                        self.rightMeshURL = meshUrl
                                        self.rightStlURL = stlUrl
                                        didLoadRight = true
                                        checkIfDoneLoading()
                                    }
                                } else {
                                    didLoadRight = true
                                    checkIfDoneLoading()
                                }
                            }
                        }
                        
                        // Left Scan
                        ScanItem(
                            title: "Left",
                            image: leftPreviewURL == nil ? "Left_Foot" : nil,
                            imageURL: leftPreviewURL,
                            showDescriptionIcon: leftScan?.description != nil && !leftScan!.description.isEmpty,
                            onButtonClick: {
                                print("Left Button was clicked!")
                                navigateToScanner(footType: "Left")
                            }
                        )
                        .onAppear {
                            DispatchQueue.main.async {
                                isLoading = true
                                didLoadLeft = false
                                if let leftScan = leftScan {
                                    downloadAndExtractPreview(from: leftScan.attachmentUrl, identifier: "right_model") { url, meshUrl,stlUrl in
                                        print("right---->",stlUrl)
                                        self.leftPreviewURL = url
                                        self.leftMeshURL = meshUrl
                                        self.leftStlURL = stlUrl
                                        didLoadLeft = true
                                        checkIfDoneLoading()
                                    }
                                } else {
                                    didLoadLeft = true
                                    checkIfDoneLoading()
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                // Right Side: Buttons (❌, 📷, 📸)
                VStack(spacing: screenHeight * 0.02) {
                    // ❌ Close Button
                    Button(action: {
                        isPresented = false
                        if let folderItem = folderItem{
                            onDismiss?(folderItem)
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: screenHeight * 0.025, height: screenHeight * 0.025)
                            .padding(10)
                            .background(Color.white.opacity(0.3))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    if(isEditable){
                        // 📷 Photo Library Button
                        Button(action: {
                            sourceType = .photoLibrary
                            showPicker = true
                        }) {
                            Image(systemName: "photo.on.rectangle")
                                .resizable()
                                .scaledToFit()
                                .frame(width: screenHeight * 0.02, height: screenHeight * 0.02)
                                .padding(10)
                                .background(Color.white.opacity(0.3))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        // 📸 Camera Button
                        Button(action: {
                            sourceType = .camera
                            showPicker = true
                        }) {
                            Image(systemName: "camera")
                                .resizable()
                                .scaledToFit()
                                .frame(width: screenHeight * 0.02, height: screenHeight * 0.02)
                                .padding(10)
                                .background(Color.white.opacity(0.3))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                    }
                }
                .padding(.trailing, 12)
                .offset(y: -screenHeight * 0.1) // Moves the entire column of buttons slightly up
            }
            .padding(.vertical)
            .background(Color.black.opacity(0.2))
        }
        .padding(.top, screenHeight * 0.1)
    }
    
    private var picturesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pictures")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if let documents = folderItem?.images {
                        ForEach(documents, id: \.documentId) { document in
                            if let url = URL(string: document.attachmentUrl) {
                                ZStack(alignment: .topTrailing) {
                                    Button(action: {
                                        print("Selected image URL: \(url)")
                                        selectedImageURL = url
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            isImageFullScreen = true
                                        }
                                    }) {
                                        AsyncImage(url: url) { phase in
                                            switch phase {
                                            case .empty:
                                                ProgressView()
                                                    .frame(width: 100, height: 140)
                                                    .background(Color.gray.opacity(0.2))
                                                    .cornerRadius(8)
                                            case .success(let image):
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                                    .frame(width: 100, height: 140)
                                                    .clipped()
                                                    .cornerRadius(8)
                                            case .failure:
                                                Image(systemName: "photo")
                                                    .frame(width: 100, height: 140)
                                                    .background(Color.gray)
                                                    .cornerRadius(8)
                                            @unknown default:
                                                EmptyView()
                                            }
                                        }
                                    }
                                    
                                    // Delete button
                                    if(isEditable){
                                        Button(action: {
                                            deleteImage(document)
                                        }) {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(.red)
                                                .background(Color.clear)
                                                .font(.system(size: 18, weight: .bold))
                                                .padding(4)
                                        }
                                    }
                                    
                                }
                                .frame(width: 100, height: 140)
                            }
                        }
                        
                    }
                }
                .padding(.horizontal)
            }
            .fullScreenCover(isPresented: $isImageFullScreen) {
                if let imageURL = selectedImageURL {
                    FullScreenImageView(imageURL: imageURL, isPresented: $isImageFullScreen)
                } else {
                    ZStack(alignment: .topTrailing) {
                        Button(action: { isImageFullScreen = false }) {
                            Text("No image available")
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        
                        Button(action: { isImageFullScreen = false }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.gray)
                                .padding(16)
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Color.white)
                }
            }
        }
    }
    
    private var orderFormsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Order Forms")
                    .font(.title2)
                    .foregroundColor(.white)
                Spacer()
                if(isEditable){
                    Button(action: {
                        //showPDF = true
                        showOrthoticWorkOrder = true
                    }) {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.white)
                    }
                }else{
                    Text("View Only")
                        .foregroundColor(.white)
                }
            }.padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    if(isEditable){
                        if let folderItem = folderItem, folderItem.documents.count > 0 {
                        }else{
                            Button(action: {
                                showOrthoticWorkOrder = true
                            }) {
                                Rectangle()
                                    .fill(Color.white)
                                    .frame(width: 100, height: 140)
                                    .cornerRadius(8)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "plus")
                                                .font(.title2)
                                            Text("TAP TO ADD")
                                                .font(.system(size: 12))
                                        }
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                    }
                    
                    if let documents = folderItem?.documents {
                        ForEach(documents, id: \.documentId) { document in
                            if let url = URL(string: document.attachmentUrl) {
                                ZStack(alignment: .topTrailing) {
                                    // Main PDF preview button
                                    Button(action: {
                                        selectedDocumentId = document.documentId
                                        selectedPdfUrl = url
                                        self.selectedPDF = PDFSelection(url: url, documentId: document.documentId)
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            self.showPDF = true
                                        }
                                    }) {
                                        ListPdfView(url: url)
                                            .frame(width: 100, height: 140)
                                            .cornerRadius(8)
                                            .clipped()
                                    }
                                    if(isEditable){
                                        // Overlayed trash button
                                        Button(action: {
                                            deletePdf(document)
                                        }) {
                                            Image(systemName: "trash.fill")
                                                .foregroundColor(.red)
                                                .font(.system(size: 14, weight: .bold))
                                                .padding(6)
                                                .background(Color.white.opacity(0.9))
                                                .clipShape(Circle())
                                                .shadow(radius: 1)
                                        }
                                        .padding(6) // position padding inside ZStack
                                    }
                                }
                                .frame(width: 100, height: 140)
                            }
                        }
                    }
                }
                .padding(.leading, UIScreen.main.bounds.width * 0.05)
            }
            if(isEditable){
                if(hasBothScansAndOrderForm(in: folderItem)){
                    bottomButtons()
                }
            }
        }
        .fullScreenCover(isPresented: $showOrthoticWorkOrder) {
            NavigationView {
                OrthoticWorkOrderPart1(folderItem:$folderItem, patient:patient, patientData: $patientData, orderId: patient?.orderId ?? 0, orderStatus: patient?.status ?? "Not Scanned", onSubmit: {pdfItem,isUpdated in
                    showOrthoticWorkOrder = false
                    if let pdfItem = pdfItem{
                        appendPdf(pdfItem: pdfItem)
                    }
                    //                        submitOrderAPI()
                })
                .navigationBarItems(leading: Button("Cancel") {
                    showOrthoticWorkOrder = false
                })
            }
        }
    }
    
    @ViewBuilder
    func bottomButtons() -> some View {
        let screenWidth = UIScreen.main.bounds.width
        let buttonWidth = (screenWidth * 0.9 - 10) / 2 // 10 is the spacing between buttons
        
        HStack(spacing: 10) {
            Button(action: {
                
                submitOrderAPI()
                // navigateToScannerVC()
            }) {
                HStack {
                    Image(systemName: "viewfinder")
                        .foregroundColor(Colors.primary)
                    Text("Submit now")
                }
                .font(.system(size: 16, weight: .bold))
                .frame(width: buttonWidth, height: 50)
                .background(Colors.white)
                .foregroundColor(Colors.primary)
                .overlay(
                    Capsule().stroke(Colors.primary, lineWidth: 2)
                )
                .clipShape(Capsule())
            }
            
            Button(action: {
                print("Save Profile Tapped")
                isPresented = false
                if let folderItem = folderItem{
                    onDismiss?(folderItem)
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text("Save for later")
                }
                .font(.system(size: 16, weight: .bold))
                .frame(width: buttonWidth, height: 50)
                .background(Colors.primary)
                .foregroundColor(Colors.white)
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, (screenWidth - (buttonWidth * 2 + 10)) / 2)
        .padding(.bottom, 20)
    }
    
//    private var loadingOverlay: some View {
//        Color.black.opacity(0.6)
//            .ignoresSafeArea()
//            .overlay(
//                ProgressView()
//                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
//                    .scaleEffect(1.5)
//                    .padding()
//                    .background(Color.black.opacity(1))
//                    .cornerRadius(12)
//            )
//    }
    
    private func loadingOverlay(text: String? = nil) -> some View {
        Color.black.opacity(0.6)
            .ignoresSafeArea()
            .overlay(
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)

                    if let text = text {
                        Text(text)
                            .foregroundColor(.white)
                            .font(.body)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .background(Color.black.opacity(1))
                .cornerRadius(12)
            )
    }
    
    func checkIfDoneLoading() {
        print("checkIfDoneLoading ",didLoadRight,didLoadLeft)
        if didLoadRight && didLoadLeft {
            isLoading = false
            print("checkIfDoneLoading false")
            checkAndAutoSubmit()
        }else{
            print("checkIfDoneLoading true")
        }
    }
    
     func checkAndAutoSubmit() {
            // Only auto-submit if both STL URLs are available and the autoSubmit flag is true
            if shouldAutoSubmit{
                if let leftUrl = leftStlURL, let rightUrl = rightStlURL {
                    print("Auto-submitting order with both STL files ready")
                    submitOrderAPI()
                    shouldAutoSubmit = false
                }
            }
    }
    
    func hasBothScansAndOrderForm(in folderItem: ScanFolderItem?) -> Bool {
        print("hasBothScansAndOrderForm")
        guard let scans = folderItem?.scans, !scans.isEmpty,
              let documents = folderItem?.documents else {
            return false
        }
        
        let hasLeft = scans.contains { $0.footType?.lowercased() == "left" }
        let hasRight = scans.contains { $0.footType?.lowercased() == "right" }
        print("documents",documents)
        let hasOrderForm = documents.count > 0
        return hasLeft && hasRight && hasOrderForm
    }
    
    
    private func deleteImage(_ document: OrderScans) {
        
        ScansService.shared.deleteAttachment(documentId:document.documentId, orderStatus: patient?.status ?? "Not Scanned") { result in
            switch result {
            case .success(let response):
                guard var currentFolder = folderItem else { return }
                currentFolder.images.removeAll { $0.documentId == document.documentId }
                folderItem = currentFolder
                print("deleteImage",response)
            case .failure(let error):
                print("Delete failed with error:", error.localizedDescription)
            }
        }
    }
    
    private func deletePdf(_ document: OrderScans) {
        
        ScansService.shared.deleteAttachment(documentId:document.documentId, orderStatus: patient?.status ?? "Not Scanned") { result in
            switch result {
            case .success(let response):
                guard var currentFolder = folderItem else { return }
                currentFolder.documents.removeAll { $0.documentId == document.documentId }
                folderItem = currentFolder
                print("deleteImage",response)
            case .failure(let error):
                print("Delete failed with error:", error.localizedDescription)
            }
        }
    }
    
    private func saveImage(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to data")
            return
        }
        let fileManager = FileManager.default
        let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageURL = docDir.appendingPathComponent("CapturedImage.jpg")
        
        do {
            try imageData.write(to: imageURL)
            print("📸 Image saved at: \(imageURL)")
            isLoading = true
            ScansService.shared.uploadOrderDocument(
                orderId: patient?.orderId ?? 0,
                folderId: folderItem?.folderId,
                orderStatus: patient?.status ?? "Not Scanned",
                fileURL: imageURL,
                documentType: "image"
            ) { result in
                isLoading = false
                switch result {
                case .success(let response):
                    self.toastMessage = "Image saved and uploaded"
                    self.isToastVisible = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.isToastVisible = false
                    }
                    guard let data = response.data else { return }
                    appendImage(imageItem: data)
                case .failure(let error):
                    print("❌ Upload failed: \(error.localizedDescription)")
                }
            }
        } catch {
            print("❌ Error saving image: \(error)")
        }
    }
    
    private func appendImage(imageItem: OrderScans) {
        guard var item = folderItem else { return }
        item.images.append(imageItem)
        folderItem = item
        print("✅ Appended new image: \(imageItem)")
    }
    
    private func submitOrderAPI() {
        print("submitOrderAPI")
        isLoading = true
        let mergedURL = FileManager.default.temporaryDirectory.appendingPathComponent("merged_output.stl")
        do {
            if let leftStlURL = leftStlURL,let rightStlURL = rightStlURL{
                try mergeBinarySTLFiles(leftURL: leftStlURL, rightURL: rightStlURL, outputURL: mergedURL)
            }
            
            ScansService.shared.uploadScanResult(
                orderId:patient?.orderId ?? 0,
                description: "",
                footType: "Merged",
                scanType: "STL",
                folderId: folderItem?.folderId,
                orderStatus:patient?.status ?? "Scanned",
                meshFileURL: mergedURL
            ) { result in
                
                switch result {
                case .success(let response):
                    print("📩 Message STL: \(response.message)")
                    let submitRequest = SubmitOrder(orderId: patient?.orderId ?? 0)
                    PatientsService.shared.postSubmitOrder(requestBody: submitRequest) { result in
                        isLoading = false
                        switch result {
                        case .success(let apiResponse):
                            print("postSubmitOrder========>",apiResponse)
                            if let folderItem = folderItem, let data = apiResponse.data{
                                print("postSubmitOrder---->IN",apiResponse)
                                isPresented = false
                                submitOrder?(folderItem,nil, true)
                            }
                            
                        case .failure(let error):
                            print("postSubmitOrder error",error)
                        }
                    }
                case .failure(let error):
                    print("❌ Upload STL failed: \(error.localizedDescription)")
                }
            }
        } catch {
            print("❌ Failed to merge STL files: \(error)")
        }
    }
    
    // Function to handle navigation when button is clicked
    func navigateToScanner(footType: String) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Could not find root view controller")
            return
        }
        
        let scan = folderItem?.scans.first { $0.footType?.lowercased() == footType.lowercased() }
        let meshURL = (footType.lowercased() == "right") ? rightMeshURL : leftMeshURL
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        print("navigateToScanner")
        if scan == nil && isEditable {
            let sensorType = UserDefaults.standard.string(forKey: "selectedSensorType")
            print("sensorType",sensorType)
            if(sensorType == "Structure"){
                guard let fixedOrientationVC = storyboard.instantiateViewController(withIdentifier: "FixedOrientationStructure") as? FixedOrientationStructure,
                      let viewController = fixedOrientationVC.viewControllers.first as? StructureViewController else {
                    print("❌ Could not instantiate FixedOrientationStructure or inner ViewController")
                    return
                }
                
                // Pass necessary data
                viewController.footType = footType
                viewController.orderId = patient?.orderId
                viewController.folderId = folderItem?.folderId
                viewController.scanType = scan?.scanType
                viewController.orderStatus = patient?.status
                fixedOrientationVC.modalPresentationStyle = .fullScreen
                topController.present(fixedOrientationVC, animated: true)
            }else{
                guard let fixedOrientationVC = storyboard.instantiateViewController(withIdentifier: "FixedOrientationController") as? FixedOrientationController,
                      let viewController = fixedOrientationVC.viewControllers.first as? ViewController else {
                    print("❌ Could not instantiate FixedOrientationController or inner ViewController")
                    return
                }
                // Pass necessary data
                viewController.footType = footType
                viewController.orderId = patient?.orderId
                viewController.folderId = folderItem?.folderId
                viewController.scanType = scan?.scanType
                viewController.orderStatus = patient?.status
                fixedOrientationVC.modalPresentationStyle = .fullScreen
                topController.present(fixedOrientationVC, animated: true)
            }

            
        } else {
            guard let meshURL else {
                print("❌ Mesh URL is nil for footType: \(footType)")
                return
            }
            guard let navController = storyboard.instantiateViewController(withIdentifier: "MeshNavigationController") as? UINavigationController,
                  let meshVC = navController.topViewController as? MeshViewVC else {
                print("❌ Failed to instantiate MeshNavigationController or MeshViewVC")
                return
            }
            print("navigateToScanner 2",scan?.scanType ?? "")
            meshVC.modelURL = meshURL
            meshVC.footType = footType
            meshVC.orderId = patient?.orderId
            meshVC.folderId = folderItem?.folderId
            meshVC.scanType = scan?.scanType
            meshVC.orderStatus = patient?.status
            meshVC.documentId = scan?.documentId
            meshVC.isEditable = isEditable
            meshVC.descriptionText = scan?.description ?? ""
            meshVC.onScreenShot = { scan in
                appendImage(imageItem: scan)
            }
            topController.present(navController, animated: true)
            print("navigateToScanner end")
        }
    }
    
    func mergeBinarySTLFiles(leftURL: URL, rightURL: URL, outputURL: URL, rightModelXOffset: Float = 0.25) throws {
        func readTriangles(from url: URL, offsetX: Float = 0.0) throws -> [Data] {
            let data = try Data(contentsOf: url)
            guard data.count >= 84 else { throw NSError(domain: "STL", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid STL file size"]) }

            let triangleCount = data.subdata(in: 80..<84).withUnsafeBytes { $0.load(as: UInt32.self) }
            let expectedSize = 84 + Int(triangleCount) * 50
            guard data.count == expectedSize else { throw NSError(domain: "STL", code: 2, userInfo: [NSLocalizedDescriptionKey: "File size doesn't match triangle count"]) }

            var triangles: [Data] = []

            for i in 0..<triangleCount {
                let start = 84 + Int(i) * 50
                var triangle = data.subdata(in: start..<(start + 50))
                // Offset the vertex positions if needed
                if offsetX != 0 {
                    var mutableTriangle = triangle
                    for j in 0..<3 { // 3 vertices
                        let vertexOffset = 12 + j * 12 // Normal is first 12 bytes
                        let xRange = vertexOffset..<(vertexOffset + 4)
                        let x = mutableTriangle.subdata(in: xRange).withUnsafeBytes { $0.load(as: Float.self) }
                        var newX = x + offsetX
                        let newXData = Data(bytes: &newX, count: 4)
                        mutableTriangle.replaceSubrange(xRange, with: newXData)
                    }
                    triangles.append(mutableTriangle)
                } else {
                    triangles.append(triangle)
                }
            }
            return triangles
        }

        let leftTriangles = try readTriangles(from: leftURL)
        let rightTriangles = try readTriangles(from: rightURL, offsetX: rightModelXOffset)
        let allTriangles = leftTriangles + rightTriangles
        let totalCount = UInt32(allTriangles.count)
        var mergedData = Data()

        let header = "Merged STL File".padding(toLength: 80, withPad: " ", startingAt: 0)
        mergedData.append(header.data(using: .ascii)!)

        var triangleCount = totalCount
        mergedData.append(Data(bytes: &triangleCount, count: 4))

        for triangle in allTriangles {
            mergedData.append(triangle)
        }
        
        try mergedData.write(to: outputURL)
        print("✅ Merged STL file written to: \(outputURL.path)")
    }
}

// MARK: - Subviews
struct ScanItem: View {
    let title: String
    let image: String?
    let imageURL: URL?
    let showDescriptionIcon: Bool
    let onButtonClick: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background image
            if let url = imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 150, height: 140)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 150, height: 140)
                            .clipped()
                    case .failure:
                        Image(systemName: "photo.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 100)
                            .foregroundColor(.gray)
                            .clipped()
                    @unknown default:
                        EmptyView()
                    }
                }
            } else if let image = image {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 120, height: 100)
                    .foregroundColor(Colors.primary)
                    .clipped()
            }
            
            // Description Icon (top-left)
            if showDescriptionIcon {
                VStack {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                        Spacer()
                    }
                    Spacer()
                }
                .frame(width: 150, height: 140)
            }
            
            // Title at bottom
            Text(title)
                .foregroundColor(.white)
                .bold()
                .padding(6)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.5))
        }
        .frame(width: 150, height: 140)
        .cornerRadius(10)
        .clipped()
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white, lineWidth: 2)
        )
        .onTapGesture {
            onButtonClick()
        }
    }
}

struct LatestScanItem: View {
    let item: ScanFolderItem
    let title: String
    let date: String
    let isSelected: Bool
    
    private var hasBothScans: Bool {
        let hasLeft = item.scans.contains { $0.footType?.lowercased() == "left" }
        let hasRight = item.scans.contains { $0.footType?.lowercased() == "right" }
        return hasLeft && hasRight
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(scanTitle(for: item.scans))
                    .font(.system(size: 15, weight: .semibold))
                
                Text(item.scans.first?.scanType ?? "")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? .white : .black)
                
                Text(latestScanDateFormatted(from: item.scans))
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .gray)
            }
            Spacer()
            // ✅ or ❌ based on scan completeness
            Image(systemName: hasBothScans ? "checkmark.seal.fill" : "xmark.seal")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(hasBothScans ? .green : .red)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(isSelected ? Colors.primary : Color.white)
        .cornerRadius(10)
        .shadow(radius: isSelected ? 4 : 1)
    }
    
    func scanTitle(for scans: [OrderScans]) -> String {
        let footTypes = Set(scans.map { $0.footType?.lowercased() })
        
        if footTypes.contains("left") && footTypes.contains("right") {
            return "Foot, Both"
        } else if footTypes.contains("left") {
            return "Foot, Left"
        } else if footTypes.contains("right") {
            return "Foot, Right"
        } else {
            return "Foot"
        }
    }
    
    func latestScanDateFormatted(from scans: [OrderScans]) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS" // <== updated
        inputFormatter.locale = Locale(identifier: "en_US_POSIX")
        inputFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let latestDate = scans
            .compactMap { inputFormatter.date(from: $0.createDate) }
            .max()
        
        guard let date = latestDate else {
            return "No valid date"
        }
        // Format into string
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "yyyy-MM-dd"
        outputFormatter.timeZone = TimeZone.current
        
        return outputFormatter.string(from: date)
    }
}
