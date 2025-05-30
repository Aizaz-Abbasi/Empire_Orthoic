import SwiftUI
import PDFKit
import WebKit

struct PDFFormViewer: View {
    @Binding var document: PDFDocument
    @Binding var isPresented: Bool
    @Binding var patient: PatientData?
    @Binding var patientData: OrderPatientProfile?
    @Binding var folderItem: ScanFolderItem?
    @State private var prefilledValues: [String: String] = [:]
    @Binding var footImage: UIImage?
    @Binding var heelLiftText: String?
    @Binding var notes: String?
    @Binding var prefilledCheckBoxes: [String: String]?
    
    var selectedDocumentId: Int?
    var documentURL: URL?
    @State private var hasChanges = false
    var onClose: ((OrderScans?, Bool,Bool) -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") {
                    onClose?(nil, false, false)
                    isPresented = false
                }
                .padding()
                Spacer()
                if(patient?.status == "Not Scanned" || patient?.status == "Scanned"){
                    Button("Save") {
                        savePDF()
                    }
                    .padding()
                    .disabled(!hasChanges)
                    .opacity(hasChanges ? 1 : 0.5)
                }
            }
            .background(Color(.systemGray6))
            PDFFormViewGPT(document: $document, hasChanges: $hasChanges, prefilledValues: prefilledValues)
                .edgesIgnoringSafeArea(.bottom)
                .onAppear {
                    // Pre-fill the form when the view appears
                    if let url = documentURL{
                        Task {
                            print("Loading image from URL")
                            await loadDocumentFromURL(url)
                        }
                    }else{
                        setupPrefferedValues()
                    }
                }
        }
    }
    
    private func loadDocumentFromURL(_ url: URL) async {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)  // Extract data from the tuple
            if let pdfDocument = PDFDocument(data: data) {
                document = pdfDocument
                hasChanges = true
            }
        } catch {
            print("Failed to download PDF: \(error)")
        }
    }
    
    
    func setupPrefferedValues() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let currentDateString = formatter.string(from: Date())
        let newValues = [
            "Patient": "\(patient?.patientFirstName ?? "") \(patient?.patientLastName ?? "")",
            "Sex": "\(patient?.sex ?? "")",
            "Date": currentDateString,
            "Provider": "None",
            "Location": "\(patientData?.address ?? "")",
            "Shoe Size": "\(patientData?.shoeSize ?? "")"
        ]
        if self.prefilledCheckBoxes == nil {
            self.prefilledCheckBoxes = [:]
        }
        if let heelLiftValue = heelLiftText, !heelLiftValue.isEmpty {
            print("Heel assign")
            self.prefilledValues["mm"] = heelLiftValue
        }
        if let notes = notes, !notes.isEmpty {
            print("Notes assign")
            self.prefilledValues["Note"] = notes
        }
        newValues.forEach { key, value in
            self.prefilledValues[key] = value
        }
        
        prefilledCheckBoxes?.forEach { key, value in
            self.prefilledValues[key] = value
        }
        print("prefilledCheckBoxes--->",prefilledCheckBoxes)
        //printAllCheckboxFieldNames()
        prefillForm()
    }
    
    private func highlightFormField(_ annotation: PDFAnnotation) {
        annotation.border = PDFBorder()
        //        annotation.border?.lineWidth = 2
        //        annotation.border?.style = .beveled
        annotation.backgroundColor = UIColor(Color(red: 221/255, green: 228/255, blue: 255/255))
        //annotation.color = .brown
        //annotation.interiorColor = .darkGray
        annotation.isHighlighted = true
        //annotation.markupType = .highlight
    }
    // Pre-fill the form with values
    private func prefillForm() {
        if prefilledValues.isEmpty {
            return
        }
        // Iterate through all pages and annotations
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            for annotation in page.annotations {
                // Only process editable form fields
                if !annotation.isReadOnly {
                    guard let fieldName = annotation.fieldName else { continue }
                    print("fieldName",fieldName)
                    if(fieldName == "5th" || fieldName == "1st"){
                        print("fieldName---->",fieldName)
                        print( prefilledValues[fieldName])
                        print("prefilledValues",prefilledValues)
                    }
                    if annotation.widgetFieldType != .button {
                        highlightFormField(annotation)
                    }
                    if let value = prefilledValues[fieldName] {
                        if annotation.widgetFieldType == .signature {
                            //print("value========>",value)
                        }
                        if annotation.widgetFieldType == .text {
                            switch fieldName.lowercased() {
                            case "date":
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateFormat = "M/dd/yyyy"
                                annotation.widgetStringValue = " \(dateFormatter.string(from: Date()))"
                            case "note":
                                annotation.widgetStringValue = value + ""
                            case "mm":
                                annotation.widgetStringValue = "\(value)"
                            default:
                                annotation.widgetStringValue = value
                            }
                        } else if annotation.widgetFieldType == .button {
                            print("fieldName",fieldName)
                            if isImageField(fieldName), let image = footImage {
                                addImageAnnotation(image: image, on: page, in: annotation.bounds)
                            } else  if ["yes", "true", "1", "on", "checked"].contains(value.lowercased()) {
                                setCheckboxToCheckedState(annotation)
                            } else {
                                annotation.buttonWidgetState = .offState
                                print(".button------2")
                            }
                        } else if annotation.widgetFieldType == .choice {
                            annotation.widgetStringValue = value
                            
                        }
                        // Mark that we have changes
                        hasChanges = true
                    }
                }
            }
        }
    }
    
    private func findExistingImageAnnotation(on page: PDFPage, in bounds: CGRect) -> ImageStampAnnotation? {
        for existingAnnotation in page.annotations {
            if let imageAnnotation = existingAnnotation as? ImageStampAnnotation,
               imageAnnotation.bounds == bounds {
                return imageAnnotation
            }
        }
        return nil
    }
    
    private func isImageField(_ fieldName: String) -> Bool {
        //print("fieldName",fieldName)
        //print("fieldName---->",fieldName.lowercased().contains("signature") || fieldName.lowercased().contains("image"))
        return fieldName.lowercased().contains("signature") || fieldName.lowercased().contains("image")
    }
    
    private func printAllCheckboxFieldNames() {
        for pageIndex in 0..<document.pageCount {
            guard let page = document.page(at: pageIndex) else { continue }
            
            for annotation in page.annotations {
                if annotation.widgetFieldType == .button,
                   let fieldName = annotation.fieldName {
                    print("🟩 Checkbox Field Name: \(fieldName)")
                }
                if annotation.widgetFieldType == .choice,
                   let fieldName = annotation.fieldName {
                    print("🟩 Checkbox Choice Name: \(fieldName)")
                }
            }
        }
    }
    
    private func addImageAnnotation(image: UIImage, on page: PDFPage, in bounds: CGRect) {
        print("ImageStampAnnotation===============>")
        let annotation = ImageStampAnnotation(bounds: bounds, image: image)
        page.addAnnotation(annotation)
    }
    
    
    // Helper function to properly set checkbox to checked state
    private func setCheckboxToCheckedState(_ annotation: PDFAnnotation) {
        let exportValue = annotation.value(forAnnotationKey: .widgetValue) as? String
        let knownStates = annotation.buttonWidgetStateString.components(separatedBy: ",")
        
        if let onState = knownStates.first(where: { $0.lowercased() != "off" }) {
            annotation.buttonWidgetState = .onState
            annotation.buttonWidgetStateString = onState
            annotation.setValue(onState, forAnnotationKey: .widgetValue) // Explicitly set export value
        } else {
            annotation.buttonWidgetState = .onState
        }
        // Force UI refresh
        if let page = annotation.page {
            page.removeAnnotation(annotation)
            page.addAnnotation(annotation)
        }
    }
    
    private func savePDF() {
        // Implement your save logic here
        if let data = document.dataRepresentation() {
            let fileManager = FileManager.default
            let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let saveURL = docDir.appendingPathComponent("SavedDocument.pdf")
            var  documentId: Int? = nil
            if(documentURL == nil){
                documentId = nil
            }else{
                documentId = selectedDocumentId
            }
            print("Updating Document",documentId)
            do {
                try data.write(to: saveURL)
                print("Document saved at: \(saveURL)")
                ScansService.shared.uploadOrderDocument(
                    orderId: patient?.orderId ?? 0,
                    folderId: folderItem?.folderId,
                    documentId:documentId,
                    orderStatus: patientData?.status ?? "Not Scanned",
                    fileURL: saveURL,
                    documentType:"document"
                ) { result in
                    switch result {
                    case .success(let response):
                        print("✅ Upload pdf successful: \(response.data)")
                        guard let data = response.data else { return }
                        if let url = documentURL {
                            onClose?(data, true,true)
                        }else{
                            onClose?(data, false,true)
                        }
                        isPresented = false
                    case .failure(let error):
                        print("❌ Upload failed: \(error.localizedDescription)")
                    }
                }
                hasChanges = false
            } catch {
                print("Error saving PDF: \(error)")
            }
        }
    }
}

struct PDFFormViewGPT: UIViewRepresentable {
    @Binding var document: PDFDocument
    @Binding var hasChanges: Bool
    var prefilledValues: [String: String]
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.delegate = context.coordinator
        
        // Enable form editing explicitly
        if let document = pdfView.document {
            // This forces the document into form editing mode
            for i in 0..<document.pageCount {
                if let page = document.page(at: i) {
                    for annotation in page.annotations {
                        if annotation.isKind(of: PDFAnnotation.self) &&
                            (annotation.widgetFieldType == .choice || annotation.widgetFieldType == .text || annotation.widgetFieldType == .button) {
                            annotation.isReadOnly = false
                            
                            // Fix checkbox appearance for button type annotations
                            //                            if annotation.widgetFieldType == .button && annotation.widgetControlType == .checkBoxControl {
                            //                                // Configure the checkbox to have proper states
                            //                                configureCheckbox(annotation)
                            //                            }
                        }
                    }
                }
            }
        }
        setupObservers(for: pdfView, context: context)
        return pdfView
    }
    
    private func configureCheckbox(_ annotation: PDFAnnotation) {
        // Some PDFs might have checkboxes with custom state names
        // This ensures we properly configure them to show ticks instead of dashes
        
        let stateString = annotation.buttonWidgetStateString
        print("Checkbox \(annotation.fieldName ?? "unknown") states: \(stateString)")
        let states = stateString.components(separatedBy: ",")
        if states.contains("Yes") {
            annotation.buttonWidgetStateString = "Yes"
        } else if states.contains("On") {
            annotation.buttonWidgetStateString = "On"
        } else if states.count > 0 && states[0] != "Off" {
            // Use the first non-off state
            annotation.buttonWidgetStateString = states[0]
        } else {
            // Default to standard state
            annotation.buttonWidgetState = .onState
        }
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        pdfView.document = document
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(hasChanges: $hasChanges)
    }
    
    private func setupObservers(for pdfView: PDFView, context: Context) {
        guard let document = pdfView.document else { return }
        
        for pageIndex in 0..<document.pageCount {
            if let page = document.page(at: pageIndex) {
                for annotation in page.annotations {
                    context.coordinator.setupObservation(for: annotation)
                }
            }
        }
    }
    
    class Coordinator: NSObject, PDFViewDelegate {
        @Binding var hasChanges: Bool
        private var observations = [NSKeyValueObservation]()
        
        init(hasChanges: Binding<Bool>) {
            self._hasChanges = hasChanges
        }
        
        func setupObservation(for annotation: PDFAnnotation) {
            // Observe text field changes
            if annotation.widgetFieldType == .text {
                let observation = annotation.observe(\.widgetStringValue) { [weak self] _, _ in
                    self?.hasChanges = true
                }
                observations.append(observation)
            }
            // Observe button/checkbox changes
            else if annotation.widgetFieldType == .button {
                let observation = annotation.observe(\.buttonWidgetState) { [weak self] annotation, _ in
                    self?.hasChanges = true
                    
                    // Fix checkbox states when they change
                    if annotation.widgetControlType == .checkBoxControl {
                        // Only fix if it's in the middle state (showing a dash)
                        if annotation.buttonWidgetState == .mixedState {
                            // Force it to on state to show a tick
                            DispatchQueue.main.async {
                                let stateString = annotation.buttonWidgetStateString
                                let states = stateString.components(separatedBy: ",")
                                // Find a non-Off state to use
                                for state in states where state != "Off" {
                                    annotation.buttonWidgetStateString = state
                                    return
                                }
                                annotation.buttonWidgetState = .onState
                            }
                        }
                    }
                }
                observations.append(observation)
                let stateObservation = annotation.observe(\.buttonWidgetStateString) { [weak self] _, _ in
                    self?.hasChanges = true
                }
                observations.append(stateObservation)
            }
            // Add observation for choice fields
            else if annotation.widgetFieldType == .choice {
                let observation = annotation.observe(\.widgetStringValue) { [weak self] _, _ in
                    self?.hasChanges = true
                }
                observations.append(observation)
            }
        }
        
        // Handle new annotations being added
        func pdfView(_ pdfView: PDFView, didAddAnnotation annotation: PDFAnnotation, forPage page: PDFPage) {
            setupObservation(for: annotation)
            hasChanges = true
        }
        
        // Handle annotations being removed
        func pdfView(_ pdfView: PDFView, didRemoveAnnotation annotation: PDFAnnotation, forPage page: PDFPage) {
            hasChanges = true
        }
        
        // Handle checkbox clicks to ensure they show ticks instead of dashes
        func pdfView(_ view: PDFView, didClickAt point: CGPoint) {
            guard let page = view.page(for: point, nearest: true) else { return }
            
            // Convert the view point to page coordinates
            let pagePoint = view.convert(point, to: page)
            
            for annotation in page.annotations {
                // Check for checkbox annotations
                if annotation.widgetFieldType == .button,
                   annotation.widgetControlType == .checkBoxControl,
                   annotation.bounds.contains(pagePoint) {
                    
                    // Wait a bit for system to update before forcing our own change
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if annotation.buttonWidgetState == .mixedState {
                            let stateString = annotation.buttonWidgetStateString
                            
                            if stateString.contains(",") {
                                let states = stateString.components(separatedBy: ",")
                                if let firstValidState = states.first(where: { $0 != "Off" }) {
                                    annotation.buttonWidgetStateString = firstValidState
                                } else {
                                    annotation.buttonWidgetState = .onState
                                }
                            } else if stateString.contains("Yes") {
                                annotation.buttonWidgetStateString = "Yes"
                            } else {
                                annotation.buttonWidgetState = .onState
                            }
                        }
                    }
                    
                    break // Only handle the first matching checkbox
                }
            }
        }
        
        // Clean up observations
        deinit {
            observations.forEach { $0.invalidate() }
        }
    }
}

// Helper function to print form field names and states (for debugging)
func printPDFFormFieldNames(document: PDFDocument) {
    for pageIndex in 0..<document.pageCount {
        guard let page = document.page(at: pageIndex) else { continue }
        
        for annotation in page.annotations {
            if let fieldName = annotation.fieldName {
                print("Field: \(fieldName), Type: \(annotation.widgetFieldType.rawValue)")
                
                // For button widgets, also print the control type and states
                if annotation.widgetFieldType == .button {
                    print("  - Control Type: \(annotation.widgetControlType.rawValue)")
                    print("  - Current State: \(annotation.buttonWidgetState.rawValue)")
                    let states = annotation.buttonWidgetStateString
                    if !states.isEmpty {
                        print("  - State String: \(states)")
                    }
                }
            }
        }
    }
}



//
class ImageStampAnnotation: PDFAnnotation {
    private var image: UIImage
    
    init(bounds: CGRect, image: UIImage) {
        self.image = image
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        super.draw(with: box, in: context)
        
        guard let cgImage = image.cgImage else { return }
        context.saveGState()
        // Convert annotation bounds to the PDF coordinate system
        let rect = self.bounds
        // No flipping — just translate to the annotation's origin
        context.translateBy(x: rect.origin.x, y: rect.origin.y)
        // Draw the image as-is (no vertical flip)
        let imageRect = CGRect(origin: .zero, size: rect.size)
        context.draw(cgImage, in: imageRect)
        context.restoreGState()
    }
    func updateImage(_ newImage: UIImage) {
        self.image = newImage
        // Force redraw
        self.willChangeValue(for: \.bounds)
        self.didChangeValue(for: \.bounds)
    }
    
}


extension UIImage {
    var pdfWidgetAnnotationValue: Any? {
        guard let cgImage = self.cgImage else { return nil }
        return cgImage
    }
}
