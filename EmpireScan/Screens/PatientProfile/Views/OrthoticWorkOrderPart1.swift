//
//  OrthoticWorkOrderPart1.swift
//  OrderForm
//
//  Created by MacOK on 25/04/2025.
//
import Foundation
import SwiftUI
struct OrthoticWorkOrderPart1: View {

    @Binding var folderItem: ScanFolderItem?
    @State var patient: PatientData?
    @Binding var patientData: OrderPatientProfile?
    var orderId: Int
    var orderStatus: String
    var onSubmit: (OrderScans?, Bool) -> Void
    
    @State private var customFootOrthotics: [Option] = [
        Option(title: "Sport", isSelected: false),
        Option(title: "Semi-Flex", isSelected: false),
        Option(title: "Dress", isSelected: false)
    ]
    
    @State private var topCover: [Option] = [
        Option(title: "Spenco", isSelected: false),
        Option(title: "Perforated EVA", isSelected: false),
        Option(title: "Leather", isSelected: false),
        Option(title: "Leather W/O Padding", isSelected: false),
        Option(title: "Multi-Color EVA", isSelected: false),
        Option(title: "Plastazote", isSelected: false)
    ]
    
    @State private var extensionOptions: [Option] = [
        Option(title: "Full", isSelected: false),
        Option(title: "Sulcus", isSelected: false),
        Option(title: "Methead", isSelected: false)
    ]
    
    @State private var modifications: [ModificationOption] = [
        ModificationOption(name: "Metatarsal Pad"),
        ModificationOption(name: "Heel Spur Pad"),
        ModificationOption(name: "Deep Heel Cup"),
        ModificationOption(name: "Extnc Heel Post"),
//        ModificationOption(name: "Refurbish"),
//        ModificationOption(name: "Repair")
    ]
    @Environment(\.screenSize) private var screenSize
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    Form {
                        Section(header: Text("Custom Foot Orthotics")) {
                           
                            ForEach($customFootOrthotics) { $option in
                                    HStack {
                                        Text(option.title)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        CheckboxView(isChecked: $option.isSelected, label: "")
                                            .frame(width: 10)
                                    }
                                }
                        }
                        
                        Section(header: Text("Top Cover")) {
                            ForEach($topCover) { $option in
                                    HStack {
                                        Text(option.title)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        CheckboxView(isChecked: $option.isSelected, label: "")
                                            .frame(width: 10)
                                    }
                                }
                        }
                        
                        Section(header: Text("Extension")) {
                            ForEach($extensionOptions) { $option in
                                    HStack {
                                        Text(option.title)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        CheckboxView(isChecked: $option.isSelected, label: "")
                                            .frame(width: 10)
                                    }
                                }
                        }
                        
                        Section(header:
                            HStack {
                                Text("Modifications")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            Text("BL")
                                .frame(width: 50, alignment: .center)
                               // .background(Color.blue)
                                Text("Left")
                                    .frame(width: 50, alignment: .center)
                            
                                Text("Right")
                                    .frame(width: 50, alignment: .center)
                            }
                        ) {
                            ForEach($modifications) { $mod in
                                HStack {
                                    Text(mod.name)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    if mod.name != "Refurbish" && mod.name != "Repair" {
                                        CheckboxView(isChecked: $mod.BL, label: "")
                                            .frame(width: 50)
                                        CheckboxView(isChecked: $mod.left, label: "")
                                            .frame(width: 50)
                                        
                                    }
                                    CheckboxView(isChecked: $mod.right, label: "")
                                        .frame(width: 50)
                                }
                            }
                        }
                        //Add dynamic space at the bottom
                        Section {
                            Color.clear.frame(height: geometry.size.height * 0.1)
                                .listRowBackground(Color.clear)
                        }
                    }
                    .navigationBarTitle("Orthotic Work Order", displayMode: .inline)
                    .onAppear {
                        UITableView.appearance().contentInset.top = -20
                    }
                }
                
                VStack {
                    Spacer()
                    // White background for the button area
                    ZStack {
                        Rectangle()
                            .fill(Color.white)
                            .frame(height: geometry.size.height * 0.11) // Dynamic height based on screen
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: -2)
                        NavigationLink(destination: OrthoticWorkOrderPart2(
                            customFootOrthotics: customFootOrthotics,
                            topCover: topCover,
                            extensionOptions: extensionOptions,
                            modifications: modifications,
                            orderId: orderId,
                            orderStatus: orderStatus,
                            onSubmit: {pdfItem,isUpdated in
                                onSubmit(pdfItem,isUpdated)
                            },
                            folderItem:folderItem,
                            patient:patient,
                            patientData:patientData
                        )) {
                            Text("Next")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: geometry.size.width * 0.9) // 90% of screen width
                                .padding(.vertical, geometry.size.height * 0.015) // Dynamic padding
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Colors.primary)
                                )
                        }
                        .padding(.horizontal, geometry.size.width * 0.05) // 5% padding on sides
                        .padding(.bottom, geometry.size.height * 0.02) // 2% padding at bottom
                    }
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            
        }
    }
}

// Extension to get screen dimensions
private struct ScreenSizeKey: EnvironmentKey {
    static let defaultValue: CGSize = .zero
}

extension EnvironmentValues {
    var screenSize: CGSize {
        get { self[ScreenSizeKey.self] }
        set { self[ScreenSizeKey.self] = newValue }
    }
}

// Add this modifier to your app to provide screen size
struct ScreenSizeModifier: ViewModifier {
    @State private var screenSize: CGSize = UIScreen.main.bounds.size
    
    func body(content: Content) -> some View {
        content
            .environment(\.screenSize, screenSize)
    }
}

extension View {
    func withScreenSize() -> some View {
        self.modifier(ScreenSizeModifier())
    }
}

struct OrthoticWorkOrderPart1_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // Temporary state variables to simulate the preview
            OrthoticWorkOrderPart1(
                folderItem: .constant(nil),
                patient: nil,
                patientData: .constant(nil),
                orderId: 0,
                orderStatus: "",
                onSubmit: {_,_ in }
            )
        }
        .navigationViewStyle(.stack)
    }
}

//Models
class ModificationOption: ObservableObject, Identifiable {
    let id = UUID()
    let name: String
    @Published var BL: Bool {
        didSet {
            if BL {
                left = true
                right = true
            } else {
                left = false
                right = false
            }
        }
    }
    @Published var left: Bool
    @Published var right: Bool

    init(name: String, left: Bool = false, right: Bool = false, BL: Bool = false) {
        self.name = name
        self.left = left
        self.right = right
        self.BL = BL
    }
}

struct Option: Identifiable {
    let id = UUID()
    let title: String
    var isSelected: Bool
}

