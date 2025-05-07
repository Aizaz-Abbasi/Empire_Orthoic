//
//  ListPdfView.swift
//  EmpireScan
//
//  Created by MacOK on 18/04/2025.
//
import SwiftUI
import PDFKit

struct ListPdfView: UIViewRepresentable {
    let url: URL
    
    // Keep a reference to the PDFView
    private let pdfView = PDFView()

    func makeUIView(context: Context) -> PDFView {
        pdfView.autoScales = true
        return pdfView
    }
    func updateUIView(_ uiView: PDFView, context: Context) {
        // Load the PDF document asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            if let document = PDFDocument(url: url) {
                DispatchQueue.main.async {
                    // Only update the UI on the main thread
                    uiView.document = document
                }
            }
        }
    }
}
