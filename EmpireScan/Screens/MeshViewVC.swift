//
//  MeshView.swift
//  EmpireScan
//
//  Created by MacOK on 15/04/2025.
//
import MetalKit
import UIKit
import MessageUI
import StructureKit
import Structure
import SwiftUI
import ZIPFoundation
import UIKit
import SceneKit

var selectedDocumentId: Int? = nil
var selectedPdfUrl: URL? = nil
var selectedImageURL: URL?

class MeshViewVC: UIViewController {
    
    var modelURL: URL?
    var stlURL: String?
    let screenWidth = UIScreen.main.bounds.width
    let screenHeight = UIScreen.main.bounds.height
    private var isWireframe = false
    private let sceneView = SCNView()
    
    var descriptionText: String = ""
    private var descriptionTextView: UITextView!
    private var containerView: UIView!
    
    var footType: String?
    var scanType: String?
    var orderId:Int?
    var folderId:Int?
    var orderStatus: String?
    var documentId: Int?
    var isEditable:Bool=true
    var onScreenShot: ((OrderScans) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupSceneView()
        setupTopLeftControls()
        if(isEditable){
          setupRefreshButton()
          //setupRefreshButton()
        }
       
        setupBottomButtons()
        loadModel()
    }
    
    private func setupSceneView() {
        sceneView.frame = view.bounds
        sceneView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = true
        view.addSubview(sceneView)
    }
    
    private func setupTopLeftControls() {
        // Image 1
        let image1 = UIImageView(image: UIImage(named: "logo-empire-orthotic"))
        image1.contentMode = .scaleAspectFit
        image1.translatesAutoresizingMaskIntoConstraints = false
        //image1.layer.borderWidth = 2  // For debugging (remove in production)
        view.addSubview(image1)
        
        // Image 2
        let image2 = UIImageView(image: UIImage(named: "launch-screen-logo"))
        image2.contentMode = .scaleAspectFit
        image2.translatesAutoresizingMaskIntoConstraints = false
       // image2.layer.borderWidth = 2  // For debugging (remove in production)
        view.addSubview(image2)
        
        // Close Button
        let closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        closeButton.tintColor = .black
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(closeButton)
        
        // Stack View
        let stackView = UIStackView(arrangedSubviews: [image1, image2, closeButton])
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .center
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // Metrics
        let imageHeight = screenHeight * 0.05
        let imageWidth = screenWidth * 0.4  // Both images will use this width
        let closeButtonSize = screenWidth * 0.1
        
        NSLayoutConstraint.activate([
            // Stack View Positioning
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: -15),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            
            // Image Constraints (Equal Widths)
            image1.widthAnchor.constraint(equalToConstant: imageWidth),
            image1.heightAnchor.constraint(equalToConstant: imageHeight),
            
            image2.widthAnchor.constraint(equalTo: image1.widthAnchor),  // Match image1's width
            image2.heightAnchor.constraint(equalTo: image1.heightAnchor , multiplier:0.8),
            
            // Close Button Constraints
            closeButton.widthAnchor.constraint(equalToConstant: closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: closeButtonSize),
        ])
    }

    
    private func setupRefreshButton() {
        let refreshButton = UIButton(type: .system)

        // Load and flip the image
        let image = UIImage(named: "btn-restart")?.withRenderingMode(.alwaysOriginal)
        if image == nil {
            print("⚠️ Image not found!")
        }

        refreshButton.setImage(image, for: .normal)
        refreshButton.imageView?.contentMode = .scaleAspectFit
        refreshButton.imageView?.transform = CGAffineTransform(scaleX: -1, y: 1)
        refreshButton.addTarget(self, action: #selector(refreshTapped), for: .touchUpInside)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.backgroundColor = UIColor(Colors.primary)
        view.addSubview(refreshButton)

        let buttonSize: CGFloat = screenWidth * 0.12
        refreshButton.layer.cornerRadius = buttonSize / 2

        NSLayoutConstraint.activate([
            refreshButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            refreshButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: buttonSize),
            refreshButton.heightAnchor.constraint(equalToConstant: buttonSize)
        ])

        // Add label below the button
        let label = UILabel()
        label.text = "Re-Scan"
        label.font = UIFont.systemFont(ofSize: 14,weight: .semibold)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: refreshButton.centerXAnchor),
            label.topAnchor.constraint(equalTo: refreshButton.bottomAnchor, constant: 8)
        ])
    }
    
    private func setupMeasureButton() {
        let measureButton = UIButton(type: .system)
        let image = UIImage(systemName: "ruler")?.withRenderingMode(.alwaysTemplate)
        measureButton.setImage(image, for: .normal)
        measureButton.tintColor = .white
        measureButton.backgroundColor = UIColor(Colors.primary)
        measureButton.layer.cornerRadius = screenWidth * 0.06
        measureButton.translatesAutoresizingMaskIntoConstraints = false

        measureButton.addTarget(self, action: #selector(measureTapped), for: .touchUpInside)

        view.addSubview(measureButton)

        NSLayoutConstraint.activate([
            measureButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            measureButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            measureButton.widthAnchor.constraint(equalToConstant: screenWidth * 0.12),
            measureButton.heightAnchor.constraint(equalToConstant: screenWidth * 0.12)
        ])

        // Optional Label
        let label = UILabel()
        label.text = "Measure"
        label.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .black
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: measureButton.centerXAnchor),
            label.topAnchor.constraint(equalTo: measureButton.bottomAnchor, constant: 8)
        ])
    }

    
    private func setupBottomButtons() {
        // Image names for the buttons (make sure these match your Assets exactly)
        let buttonImages = ["wireframe", "location", "description", "screenshot"]
        let buttonSize: CGFloat = screenWidth * 0.12
        let buttons = buttonImages.map { imageName -> UIButton in
            let button = UIButton(type: .system)
            
            if let image = UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal) {
                button.setImage(image, for: .normal)
                button.imageView?.contentMode = .scaleAspectFit
                button.imageView?.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    button.imageView!.heightAnchor.constraint(equalToConstant: buttonSize),
                    button.imageView!.widthAnchor.constraint(equalToConstant: buttonSize)
                ])
            } else {
                print("⚠️ Image for \(imageName) not found!")
            }
            button.translatesAutoresizingMaskIntoConstraints = false
            // Add action for each button
            button.addTarget(self, action: #selector(buttonTapped(_:)), for: .touchUpInside)
            return button
        }
        
        // Create horizontal stack view
        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.axis = .horizontal
        //stackView.spacing = 20
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // Constraints for stack view
        NSLayoutConstraint.activate([
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.heightAnchor.constraint(equalToConstant: buttonSize) // Increased height for square buttons
        ])
        
        // Equal width and height for each button
        for button in buttons {
            NSLayoutConstraint.activate([
                button.widthAnchor.constraint(equalToConstant: buttonSize),
                button.heightAnchor.constraint(equalToConstant: buttonSize)
            ])
            //            button.layer.cornerRadius = buttonSize / 2
            //            button.clipsToBounds = true
            //            button.backgroundColor = .systemPink
        }
    }
    
    // Handle button taps
    @objc private func buttonTapped(_ sender: UIButton) {
        guard let index = sender.superview?.subviews.firstIndex(of: sender) else { return }
        switch index {
        case 0:
            print("Wireframe tapped")
            toggleWireframe()
        case 1:
            print("Location tapped")
        case 2:
            print("Description tapped")
            showDescriptionInput()
        case 3:
            print("Screenshot tapped")
            if isEditable{
                saveImageScreenshot()
            }
        default:
            break
        }
    }
    
    private func loadModel() {
        guard let objURL = modelURL else {
            print("modelURL not set from parent.")
            return
        }
        
        do {
            let scene = try SCNScene(url: objURL, options: nil)
            sceneView.scene = scene
            // Set all materials to red
            scene.rootNode.enumerateChildNodes { (node, _) in
                if let geometry = node.geometry {
                    for material in geometry.materials {
                        material.diffuse.contents = UIColor(Colors.primary)
                    }
                }
            }
            // Zoom out by moving the camera backward
            if let cameraNode = sceneView.pointOfView {
                cameraNode.position.z += 0.5 // Adjust this value as needed
            }
        } catch {
            print("Failed to load model: \(error)")
        }
    }
    
    private func saveImageScreenshot() {
        // 1. Take screenshot of the view
       let image = takeScreenshot()
        // 2. Convert image to JPEG data
        guard let imageData = image?.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to data")
            return
        }

        // 3. Save image to the app's document directory
        let fileManager = FileManager.default
        let docDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let imageURL = docDir.appendingPathComponent("CapturedImage.jpg")

        do {
            try imageData.write(to: imageURL)
            print("📸 Image saved at: \(imageURL)")
            
            // 4. Upload the image
            ScansService.shared.uploadOrderDocument(
                orderId: orderId ?? 0,
                folderId: folderId,
                orderStatus: orderStatus ?? "Not Scanned",
                fileURL: imageURL,
                documentType: "image"
            ) { result in
                switch result {
                case .success(let response):
                    print("✅ Image upload successful: \(String(describing: response.data))")
                    guard let data = response.data else { return }
                    self.showToast(message: "Screenshot saved")
                    self.onScreenShot?(data)
                case .failure(let error):
                    print("❌ Image upload failed: \(error.localizedDescription)")
                }
            }
        } catch {
            print("❌ Error saving image: \(error)")
        }
    }

    
    func takeScreenshot() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: sceneView.bounds.size)
        let image = renderer.image { ctx in
            sceneView.drawHierarchy(in: sceneView.bounds, afterScreenUpdates: true)
        }
        return image
    }
    
    @objc private func toggleWireframe() {
        guard let scene = sceneView.scene else { return }
        
        // Iterate through all the nodes in the scene
        scene.rootNode.enumerateChildNodes { (node, _) in
            // Iterate through all the geometries in the node
            if let geometry = node.geometry {
                for material in geometry.materials {
                    // Toggle the fillMode between .fill (regular) and .lines (wireframe)
                    material.fillMode = self.isWireframe ? .fill : .lines
                }
            }
        }
        isWireframe.toggle()
    }
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func refreshTapped() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Could not find root view controller")
            return
        }
        
        dismiss(animated: true) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let fixedOrientationVC = storyboard.instantiateViewController(withIdentifier: "FixedOrientationController") as? FixedOrientationController,
                  let viewController = fixedOrientationVC.viewControllers.first as? ViewController else {
                print("❌ Could not instantiate FixedOrientationController or inner ViewController")
                return
            }
            // Pass necessary data
            viewController.footType = self.footType
            viewController.orderId = self.orderId
            viewController.folderId = self.folderId
            viewController.scanType = self.scanType
            viewController.orderStatus = self.orderStatus
            fixedOrientationVC.modalPresentationStyle = .fullScreen
            let topController = rootViewController.topMostViewController()
            topController.present(fixedOrientationVC, animated: true)
        }
    }
    
    @objc private func measureTapped() {
       
    }
    
    //
    // 3. Create the description input view
    private func showDescriptionInput() {
        // Create container view
        containerView = UIView(frame: UIScreen.main.bounds)
        containerView.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        // Create content view
        let contentView = UIView()
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 12
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)
        
        // Add constraints for content view
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            contentView.widthAnchor.constraint(equalTo: containerView.widthAnchor, multiplier: 0.8),
            contentView.heightAnchor.constraint(equalTo: containerView.heightAnchor, multiplier: 0.5)
        ])
        
        // Add title label
        let titleLabel = UILabel()
        titleLabel.text = "Add Description"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(titleLabel)
        
        // Add text view
        descriptionTextView = UITextView()
        descriptionTextView.text = descriptionText
        descriptionTextView.font = UIFont.systemFont(ofSize: 16)
        descriptionTextView.layer.borderWidth = 1
        descriptionTextView.layer.borderColor = UIColor.lightGray.cgColor
        descriptionTextView.layer.cornerRadius = 8
        descriptionTextView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(descriptionTextView)
        
        // Add save button
        let saveButton = UIButton(type: .system)
        saveButton.setTitle("Save", for: .normal)
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        saveButton.backgroundColor = UIColor(Colors.primary)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 8
        saveButton.addTarget(self, action: #selector(saveDescription), for: .touchUpInside)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(saveButton)
        
        // Add cancel button
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(self, action: #selector(hideDescriptionInput), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cancelButton)
        
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        containerView.addGestureRecognizer(tapGesture)

        // Set up constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            descriptionTextView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionTextView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionTextView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            descriptionTextView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -16),
            
            saveButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            saveButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            saveButton.widthAnchor.constraint(equalToConstant: 80),
            saveButton.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.centerYAnchor.constraint(equalTo: saveButton.centerYAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -16),
        ])
        
        // Add to window and animate
        if let window = UIApplication.shared.windows.first {
            containerView.alpha = 0
            window.addSubview(containerView)
            
            UIView.animate(withDuration: 0.3) {
                self.containerView.alpha = 1
            }
        }
        
        // Show keyboard
        descriptionTextView.becomeFirstResponder()
    }
    
    @objc private func dismissKeyboard() {
        containerView.endEditing(true)
    }

    // 4. Add save and hide functions
    @objc private func saveDescription() {
        if !isEditable{
            return
        }
        descriptionText = descriptionTextView.text
        ScansService.shared.updateAttachmentDescription(
            documentId: documentId ?? 0,
            orderStatus: orderStatus ?? "Not Scanned",
            description:descriptionText
        ) { result in
            switch result {
            case .success(let response):
                print("✅ Updated successfully: \(String(describing: response.data))")
                self.showToast(message: "Description updated")
            case .failure(let error):
                self.showToast(message: "❌ Update failed: \(error.localizedDescription)")
                print("❌ Update failed: \(error.localizedDescription)")
            }
        }
        hideDescriptionInput()
    }

    @objc private func hideDescriptionInput() {
        UIView.animate(withDuration: 0.3, animations: {
            self.containerView.alpha = 0
        }) { _ in
            self.containerView.removeFromSuperview()
            self.descriptionTextView.resignFirstResponder()
        }
    }
}
