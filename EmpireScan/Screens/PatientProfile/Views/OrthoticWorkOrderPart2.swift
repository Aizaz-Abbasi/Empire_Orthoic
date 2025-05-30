import SwiftUI
import Combine

struct OrthoticWorkOrderPart2: View {
    // @Binding
    @Binding var folderItem: ScanFolderItem?
    @State var patient: PatientData?
    @Binding var patientData: OrderPatientProfile?
    
    let customFootOrthotics: [Option]
    let topCover: [Option]
    let extensionOptions: [Option]
    let modifications: [ModificationOption]
    var orderId: Int
    var orderStatus: String
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    var onSubmit: (OrderScans?, Bool) -> Void
    //PFD
    @State var prefilledValues: [String: String]? = nil
    @State private var workOrderOptions: [WorkOrderOption] = []
    @State private var otherOptions: [ModificationOption] = [
        ModificationOption(name: "UCBL"),
        ModificationOption(name: "Morton's Extension"),
        ModificationOption(name: "Gait Plate"),
        ModificationOption(name: "Arch Reinforcement"),
        ModificationOption(name: "Scaphoid Arch Pad"),
        ModificationOption(name: "Toe Filler")
    ]
    
    @State private var reverseMorton: Bool = false
    @State var heelLiftText: String?
    @State var toeFillerText: String?
    
    @State var notes: String?
    @StateObject private var heelLift = ModificationOption(name: "Heel Lift")
    @State private var gaitToInduce: String = ""
    @State private var metheadCutout: String = ""
    @State private var globeOrthotic: Bool = false
    private var screenSize = UIScreen.main.bounds.size
    @State private var isLoading = false
    @State private var showPDF = false
    @State private var showEditor = false
    @State var selectedImage:UIImage? = nil
    @State var selectedItem: MediaItem? = MediaItem(
        type: .image,
        image:  UIImage(named: "footImage"),
        video: nil,
        videoUrl: nil
    )
    @State private var isToastVisible = false
    @State private var toastMessage = ""
    @State private var pdfDocument: PDFDocument? = nil

    var body: some View {
        VStack {
            if isLoading {
                loadingOverlay
            }else{
                
                Form {
                    Section(header:
                                HStack {
                        Text("Other (+$10)")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("BL")
                            .frame(width: 50, alignment: .center)
                        // .background(Color.blue)
                        Text("Left")
                            .frame(width: 50, alignment: .center)
                        // .background(Color.red)
                        Text("Right")
                            .frame(width: 50, alignment: .center)
                        //.background(Color.green)
                    }
                    ) {
                        HStack {
                            Text("GLOBE Orthotic\nPlastazote under spenco top; leather bottom")
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            CheckboxView(isChecked: Binding(
                                get: { globeOrthotic },
                                set: { globeOrthotic = $0 }
                            ), label: "")
                            .frame(width: 50)
                        }
                        .padding(.vertical, 5)
                        
                        ForEach($otherOptions) { $option in
                            HStack {
                                Text(option.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if(option.name == "Toe Filler"){
                                    Spacer()
                                    
                                    TextField("...", text: Binding(
                                        get: { toeFillerText ?? "" },
                                        set: { toeFillerText = $0 }
                                    ))
                                    .frame(width: 80)
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.vertical, 1)
                                }
                                if option.name != "UCBL" {
                                    
                                    CheckboxView(isChecked: $option.BL, label: "")
                                        .frame(width: 50)
                                    // .background(Color.green)
                                    
                                    CheckboxView(isChecked: $option.left, label: "")
                                        .frame(width: 50)
                                    //.background(Color.blue)
                                    
                                }
                                CheckboxView(isChecked: $option.right, label: "")
                                    .frame(width: 50)
                                //.background(Color.red)
                            }
                            if option.name == "Morton's Extension" {
                                Toggle("Reverse", isOn: $reverseMorton)
                                //.padding(.leading)
                                    .tint(reverseMorton ? Colors.primary : .red)
                                    .padding(.vertical, 2)
                                    .padding(.horizontal, screenSize.width * 0.05)
                            }
                            
                            if option.name == "Gait Plate"{
                                HStack {
                                    Text("Gait to Induce (Toe Position)")
                                    Spacer()
                                    Picker("Gait to Induce (Toe Position)", selection: $gaitToInduce) {
                                        Text("Out")
                                            .foregroundColor(.black)
                                            .tag("Out")
                                        Text("In")
                                            .foregroundColor(.black)
                                            .tag("In")
                                    }
                                    .pickerStyle(.segmented)
                                    .frame(width: screenSize.width * 0.30)
                                }
                                .padding(.vertical, 5)
                                .padding(.horizontal, screenSize.width * 0.05)
                            }
                        }
                        
                        HStack {
                            Text("Heel Lift")
                            Spacer()
                            
                            TextField("mm", text: Binding(
                                get: { heelLiftText ?? "" },
                                set: { heelLiftText = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                            .padding(.vertical, 1)
                            
                            CheckboxView(isChecked: $heelLift.left, label: "")
                                .frame(width: 50)
                            
                            CheckboxView(isChecked: $heelLift.right, label: "")
                                .frame(width: 50)
                            //.background(Color.blue)
                        }
                        
                        
                        HStack {
                            Text("Met-head Cutout")
                            Spacer()
                            Picker("Met-head Cutout", selection: $metheadCutout) {
                                Text("1st").tag("1st").foregroundColor(.black)
                                Text("5th").tag("5th").foregroundColor(.black)
                                //Text("None").tag("None").foregroundColor(.black)
                            }
                            .tint(.black)
                            .pickerStyle(.segmented)
                            .frame(width: screenSize.width * 0.30)
                        }
                        .padding(.vertical, 5)
                        
                        
                    }
                    Section(header: Text("Modifications/Instructions")) {
                        
                        TextEditor(text:  Binding(
                            get: { notes ?? "" },
                            set: { notes = $0 }
                        ))
                        .frame(minHeight: 100)
                        //                        .toolbar {
                        //                            ToolbarItemGroup(placement: .keyboard) {
                        //                                Spacer()
                        //                                Button("Done") {
                        //                                    hideKeyboard()
                        //                                }
                        //                                .buttonStyle(.borderless)
                        //                            }
                        //                        }
                        
                    }
                }
                .toast(isShowing: $isToastVisible, message: toastMessage)
                .keyboardAware()
                
                
                //            if !isKeyboardVisible {
                ZStack {
                    Rectangle()
                        .fill(Color.white)
                        .frame(height: screenSize.height * 0.11)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 0)
                    Button {
                        showEditor = true
                        loadBlankPDF()
//                        self.submitForm()
                    } label: {
                        HStack {
                            Text("Submit")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: screenSize.width * 0.9)
                                .padding(.vertical, screenSize.height * 0.015)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Colors.primary)
                                )
                        }
                        .padding(.horizontal, screenSize.width * 0.05)
                    }
                }
            }
        }
        .environment(\.colorScheme, .light)
        .simultaneousGesture(
            TapGesture().onEnded {
                isKeyboardVisible = false
                hideKeyboard()
            }
        )
        .fullScreenCover(isPresented: $showPDF) {
            if let unwrappedDoc = pdfDocument {
                PDFFormViewer(
                    document: Binding(get: { unwrappedDoc }, set: { self.pdfDocument = $0 }),
                    isPresented: $showPDF,
                    patient: $patient,
                    patientData: $patientData,
                    folderItem: $folderItem,
                    footImage:Binding(
                        get: { selectedItem?.image },
                        set: { newVal in selectedItem?.image = newVal }
                    ),
                    heelLiftText: $heelLiftText,
                    notes: $notes,
                    prefilledCheckBoxes: $prefilledValues,
                    selectedDocumentId: selectedDocumentId,
                    documentURL: selectedPdfUrl,
                    onClose: { pdfItem, code, isChanged in
                        print("onClose")
                        if let pdfItem = pdfItem {
                            handlePDFFormClosed(pdfItem: pdfItem, isUpdated: code)
                        }else{
                            print("onClose Empty")
                            prefilledValues = [:]
                            workOrderOptions = []
                            globeOrthotic = false
                            //isGaitToInduce = false
                            metheadCutout = ""
                            gaitToInduce = ""
                            //...
                        }
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showEditor) {
            if let item = selectedItem {
                EditorView(media: item, onClose: {
                    selectedItem = item
                    showEditor = false
                },onSaveImage: { editedImage in
                    // Do something with the edited image
                    print("Image saved: \(editedImage)")
                    selectedItem?.image = editedImage
                    selectedImage = editedImage
                    showEditor = false
                    self.submitForm()
                })
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    private var loadingOverlay: some View {
        Color.black.opacity(0.6)
            .ignoresSafeArea()
            .overlay(
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                    .padding()
                    .background(Color.black.opacity(1))
                    .cornerRadius(12)
            )
    }
    
    private func loadBlankPDF() {
        if let url = Bundle.main.url(forResource: "blank_order_form", withExtension: "pdf"),
           let doc = PDFDocument(url: url) {
            self.pdfDocument = doc
        } else {
            print("Failed to load blank_order_form.pdf")
        }
    }

    
    private func handlePDFFormClosed(pdfItem: OrderScans, isUpdated: Bool) {
        print("handlePDFFormClosed",pdfItem,isUpdated)
        self.isLoading = true
        ScansService.shared.postOrderFormCustom(requestBody: workOrderOptions, notes: notes ?? "", orderId: orderId, orderStatus: orderStatus) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let response):
                    
                    print("postOrderFormCustom", response)
                    self.presentationMode.wrappedValue.dismiss()
                    onSubmit(pdfItem,isUpdated)
                case .failure(let error):
                    print("Error fetching postOrderFormCustom: \(error)")
                }
            }
        }
    }
    
    func submitForm() {
        //print("=== SUBMISSION ===")
        workOrderOptions = []
        if gaitToInduce.isEmpty || gaitToInduce == ""{
            if let gaitPlateOption = otherOptions.first(where: { $0.name == "Gait Plate" }) {
                let (gaitPlate, gaitPlateL, gaitPlateR) = (gaitPlateOption.BL, gaitPlateOption.left, gaitPlateOption.right)
                //print("gaitPlate ===>", gaitPlate, gaitPlateL, gaitPlateR)
                if gaitPlate || gaitPlateL || gaitPlateR {
                    toastMessage = "Please select a toe position for the Gait Plate."
                    isToastVisible = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isToastVisible = false
                    }
                    return
                }
            }
        }
        print("Execute the next code")
        //print("Custom Foot Orthotics: \(customFootOrthotics)")
        for mod in customFootOrthotics {
            //print(" - \(mod.title): isSelected: \(mod.isSelected),")
            let option = WorkOrderOption(
                optionName: mod.title,
                isLeft: false,
                isRight: false,
                isBL: mod.isSelected,
                isEmpty: true,
                isCustom:false,
                customValue: ""
            )
            workOrderOptions.append(option)
        }
        
        // From topCover
        for mod in topCover {
            let option = WorkOrderOption(
                optionName: mod.title,
                isLeft: false,
                isRight: false,
                isBL: mod.isSelected,
                isEmpty: true,
                isCustom: false,
                customValue: ""
            )
            workOrderOptions.append(option)
        }
        
        // From extensionOptions
        for mod in extensionOptions {
            let option = WorkOrderOption(
                optionName: mod.title,
                isLeft: false,
                isRight: false,
                isBL: mod.isSelected,
                isEmpty: true,
                isCustom: false,
                customValue: ""
            )
            workOrderOptions.append(option)
        }
        
        // From modifications
        //print("Modifications:")
        for mod in modifications {
            //print(" - \(mod.name): Left: \(mod.left), Right: \(mod.right)")
            
            let isSpecialCase = (mod.name == "Refurbish" || mod.name == "Repair")
            
            let option = WorkOrderOption(
                optionName: mod.name,
                isLeft: isSpecialCase ? false : mod.left,
                isRight: isSpecialCase ? false : mod.right,
                isBL: mod.BL,
                isEmpty: isSpecialCase,
                isCustom: false,
                customValue: ""
            )
            workOrderOptions.append(option)
        }
        
        //print("Other Options:")
        //print("Reverse Morton's Extension: \(reverseMorton)")
        for option in otherOptions {
            //print(" - \(option.name): Left: \(option.left), Right: \(option.right)")
            if option.name == "Morton's Extension"{
                let workOrderOption = WorkOrderOption(
                    optionName: option.name,
                    isLeft: option.left,
                    isRight: option.right,
                    isBL: option.BL,
                    isEmpty: false,
                    isCustom: reverseMorton,
                    customValue: "Reverse"
                )
                workOrderOptions.append(workOrderOption)
            }else if option.name == "UCBL"  {
                let workOrderOption = WorkOrderOption(
                    optionName: option.name,
                    isLeft: option.left,
                    isRight: option.right,
                    isBL: option.BL,
                    isEmpty: true,
                    isCustom: false,
                    customValue: ""
                )
                workOrderOptions.append(workOrderOption)
            }else if option.name == "Toe Filler"{
                if(toeFillerText == ""){
                    let workOrderOption = WorkOrderOption(
                        optionName: option.name,
                        isLeft: option.left,
                        isRight: option.right,
                        isBL: option.BL,
                        isEmpty: false,
                        isCustom: false,
                        customValue: ""
                    )
                    workOrderOptions.append(workOrderOption)
                }else{
                    let workOrderOption = WorkOrderOption(
                        optionName: option.name,
                        isLeft: option.left,
                        isRight: option.right,
                        isBL: option.BL,
                        isEmpty: false,
                        isCustom: true,
                        customValue: toeFillerText ?? ""
                    )
                    workOrderOptions.append(workOrderOption)
                }
            }else{
                let workOrderOption = WorkOrderOption(
                    optionName: option.name,
                    isLeft: option.left,
                    isRight: option.right,
                    isBL: option.BL,
                    isEmpty: false,
                    isCustom: false,
                    customValue: ""
                )
                workOrderOptions.append(workOrderOption)
            }
        }
        print("Heel Lift: \(heelLift)")
        let isHeelLiftCustom = ((heelLiftText?.isEmpty) == nil)
        let workOrderOption = WorkOrderOption(
            optionName: heelLift.name,
            isLeft: heelLift.left,
            isRight: heelLift.right,
            isBL: false,
            isEmpty: false,
            isCustom: isHeelLiftCustom,
            customValue: heelLiftText ?? ""
        )
        workOrderOptions.append(workOrderOption)
        
        //print("Gait to Induce: \(gaitToInduce)")
        let isGaitToInduce = !gaitToInduce.isEmpty
        let workOrderOption2 = WorkOrderOption(
            optionName: "Gait to Induce (Toe Position)",
            isLeft: false,
            isRight: false,
            isBL: false,
            isEmpty: false,
            isCustom: isGaitToInduce,
            customValue: gaitToInduce
        )
        workOrderOptions.append(workOrderOption2)
        
        //print("Met-head Cutout: \(metheadCutout)")
        let isMetheadCutout = !metheadCutout.isEmpty
        if(isMetheadCutout==true){
            let workOrderOption3 = WorkOrderOption(
                optionName: "Met-head Cutout",
                isLeft: false,
                isRight: false,
                isBL: false,
                isEmpty: false,
                isCustom: isMetheadCutout,
                customValue: metheadCutout
            )
            workOrderOptions.append(workOrderOption3)
        }
        
        //print("GLOBE Orthotic: \(globeOrthotic)")
        if(globeOrthotic == true){
            let workOrderOption4 = WorkOrderOption(
                optionName: "GLOBE Orthotic",
                isLeft: false,
                isRight: globeOrthotic,
                isBL: true,
                isEmpty: true,
                isCustom: false,
                customValue: ""
            )
            workOrderOptions.append(workOrderOption4)
        }
        setupPrefferedValues()
    }
    
    func setupPrefferedValues() {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        let currentDateString = formatter.string(from: Date())
        print("currentDateString",currentDateString,patientData?.practitionerName ?? "PN")
        print("patient?.doctorName ??",patient?.doctorName ?? "DocName")
        print("patientData?.practitionerName",patientData?.practitionerName ?? "PN")
        self.prefilledValues = [:]
        self.prefilledValues  =  [
            "Patient":
                "\(patient?.patientFirstName ?? "") \(patient?.patientLastName ?? "")",
            "Sex":  "\(patient?.sex ?? "")",
            "Date":currentDateString,
            "Provider":"\(patientData?.practitionerName ?? "PN")",
            "Location":"\(patientData?.address ?? "")",
            "Shoe Size":"\(patientData?.shoeSize ?? "")",
            "image":"image",
        ]
        setupCustomCheckboxes()
    }
    
    func setupCustomCheckboxes() {
        
        for mod in customFootOrthotics {
            if(mod.isSelected){
                let key = checkboxFieldMapping[mod.title]
                if let key = key{
                    print("key",key)
                    self.prefilledValues?[key] = "Yes"
                }
            }
        }
        for mod in topCover {
            if(mod.isSelected){
                let key = checkboxFieldMapping[mod.title]
                if let key = key{
                    print("key",key)
                    self.prefilledValues?[key] = "Yes"
                }
            }
        }
        for mod in extensionOptions {
            if(mod.isSelected){
                let key = checkboxFieldMapping[mod.title]
                if let key = key{
                    print("key",key)
                    self.prefilledValues?[key] = "Yes"
                }
            }
        }
        //print("Modifications:")
        for (index, mod) in modifications.enumerated() {
            let isSpecialCase = (mod.name == "Refurbish" || mod.name == "Repair")
            if isSpecialCase {
                if mod.right {
                    if let key = checkboxFieldMapping[mod.name] {
                        print("key", key)
                        self.prefilledValues?[key] = "Yes"
                    }
                }
            } else {
                let adjustedIndex = index + 1
                if mod.BL {
                    if let key = checkboxFieldMapping[mod.name] {
                        self.prefilledValues?[key] = "Yes"
                        self.prefilledValues?["L\(adjustedIndex)"] = "Yes"
                        self.prefilledValues?["R\(adjustedIndex)"] = "Yes"
                    }
                }
                if mod.right {
                    self.prefilledValues?["R\(adjustedIndex)"] = "Yes" // Adjusted with index
                } else if mod.left {
                    if(adjustedIndex==4){
                        self.prefilledValues?["L\(adjustedIndex).0"] = "Yes"
                    }else{
                        self.prefilledValues?["L\(adjustedIndex)"] = "Yes"
                    }
                }
            }
        }
        
        for (index, mod) in otherOptions.enumerated() {
            if mod.name == "Morton's Extension"{
                
                if(reverseMorton){
                    self.prefilledValues?["Reverse.0"] = "Yes"
                }
                if mod.BL {
                    //self.prefilledValues?["Reverse.0"] = "Yes"
                    self.prefilledValues?["Undefined.0"] = "Yes"
                    self.prefilledValues?["ML"] = "Yes"
                    self.prefilledValues?["MR"] = "Yes"
                }
                if mod.right {
                    self.prefilledValues?["ML"] = "Yes"
                } else if mod.left {
                    self.prefilledValues?["MR"] = "Yes"
                }
            }else if mod.name == "UCBL"{
                if mod.right {
                    if let key = checkboxFieldMapping[mod.name] {
                        self.prefilledValues?[key] = "Yes"
                    }
                }
            }else if mod.name == "Gait Plate"{
                if mod.BL {
                    if let key = checkboxFieldMapping[mod.name] {
                        print("key", key)
                        self.prefilledValues?[key] = "Yes"
                        self.prefilledValues?["Gait L"] = "Yes"
                        self.prefilledValues?["Gait R"] = "Yes"
                    }
                }
                if mod.right {
                    self.prefilledValues?["Gait R"] = "Yes"
                } else if mod.left {
                    self.prefilledValues?["Gait L"] = "Yes"
                }
            }else if mod.name == "Arch Reinforcement"{
                if mod.BL {
                    if let key = checkboxFieldMapping[mod.name] {
                        self.prefilledValues?[key] = "Yes"
                        self.prefilledValues?["Arch L"] = "Yes"
                        self.prefilledValues?["Arch R"] = "Yes"
                    }
                }
                if mod.right {
                    self.prefilledValues?["Arch R"] = "Yes"
                } else if mod.left {
                    self.prefilledValues?["Arch L"] = "Yes"
                }
                
            }else if mod.name == "Scaphoid Arch Pad"{
                if mod.BL {
                    if let key = checkboxFieldMapping[mod.name] {
                        self.prefilledValues?[key] = "Yes"
                        self.prefilledValues?["Scaphoid L"] = "Yes"
                        self.prefilledValues?["Scaphoid R"] = "Yes"
                    }
                }
                if mod.right {
                    self.prefilledValues?["Scaphoid R"] = "Yes"
                } else if mod.left {
                    self.prefilledValues?["Scaphoid L"] = "Yes"
                }
                
            }else if mod.name == "Toe Filler"{
                if mod.BL {
                    if let key = checkboxFieldMapping[mod.name] {
                        self.prefilledValues?[key] = "Yes"
                        self.prefilledValues?["Toe L"] = "Yes"
                        self.prefilledValues?["Toe R"] = "Yes"
                    }
                }
                if mod.right {
                    self.prefilledValues?["Toe R"] = "Yes"
                } else if mod.left {
                    self.prefilledValues?["Toe L"] = "Yes"
                }
                
            }else if mod.name == "Heel Lift"{
                if mod.BL {
                    if let key = checkboxFieldMapping[mod.name] {
                        self.prefilledValues?[key] = "Yes"
                        self.prefilledValues?["Heel Lift L.0"] = "Yes"
                        self.prefilledValues?["Heel Lift R"] = "Yes"
                    }
                }
                if mod.right {
                    self.prefilledValues?["Heel Lift R"] = "Yes"
                } else if mod.left {
                    self.prefilledValues?["Heel Lift L.0"] = "Yes"
                }
                
            }else if mod.name == "Met-head Cutout"{
                if !metheadCutout.isEmpty {
                    if(metheadCutout == "1st"){
                        self.prefilledValues?["1th"] = "Yes"
                    }else{
                        self.prefilledValues?["5th"] = "Yes"
                    }
                }
            }else if mod.name == "Gait to Induce (Toe Position)"{
                if !gaitToInduce.isEmpty {
                    if(gaitToInduce == "Out"){
                        self.prefilledValues?["OutToe"] = "Yes"
                    }else{
                        self.prefilledValues?["InToe"] = "Yes"
                    }
                }
            } else if(globeOrthotic == true){
                self.prefilledValues?["Globe"] = "Yes"
            }
        }
        
        let isGaitToInduce = !gaitToInduce.isEmpty
        if(isGaitToInduce==true){
            let key = checkboxFieldMapping["Gait to Induce (Toe Position)"]
            if let key = key{
                self.prefilledValues?[key] = "Yes"
            }
        }
        
        let isMetheadCutout = !metheadCutout.isEmpty
        if(isMetheadCutout==true){
            let key = checkboxFieldMapping["Met-head Cutout"]
            if let key = key{
                self.prefilledValues?[key] = "Yes"
                if(metheadCutout == "1st"){
                    self.prefilledValues?["1st"] = "Yes"
                }else{
                    self.prefilledValues?["5th"] = "Yes"
                }
            }
        }
        
        if(globeOrthotic == true){
            let key = checkboxFieldMapping["GLOBE Orthotic"]
            if let key = key{
                self.prefilledValues?[key] = "Yes"
            }
        }
 
            if heelLift.right {
                self.prefilledValues?["Heel Lift R"] = "Yes"
                if heelLift.left {
                    self.prefilledValues?["Heel Lift L.0"] = "Yes"
                    self.prefilledValues?["Heel Lift"] = "Yes"
                }
            } else if heelLift.left {
                self.prefilledValues?["Heel Lift L.0"] = "Yes"
            }
        print("prefilledValues",prefilledValues)
        self.showPDF=true
    }
    
    init(
        customFootOrthotics: [Option],
        topCover: [Option],
        extensionOptions: [Option],
        modifications: [ModificationOption],
        orderId: Int,
        orderStatus: String,
        onSubmit:  @escaping (OrderScans?, Bool) -> Void,
        folderItem: ScanFolderItem?,
        patient: PatientData?,
        patientData: OrderPatientProfile?
        
    ) {
        self.customFootOrthotics = customFootOrthotics
        self.topCover = topCover
        self.extensionOptions = extensionOptions
        self.modifications = modifications
        self.orderId = orderId
        self.orderStatus = orderStatus
        self.onSubmit = onSubmit
        
        self._folderItem = Binding.constant(folderItem)
        self.patient = patient
        self._patientData = Binding.constant(patientData)
    }
}

struct KeyboardToolbar: ToolbarContent {
    var hideKeyboardAction: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") {
                hideKeyboardAction()
            }
            .buttonStyle(.bordered)
        }
    }
}

