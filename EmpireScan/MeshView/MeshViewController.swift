/*
 Copyright © 2022 XRPro, LLC. All rights reserved.
 http://structure.io
 */

import MetalKit
import UIKit
import MessageUI
import StructureKit
import Structure
import SwiftUI
import ZIPFoundation

protocol MeshViewDelegate: AnyObject {
    func meshViewWillDismiss()
    func meshViewDidDismiss()
    func meshViewDidRequestColorizing(mesh: STMesh, previewCompletionHandler: @escaping () -> Void, enhancedCompletionHandler: @escaping () -> Void) -> Bool
}
typealias RendererMetal = RendererMeshMetal

class MeshViewController: UIViewController, UIGestureRecognizerDelegate {
    
    weak var delegate: MeshViewDelegate?
    var needsDisplay: Bool = false
    var colorEnabled: Bool = false
    
    var footType: String?
    var scanType: String?
    var orderId:Int?
    var folderId:Int?
    var orderStatus: String?
    
    @IBOutlet weak var mtkView: MTKView!
    @IBOutlet weak var displayControl: UISegmentedControl!
    @IBOutlet weak var meshViewerMessageView: UIView!
    @IBOutlet weak var meshViewerMessageLabel: UILabel!
    @IBOutlet weak var poweredByStructureButton: UIButton!
    
    var _meshLoaded: STMesh! = nil
    var _mesh: STMesh! = nil
    //  var context: EAGLContext?
    var mesh: STMesh! {
        get {
            return _mesh
        }
        set {
            _mesh = newValue
            if let mesh = _mesh {
                mtkRenderer.updateMesh(mesh: mesh)
                trySwitchToColorRenderingMode()
                needsDisplay = true
            }
        }
    }

    var mtkRenderer: RendererMetal!
    var displayLink: CADisplayLink?
    var viewpointController: ViewpointController = ViewpointController()
    var viewport = [GLfloat](repeating: 0, count: 4)
    
    var modelViewMatrixBeforeUserInteractions: float4x4?
    var projectionMatrixBeforeUserInteractions: float4x4?
    
    var shareViewController: UIActivityViewController!
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(dismissView))
        navigationItem.leftBarButtonItem = backButton
        
        let shareButton = UIBarButtonItem(title: "Save", style: .plain,  target: self, action: #selector(shareMesh(_:)))
        navigationItem.rightBarButtonItem = shareButton
        // Custom initialization
        title = "3D Foot Scan"
    }
    
    func setupMetal() {
        let device = MTLCreateSystemDefaultDevice()!
        mtkView.device = device
        
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        if(_meshLoaded != nil){
            if let mtkView = mtkView,
               let mesh = _meshLoaded {
                mtkRenderer = RendererMetal(view: mtkView, device: device, mesh: mesh, size: view.bounds.size)
            } else {
                print("❌ One or more values are nil: mtkView=\(mtkView), device=\(device), _mesh=\(mesh)")
            }
        }else{
            if let mtkView = mtkView,
               let mesh = mesh {
                mtkRenderer = RendererMetal(view: mtkView, device: device, mesh: mesh, size: view.bounds.size)
            } else {
                print("❌ One or more values are nil: mtkView=\(mtkView), device=\(device), _mesh=\(mesh)")
            }
        }

//      mtkRenderer = RendererMetal(view: mtkView, device: device, mesh: _mesh, size: view.bounds.size)
        mtkRenderer.viewpointController = viewpointController
        mtkView.delegate = mtkRenderer
        // we will trigger drawing by ourselfes
        mtkView.enableSetNeedsDisplay = false
        mtkView.isPaused = true
        
        // allow access to the bytes to write screenshots
        mtkView.framebufferOnly = false
        
        // correct the projection matrix for our viewport
        let viewportSize = view.bounds.size
        let oldProjection = projectionMatrixBeforeUserInteractions!
        let actualRatio = Float(viewportSize.height / viewportSize.width)
        let oldRatio = oldProjection.columns.0.norm() / oldProjection.columns.1.norm()
        let diff = actualRatio / oldRatio
        let newProjection = float4x4.makeScale(diff, 1.0, 1) * oldProjection
        viewpointController.setCameraProjection(newProjection)
    }
    
    func setupGestureRecognizer() {
        let pinchScaleGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchScaleGesture(_:)))
        pinchScaleGesture.delegate = self
        mtkView.addGestureRecognizer(pinchScaleGesture)
        
        // We'll use one finger pan for rotation.
        let oneFingerPanGesture = UIPanGestureRecognizer(target: self, action: #selector(oneFingerPanGesture(_:)))
        oneFingerPanGesture.delegate = self
        oneFingerPanGesture.maximumNumberOfTouches = 1
        mtkView.addGestureRecognizer(oneFingerPanGesture)
        
        // We'll use two fingers pan for in-plane translation.
        let twoFingersPanGesture = UIPanGestureRecognizer(target: self, action: #selector(twoFingersPanGesture(_:)))
        twoFingersPanGesture.delegate = self
        twoFingersPanGesture.maximumNumberOfTouches = 2
        twoFingersPanGesture.minimumNumberOfTouches = 2
        mtkView.addGestureRecognizer(twoFingersPanGesture)
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupMetal()
        meshViewerMessageView.alpha = 0.0
        meshViewerMessageView.isHidden = true
        
        let font = UIFont.boldSystemFont(ofSize: 14.0)
        displayControl.setTitleTextAttributes([NSAttributedString.Key.font: font], for: .normal)
        
        setupGestureRecognizer()
        // initialization order is important!
        viewpointController.setScreenSize(screenSizeX: Float(mtkView.frame.size.width), screenSizeY: Float(mtkView.frame.size.height))
        
        trySwitchToColorRenderingMode()
        needsDisplay = true
    }
    
    func setLabel(_ label: UILabel?, enabled: Bool) {
        let whiteLightAlpha = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5)
        if enabled {
            label?.textColor = UIColor.white
        } else {
            label?.textColor = whiteLightAlpha
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        displayLink?.invalidate()
        displayLink = nil
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupDisplayLynk()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        needsDisplay = true
    }
    
    private func setupDisplayLynk() {
        displayLink?.invalidate()
        displayLink = nil
        
        displayLink = CADisplayLink(target: self, selector: #selector(MeshViewController.draw))
        displayLink!.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
        
        viewpointController.reset()
        
        if !colorEnabled {
            displayControl.removeSegment(at: 2, animated: false)
        }
        
        displayControl.selectedSegmentIndex = 1
    }
    
    private var isModal: Bool {
        return presentingViewController != nil ||
               navigationController?.presentingViewController != nil
    }
    
    @objc func dismissView() {
        print("dismissView")
        delegate?.meshViewWillDismiss()
        // Make sure we clear the data we don't need.
        displayLink?.invalidate()
        displayLink = nil
        
        _mesh = nil
        dismiss(animated: true)
 }
    
    // MARK: - MeshViewer setup when loading the mesh
    func setCameraProjectionMatrix(_ projection: float4x4) {
        viewpointController.setCameraProjection(projection)
        projectionMatrixBeforeUserInteractions = projection
    }
    
    func resetMeshCenter(_ center: vector_float3, _ size: vector_float3) {
        viewpointController.reset()
        viewpointController.setMeshCenter(center, size)
        modelViewMatrixBeforeUserInteractions = viewpointController.currentGLModelViewMatrix()
    }
    
    // MARK: Mesh file share
    func prepareScreenShot(screenshotPath: URL) {
        let lastDrawableDisplayed = mtkView.currentDrawable?.texture
        if let imageRef = lastDrawableDisplayed?.toImage() {
            let uiImage: UIImage = UIImage.init(cgImage: imageRef)
            if let data = uiImage.jpegData(compressionQuality: 0.8) {
                try? data.write(to: screenshotPath)
            }
        }
    }
    
    func getMeshExportFormat() -> Int {
        switch UserDefaults.standard.integer(forKey: "meshExportFormat") {
        case 0: return STMeshWriteOptionFileFormat.objFile.rawValue
        case 1: return STMeshWriteOptionFileFormat.plyFile.rawValue
        case 2: return STMeshWriteOptionFileFormat.binarySTLFile.rawValue
        default:
            NSLog("Unknown meshExportFormat")
            return STMeshWriteOptionFileFormat.objFileZip.rawValue
        }
    }
    
    @MainActor private func toggleShareButton(enabled: Bool) {
        navigationItem.rightBarButtonItem?.isEnabled = enabled
    }
    
    @MainActor private func openShareMeshDialog() {
        print("openShareMeshDialog")
        LoaderManager.shared.show(in: self.view, message: "Saving Scan")
        
        let cacheDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let screenshotPath = cacheDirectory.appendingPathComponent("Preview.jpg")
        
        // Set file permissions and prepare screenshot
        try? FileManager.default.setAttributes([.posixPermissions: 0o777], ofItemAtPath: screenshotPath.path)
        prepareScreenShot(screenshotPath: screenshotPath)
        let timestamp = Int(Date().timeIntervalSince1970)
        // Prepare file paths
        let objFileName = "Model_\(timestamp).obj"
        let stlFileName = "Model_STL_\(timestamp).stl"
        let objFileURL = cacheDirectory.appendingPathComponent(objFileName)
        let stlFileURL = cacheDirectory.appendingPathComponent(stlFileName)
        
        do {
            // Save OBJ
            let objOptions: [String: Any] = [
                kSTMeshWriteOptionFileFormatKey: STMeshWriteOptionFileFormat.objFile.rawValue,
                kSTMeshWriteOptionUseXRightYUpConventionKey: true
            ]
            try _mesh.write(toFile: objFileURL.path, options: objOptions)
            print("✅ OBJ file saved")

            // Save STL
            let stlOptions: [String: Any] = [
                kSTMeshWriteOptionFileFormatKey: STMeshWriteOptionFileFormat.binarySTLFile.rawValue,
                kSTMeshWriteOptionUseXRightYUpConventionKey: true
            ]
            try _mesh.write(toFile: stlFileURL.path, options: stlOptions)
            print("✅ STL file saved")

        } catch let error as NSError {
            let alert = UIAlertController(title: "Mesh cannot be exported.",
                                          message: "Exporting failed: \(error.localizedDescription).",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Check file existence
        guard FileManager.default.fileExists(atPath: objFileURL.path),
              FileManager.default.fileExists(atPath: stlFileURL.path) else {
            print("❌ Exported mesh files are missing")
            return
        }

        // Create ZIP
        let zipFileURL = cacheDirectory.appendingPathComponent("Model_\(timestamp).zip")
        if FileManager.default.fileExists(atPath: zipFileURL.path) {
            try? FileManager.default.removeItem(at: zipFileURL)
        }
        do {
            guard let archive = Archive(url: zipFileURL, accessMode: .create) else {
                print("❌ Could not create archive")
                return
            }
            try archive.addEntry(with: objFileName, fileURL: objFileURL)
            try archive.addEntry(with: stlFileName, fileURL: stlFileURL)
            try archive.addEntry(with: screenshotPath.lastPathComponent, fileURL: screenshotPath)
            print("📦 ZIP file created at: \(zipFileURL.path)")
            uploadMesh(zipFileURL: zipFileURL)

        } catch {
            print("❌ Failed to create ZIP file: \(error.localizedDescription)")
        }
    }


    @MainActor private func openShareMeshDialog1() {
        print("openShareMeshDialog")
        LoaderManager.shared.show(in: self.view,message: "Saving Scan")
        let cacheDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let screenshotPath = cacheDirectory.appendingPathComponent("Preview.jpg")
        
        // Set file permissions for screenshot
        try? FileManager.default.setAttributes([.posixPermissions: 0o777], ofItemAtPath: screenshotPath.path)
        // Take a screenshot and save it to disk.
        prepareScreenShot(screenshotPath: screenshotPath)
        
        let exportExtensions: [Int: String] = [
            STMeshWriteOptionFileFormat.objFile.rawValue: "obj",
            STMeshWriteOptionFileFormat.plyFile.rawValue: "ply",
            STMeshWriteOptionFileFormat.binarySTLFile.rawValue: "stl"
        ]

        let meshExportFormat: Int = getMeshExportFormat()
        guard let fileExtension = exportExtensions[meshExportFormat] else {
            print("❌ Unsupported file format")
            return
        }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let meshFileName = "Model_\(timestamp).\(fileExtension)"
        let meshFileURL = cacheDirectory.appendingPathComponent(meshFileName)
        
        print("⏳ Saving mesh file: \(meshFileName)")
        
        // Request a zipped OBJ file, potentially with embedded MTL and texture.
        let options: [String: Any] = [
            kSTMeshWriteOptionFileFormatKey: meshExportFormat,
            kSTMeshWriteOptionUseXRightYUpConventionKey: true
        ]
        
        do {
            try _mesh.write(toFile: meshFileURL.path, options: options)
        } catch let error as NSError {
            let message = "Exporting failed: \(error.localizedDescription)."
            let alert = UIAlertController(title: "Mesh cannot be exported.",
                                          message: message,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        // Ensure file exists before sharing
        guard FileManager.default.fileExists(atPath: meshFileURL.path) else {
            print("❌ Mesh file does not exist at path: \(meshFileURL.path)")
            return
        }
        // Create ZIP file and add mesh and screenshot
        let zipFileURL = cacheDirectory.appendingPathComponent("Model_\(timestamp).zip")
        // Delete if ZIP already exists
        if FileManager.default.fileExists(atPath: zipFileURL.path) {
            try? FileManager.default.removeItem(at: zipFileURL)
        }
         do {
                // Create ZIP archive
             guard let archive = Archive(url: zipFileURL, accessMode: .create) else {
                 print("❌ Could not create archive")
                 return
             }
                try archive.addEntry(with: meshFileURL.lastPathComponent, fileURL: meshFileURL)
                try archive.addEntry(with: screenshotPath.lastPathComponent, fileURL: screenshotPath)
                
                print("📤 ZIP file created at: \(zipFileURL.path)")
                uploadMesh(zipFileURL: zipFileURL)
            } catch {
                print("❌ Failed to create ZIP file: \(error.localizedDescription)")
            }
    }

    func uploadMesh(zipFileURL: URL) {
        print("📤 Calling uploadMesh() with ZIP file: \(zipFileURL.path)")

        // Ensure file exists before uploading
        guard FileManager.default.fileExists(atPath: zipFileURL.path) else {
            print("❌ ZIP file does not exist at path: \(zipFileURL.path)")
            return
        }
        if let fileSize = getFileSize(fileURL: zipFileURL) {
            print("📏 File size: \(fileSize) bytes")
        } else {
            print("⚠️ Unable to determine file size")
        }
        print("mesh orderStatus", orderStatus)
        
        ScansService.shared.uploadScanResult(
            orderId: orderId ?? 0,
            description: "",
            footType: footType ?? "",
            scanType: scanType ?? "",
            folderId: folderId,
            orderStatus: orderStatus ?? "",
            meshFileURL: zipFileURL
        ) { result in
            DispatchQueue.main.async {
                LoaderManager.shared.hide {
                    switch result {
                    case .success(let response):
                        print("📩 Message uploadScanResult: \(response.message)")
                        self.showToast(message: response.message)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            if let rootVC = self.presentingViewController?.presentingViewController {
                                rootVC.dismiss(animated: true) {
                                    self.delegate?.meshViewDidDismiss()
                                            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                               let window = scene.windows.first,
                                               let navController = window.rootViewController?.topMostViewController().navigationController {
                                                
                                                print("Navigation stack before pop: \(navController.viewControllers.map { type(of: $0) })")
                                                if let topVC = navController.viewControllers.last,
                                                   topVC is FootSelectionVC {
                                                    navController.popViewController(animated: true)
                                                }
                                                print("📣 Posting scanUploadedSuccessfully")
                                                NotificationCenter.default.post(name: .scanUploadedSuccessfully, object: response.data)
                                            }
                                        }
                            } else {
                                self.dismiss(animated: true) {
                                    self.delegate?.meshViewDidDismiss()
                                }
                            }
                        }

                    case .failure(let error):
                        print("❌ Upload failed: \(error.localizedDescription)")
                        self.showToast(message: error.localizedDescription)
                    }
                }
            }
        }
    }

    func getFileSize(fileURL: URL) -> Int64? {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            return fileAttributes[.size] as? Int64
        } catch {
            print("❌ Error getting file size: \(error.localizedDescription)")
            return nil
        }
    }
    
    @MainActor
    @objc func shareMesh(_ sender: AnyObject) {
        openShareMeshDialog()
    }
    
    // MARK: Rendering
    @objc func draw() {
        let viewpointChanged = viewpointController.update()
        
        // If nothing changed, do not waste time and resources rendering.
        if !needsDisplay && !viewpointChanged {
            return
        }
        
        mtkView.draw()
        needsDisplay = false
        
        //    var currentModelView = viewpointController.currentGLModelViewMatrix()
        //    var currentProjection = viewpointController.currentGLProjectionMatrix()
        //
        //    mtkRenderer.draw(in: mtkView)
        
        //    renderer.clear()
        //
        //    withUnsafePointer(to: &currentProjection) { (one)->Void in
        //      withUnsafePointer(to: &currentModelView, { (two)->Void in
        //        one.withMemoryRebound(to: GLfloat.self, capacity: 16, { (onePtr)->Void in
        //          two.withMemoryRebound(to: GLfloat.self, capacity: 16, { (twoPtr)->Void in
        //            renderer.render(onePtr, modelViewMatrix: twoPtr)
        //          })
        //        })
        //      })
        //    }
        //    _ = eview.presentFramebuffer()
    }
    
    // MARK: Touch & Gesture control
    
    @objc func pinchScaleGesture(_ sender: UIPinchGestureRecognizer) {
        // Forward to the ViewpointController.
        if sender.state == .began {
            viewpointController.onPinchGestureBegan(Float(sender.scale))
        } else if sender.state == .changed {
            viewpointController.onPinchGestureChanged(Float(sender.scale))
        }
    }
    
    @IBAction func oneFingerPanGesture(_ sender: UIPanGestureRecognizer) {
        let touchPos = sender.location(in: view)
        let touchVel = sender.velocity(in: view)
        let touchPosVec = vector_float2(Float(touchPos.x), Float(touchPos.y))
        let touchVelVec = vector_float2(Float(touchVel.x), Float(touchVel.y))
        
        if sender.state == .began {
            viewpointController.onOneFingerPanBegan(touchPosVec)
        } else if sender.state == .changed {
            viewpointController.onOneFingerPanChanged(touchPosVec)
        } else if sender.state == .ended {
            viewpointController.onOneFingerPanEnded(touchVelVec)
        }
    }
    
    @IBAction func twoFingersPanGesture(_ sender: UIPanGestureRecognizer) {
        if sender.numberOfTouches != 2 {
            return
        }
        
        let touchPos = sender.location(in: view)
        let touchVel = sender.velocity(in: view)
        let touchPosVec = vector_float2(Float(touchPos.x), Float(touchPos.y))
        let touchVelVec = vector_float2(Float(touchVel.x), Float(touchVel.y))
        if sender.state == .began {
            viewpointController.onTwoFingersPanBegan(touchPosVec)
        } else if sender.state == .changed {
            viewpointController.onTwoFingersPanChanged(touchPosVec)
        } else if sender.state == .ended {
            viewpointController.onTwoFingersPanEnded(touchVelVec)
        }
        
        func touchesBegan(_ touches: NSSet?, event: UIEvent?) {
            viewpointController.onTouchBegan()
        }
    }
    
    // MARK: UI Control
    
    @IBAction func openDeveloperPortal(_ sender: UIButton) {
        if let url = URL(string: "https://structure.io/developers") {
            UIApplication.shared.open(url)
        }
    }
    
    func trySwitchToColorRenderingMode() {
        // Choose the best available color render mode, falling back to LightedGray
        
        // This method may be called when colorize operations complete, and will
        // switch the render mode to color, as long as the user has not changed
        // the selector.
        if displayControl.selectedSegmentIndex == 2 {
            if mesh.hasPerVertexUVTextureCoords() {
                mtkRenderer.mode = .texture
            } else if mesh.hasPerVertexColors() {
                mtkRenderer.mode = .vertexColor
            } else {
                mtkRenderer.mode = .lightedGrey
            }
        }
    }
    
    @IBAction func displayControlChanged(_ sender: AnyObject) {
        switch displayControl.selectedSegmentIndex {
        case 0: // x-ray
            mtkRenderer.mode = .xray
        case 1: // lighted-gray
            mtkRenderer.mode = .lightedGrey
        case 2: // color
            trySwitchToColorRenderingMode()
            let meshIsColorized: Bool = mesh.hasPerVertexColors() || mesh.hasPerVertexUVTextureCoords()
            if !meshIsColorized {
                colorizeMesh()
            }
            
        default:
            NSLog("Unknown rendering mode")
        }
        
        needsDisplay = true
    }
    
    func colorizeMesh() {
        guard let mesh = self.mesh, let delegate = self.delegate else { return }
        _ = delegate.meshViewDidRequestColorizing(
            mesh: mesh,
            previewCompletionHandler: {},
            enhancedCompletionHandler: { [weak self] in self?.hideMeshViewerMessage() })
    }
    
    func hideMeshViewerMessage() {
        UIView.animate(withDuration: 0.5, animations: { [self] in
            meshViewerMessageView.alpha = 0.0
        }, completion: { [self] _ in
            meshViewerMessageView.isHidden = true
        })
    }
    
    func showMeshViewerMessage(_ msg: String) {
        meshViewerMessageLabel.text = msg
        if meshViewerMessageView.isHidden == true {
            meshViewerMessageView.alpha = 0.0
            meshViewerMessageView.isHidden = false
            
            UIView.animate(withDuration: 0.5, animations: { [self] in
                meshViewerMessageView.alpha = 0.8
                
            })
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @available(iOS 15, *)
    @MainActor private func showPurchaseDialog(trialAvailable: Bool) {
        
        let trialAvailabilityMessage = trialAvailable ? "\n7 days free Trial!" : ""
        
        let alert = UIAlertController(title: "Sharing restrictions",
                                      message: "You can export scans only if active subscription exists.\(trialAvailabilityMessage)",
                                      preferredStyle: .actionSheet)
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.barButtonItem = navigationItem.rightBarButtonItem
        }
        
        for item in StoreKitService.shared.subscriptions {
            alert.addAction(UIAlertAction(title: "\(item.displayName) - \(item.displayPrice)",
                                          style: .default,
                                          handler: { [weak self] _ in
                
                guard let self = self else { return }
                self.toggleShareButton(enabled: false)
                Task {
                    if (try? await StoreKitService.shared.purchase(item)) != nil,
                       let rightButton = self.navigationItem.rightBarButtonItem {
                        self.shareMesh(rightButton)
                    }
                    self.toggleShareButton(enabled: true)
                }
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Restore Purchases",
                                      style: .default,
                                      handler: { [weak self] _ in
            
            guard let self = self else { return }
            self.toggleShareButton(enabled: false)
            Task {
                await StoreKitService.shared.restorePurchase()
                self.toggleShareButton(enabled: true)
            }
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func showPurchaseDialog() {
        
        guard #available(iOS 15, *) else {
            return
        }
        Task {
            // let availability = await StoreKitService.shared.trialPeriodAvailable()
            showPurchaseDialog(trialAvailable: true)
        }
    }
}

// MARK: - MFMailComposeViewControllerDelegate Delegate and Mail related helper functions
extension MeshViewController: MFMailComposeViewControllerDelegate, UINavigationControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    private func createEmailUrl(to: String, subject: String, body: String) -> URL? {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        let gmailUrl = URL(string: "googlegmail://co?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let outlookUrl = URL(string: "ms-outlook://compose?to=\(to)&subject=\(subjectEncoded)")
        let yahooMail = URL(string: "ymail://mail/compose?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let sparkUrl = URL(string: "readdle-spark://compose?recipient=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let airMail = URL(string: "airmail://compose?to=\(to)&subject=\(subjectEncoded)&plainBody=\(bodyEncoded)")
        let protonMail = URL(string: "protonmail://mailto?:=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let fastMail = URL(string: "fastmail://mail/compose?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let dispatchMail = URL(string: "x-dispatch://compose?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let defaultUrl = URL(string: "mailto:\(to)?subject=\(subjectEncoded)&body=\(bodyEncoded)")
        
        if let gmailUrl = gmailUrl, UIApplication.shared.canOpenURL(gmailUrl) {
            return gmailUrl
        } else if let outlookUrl = outlookUrl, UIApplication.shared.canOpenURL(outlookUrl) {
            return outlookUrl
        } else if let yahooMail = yahooMail, UIApplication.shared.canOpenURL(yahooMail) {
            return yahooMail
        } else if let sparkUrl = sparkUrl, UIApplication.shared.canOpenURL(sparkUrl) {
            return sparkUrl
        } else if let airMail = airMail, UIApplication.shared.canOpenURL(airMail) {
            return airMail
        } else if let protonMail = protonMail, UIApplication.shared.canOpenURL(protonMail) {
            return protonMail
        } else if let fastMail = fastMail, UIApplication.shared.canOpenURL(fastMail) {
            return fastMail
        } else if let dispatchMail = dispatchMail, UIApplication.shared.canOpenURL(dispatchMail) {
            return dispatchMail
        }
        
        return defaultUrl
    }
}

extension MTLTexture {
    
    func toImage() -> CGImage? {
        assert(self.pixelFormat == .bgra8Unorm)
        
        let width = self.width
        let height = self.height
        guard let bytes: UnsafeMutableRawPointer = malloc(width * height * 4) else { return nil }
        
        let rowBytes = self.width * 4
        self.getBytes(bytes, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        
        let selftureSize = self.width * self.height * 4
        let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (_: UnsafeMutableRawPointer?, data: UnsafeRawPointer, _: Int) -> Void in
            data.deallocate()
        }
        guard let provider = CGDataProvider(dataInfo: nil, data: bytes, size: selftureSize, releaseData: releaseMaskImagePixelData) else { return nil }
        
        let pColorSpace = CGColorSpaceCreateDeviceRGB()
        let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)
        let cgImageRef = CGImage(
            width: self.width,
            height: self.height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: rowBytes,
            space: pColorSpace,
            bitmapInfo: bitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: CGColorRenderingIntent.defaultIntent)
        return cgImageRef
    }
}
