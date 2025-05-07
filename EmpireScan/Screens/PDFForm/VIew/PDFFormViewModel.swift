//
//  PDFFormViewModel.swift
//  EmpireScan
//
//  Created by MacOK on 09/04/2025.
//

import Foundation
import Foundation
import PDFKit

class PDFFormViewModel: ObservableObject {
    @Published var pdfDocument: PDFDocument?
    @Published var formData: [String: Any] = [:]

    private let apiEndpoint = "https://api.example.com/upload-pdf"

    func loadPDF() {
        guard let url = Bundle.main.url(forResource: "OrthioticWorkOrder", withExtension: "pdf"),
              let document = PDFDocument(url: url) else { return }
        self.pdfDocument = document
    }

    func submitForm(completion: @escaping (Bool, String?) -> Void) {
        guard collectFormData(), let savedURL = savePDFWithFormData() else {
            completion(false, "Form data invalid or failed to save")
            return
        }

        uploadPDF(savedURL, completion: completion)
    }

    private func collectFormData() -> Bool {
        guard let document = pdfDocument else { return false }

        formData.removeAll()

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

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("filled_form_\(Date().timeIntervalSince1970).pdf")
        return document.write(to: url) ? url : nil
    }

    private func uploadPDF(_ pdfURL: URL, completion: @escaping (Bool, String?) -> Void) {
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        for (key, value) in formData {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.append("\(value)\r\n")
        }

        if let data = try? Data(contentsOf: pdfURL) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(pdfURL.lastPathComponent)\"\r\n")
            body.append("Content-Type: application/pdf\r\n\r\n")
            body.append(data)
            body.append("\r\n")
            body.append("--\(boundary)--\r\n")

            URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
                if let error = error {
                    completion(false, "Upload failed: \(error.localizedDescription)")
                    return
                }

                let success = (response as? HTTPURLResponse)?.statusCode == 200
                completion(success, success ? nil : "Server returned error")
            }.resume()
        } else {
            completion(false, "Could not read PDF data")
        }
    }
}
