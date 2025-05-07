//
//  PDFFormVC.swift
//  EmpireScan
//
//  Created by MacOK on 09/04/2025.
//

import Foundation
import UIKit
import PDFKit
import MobileCoreServices

class PDFFormViewController: UIViewController {
    
    // MARK: - Properties
    private var pdfView: PDFView!
    private var pdfDocument: PDFDocument?
    private var formData: [String: Any] = [:]
    private let apiEndpoint = "https://api.example.com/upload-pdf" // Replace with your actual API endpoint
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPDFView()
        setupNavigationBar()
    }
    
    // MARK: - Setup
    private func setupPDFView() {
        pdfView = PDFView(frame: view.bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.autoScales = true
        view.addSubview(pdfView)
        
        // Load the PDF form
        loadPDFForm()
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "Orthotic Work Order"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Submit",
            style: .plain,
            target: self,
            action: #selector(submitButtonTapped)
        )
    }
    
    // MARK: - PDF Handling
    private func loadPDFForm() {
        guard let pdfURL = Bundle.main.url(forResource: "OrthioticWorkOrder", withExtension: "pdf") else {
            showAlert(message: "Could not locate the PDF form")
            return
        }
        
        guard let document = PDFDocument(url: pdfURL) else {
            showAlert(message: "Could not load the PDF document")
            return
        }
        
        pdfDocument = document
        pdfView.document = document
        
        // Add gesture recognizer for form interaction
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        pdfView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: pdfView)
        guard let page = pdfView.page(for: location, nearest: true) else { return }
        
        // Convert view coordinates to page coordinates
        let convertedPoint = pdfView.convert(location, to: page)
        // Get all annotations on the page
        let annotations = page.annotations
        // Filter annotations that contain the point
        let tappedAnnotations = annotations.filter { annotation in
            // Get the bounds of the annotation
            let annotationBounds = annotation.bounds
            // Check if the bounds contain the point
            return annotationBounds.contains(convertedPoint)
        }

        // Process the tapped annotations
        for annotation in tappedAnnotations {
            handleAnnotationTap(annotation)
        }
    }
    
    private func handleAnnotationTap(_ annotation: PDFAnnotation) {
        if annotation.widgetFieldType == .button {
            // Toggle checkbox
            if let buttonWidgetState = annotation.widgetStringValue {
                annotation.widgetStringValue = (buttonWidgetState == "Yes") ? "Off" : "Yes"
            }
        } else if annotation.widgetFieldType == .choice {
            // Show dropdown options
            showDropdownOptions(for: annotation)
        } else if annotation.widgetFieldType == .text {
            // Show text input
            showTextInput(for: annotation)
        }
    }
    
    private func showDropdownOptions(for annotation: PDFAnnotation) {
        guard let fieldName = annotation.fieldName else { return }
        
        // Since we can't directly access options from the annotation,
        // we'll need to handle this based on the field name or provide default options
        let options = getOptionsForField(fieldName)
        
        let alert = UIAlertController(title: "Select Option", message: nil, preferredStyle: .actionSheet)
        
        for option in options {
            let action = UIAlertAction(title: option, style: .default) { [weak self] _ in
                annotation.widgetStringValue = option
                self?.formData[fieldName] = option
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    private func getOptionsForField(_ fieldName: String) -> [String] {
        // Map field names to their possible options
        // This would need to be customized for your specific PDF form
        switch fieldName {
        case "TYPE":
            return ["Functional", "Accommodative", "Sport", "Pediatric", "Diabetic"]
        case "TopCover":
            return ["Leather", "Vinyl", "EVA", "Plastazote", "Poron"]
        case "Extension":
            return ["Sulcus", "Met Head", "Full"]
        case "Device":
            return ["Standard", "Athletic", "Dress", "Pediatric"]
        default:
            return ["Option 1", "Option 2", "Option 3"]
        }
    }
    
    private func showTextInput(for annotation: PDFAnnotation) {
        guard let fieldName = annotation.fieldName else { return }
        
        let alert = UIAlertController(title: "Enter Text", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = annotation.widgetStringValue
        }
        
        let confirmAction = UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            if let text = alert.textFields?.first?.text {
                annotation.widgetStringValue = text
                self?.formData[fieldName] = text
            }
        }
        
        alert.addAction(confirmAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // MARK: - Form Data Handling
    private func collectFormData() -> Bool {
        guard let document = pdfDocument else { return false }
        
        // Loop through pages and collect form data
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            
            for annotation in page.annotations {
                if let fieldName = annotation.fieldName {
                    if annotation.widgetFieldType == .button {
                        formData[fieldName] = (annotation.widgetStringValue == "Yes")
                    } else {
                        formData[fieldName] = annotation.widgetStringValue
                    }
                }
            }
        }
        
        return !formData.isEmpty
    }
    
    private func savePDFWithFormData() -> URL? {
        guard let document = pdfDocument else { return nil }
        
        // Create a temporary URL to save the filled form
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("filled_form_\(Date().timeIntervalSince1970).pdf")
        
        // Save the document with form data
        if document.write(to: tempFileURL) {
            print("Saved filled PDF to: \(tempFileURL.path)")
            return tempFileURL
        } else {
            print("Failed to save filled PDF")
            return nil
        }
    }
    
    // MARK: - API Integration
    @objc private func submitButtonTapped() {
        // First collect all form data
        if !collectFormData() {
            showAlert(message: "No form data to submit")
            return
        }
        
        // Save the filled PDF
        guard let pdfURL = savePDFWithFormData() else {
            showAlert(message: "Failed to save the form")
            return
        }
        
        // Show progress indicator
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.center = view.center
        indicator.startAnimating()
        view.addSubview(indicator)
        
        // Upload the PDF to the API
        uploadPDF(pdfURL) { [weak self] success, message in
            DispatchQueue.main.async {
                indicator.removeFromSuperview()
                
                if success {
                    self?.showAlert(message: "Form submitted successfully")
                } else {
                    self?.showAlert(message: "Form submission failed: \(message ?? "Unknown error")")
                }
            }
        }
    }
    
    private func uploadPDF(_ pdfURL: URL, completion: @escaping (Bool, String?) -> Void) {
        // Create a URLRequest
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        
        // Create multipart form data
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create the request body
        var data = Data()
        
        // Add form fields
        for (key, value) in formData {
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            data.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add the PDF file
        do {
            let pdfData = try Data(contentsOf: pdfURL)
            data.append("--\(boundary)\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(pdfURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
            data.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
            data.append(pdfData)
            data.append("\r\n".data(using: .utf8)!)
        } catch {
            completion(false, "Failed to read PDF data: \(error.localizedDescription)")
            return
        }
        
        // Final boundary
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Create and start task
        let task = URLSession.shared.uploadTask(with: request, from: data) { data, response, error in
            if let error = error {
                completion(false, "Network error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(false, "Invalid response")
                return
            }
            
            if httpResponse.statusCode == 200 {
                completion(true, nil)
            } else {
                let responseMessage = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Status code: \(httpResponse.statusCode)"
                completion(false, responseMessage)
            }
        }
        
        task.resume()
    }
    
    // MARK: - Helper
    private func showAlert(message: String) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Navigation Extension for Screen Integration
extension UIViewController {
    func presentPDFFormScreen() {
        let pdfFormVC = PDFFormViewController()
        let navController = FixedOrientationController(rootViewController: pdfFormVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: true)
    }
}
