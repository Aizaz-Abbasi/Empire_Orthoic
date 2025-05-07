//
//  PDFFormView.swift
//  EmpireScan
//
//  Created by MacOK on 09/04/2025.
//

import Foundation
import SwiftUI
import PDFKit

struct PDFFormView: View {
    @StateObject private var viewModel = PDFFormViewModel()
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            PDFKitView(pdfDocument: $viewModel.pdfDocument, formData: $viewModel.formData)
                .edgesIgnoringSafeArea(.all)

            Button("Submit") {
                viewModel.submitForm { success, message in
                    alertMessage = message ?? (success ? "Form submitted successfully" : "Submission failed")
                    showAlert = true
                }
            }
            .padding()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertMessage))
        }
        .onAppear {
            viewModel.loadPDF()
        }
    }
}

