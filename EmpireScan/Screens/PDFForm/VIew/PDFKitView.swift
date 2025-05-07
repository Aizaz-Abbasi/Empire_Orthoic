//
//  PDFKitView.swift
//  EmpireScan
//
//  Created by MacOK on 09/04/2025.
//

import Foundation
import SwiftUI
import PDFKit

struct PDFKitView: UIViewRepresentable {
    @Binding var pdfDocument: PDFDocument?
    @Binding var formData: [String: Any]

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.delegate = context.coordinator as! any PDFViewDelegate

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleTap(_:)))
        pdfView.addGestureRecognizer(tapGesture)

        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = pdfDocument
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(formData: $formData)
    }

    class Coordinator: NSObject {
        @Binding var formData: [String: Any]

        init(formData: Binding<[String: Any]>) {
            _formData = formData
        }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let pdfView = sender.view as? PDFView,
                  let page = pdfView.page(for: sender.location(in: pdfView), nearest: true) else { return }

            let location = pdfView.convert(sender.location(in: pdfView), to: page)

            for annotation in page.annotations where annotation.bounds.contains(location) {
                handleAnnotation(annotation, in: pdfView)
            }
        }

        func handleAnnotation(_ annotation: PDFAnnotation, in pdfView: PDFView) {
            guard let fieldName = annotation.fieldName else { return }

            switch annotation.widgetFieldType {
            case .button:
                annotation.widgetStringValue = (annotation.widgetStringValue == "Yes") ? "Off" : "Yes"
                formData[fieldName] = (annotation.widgetStringValue == "Yes")
            case .choice:
                showDropdown(for: annotation, in: pdfView)
            case .text:
                showTextInput(for: annotation, in: pdfView)
            default:
                break
            }
        }

        private func showTextInput(for annotation: PDFAnnotation, in pdfView: PDFView) {
            guard let fieldName = annotation.fieldName else { return }

            let alert = UIAlertController(title: "Enter Text", message: nil, preferredStyle: .alert)
            alert.addTextField { $0.text = annotation.widgetStringValue }

            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                if let text = alert.textFields?.first?.text {
                    annotation.widgetStringValue = text
                    self.formData[fieldName] = text
                }
            })

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            if let controller = pdfView.window?.rootViewController {
                controller.present(alert, animated: true)
            }
        }

        private func showDropdown(for annotation: PDFAnnotation, in pdfView: PDFView) {
            guard let fieldName = annotation.fieldName else { return }

            let options = getOptions(for: fieldName)

            let alert = UIAlertController(title: "Select Option", message: nil, preferredStyle: .actionSheet)

            for option in options {
                alert.addAction(UIAlertAction(title: option, style: .default) { _ in
                    annotation.widgetStringValue = option
                    self.formData[fieldName] = option
                })
            }

            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            if let controller = pdfView.window?.rootViewController {
                controller.present(alert, animated: true)
            }
        }

        private func getOptions(for fieldName: String) -> [String] {
            switch fieldName {
            case "TYPE": return ["Functional", "Accommodative", "Sport", "Pediatric", "Diabetic"]
            case "TopCover": return ["Leather", "Vinyl", "EVA", "Plastazote", "Poron"]
            case "Extension": return ["Sulcus", "Met Head", "Full"]
            case "Device": return ["Standard", "Athletic", "Dress", "Pediatric"]
            default: return ["Option 1", "Option 2", "Option 3"]
            }
        }
    }
}
