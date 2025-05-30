/*
 Copyright © 2022 XRPro, LLC. All rights reserved.
 http://structure.io
 */

import Combine
import Foundation
import GLKit
import MediaPlayer
import MetalKit
import StructureKit
import UIKit
import Structure 

class FixedOrientationController: UINavigationController {
  override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .portrait
  }
}

class ViewController: UIViewController {
  // MARK: UI
  @IBOutlet var mtkView: MTKView!
  @IBOutlet var alignCubeWithCameraLabel: UILabel!
  @IBOutlet var fixedCubeDistanceLabel: UILabel!
  @IBOutlet var boxDistanceLabel: UILabel!
  @IBOutlet var boxSizeLabel: UILabel!
  @IBOutlet var alignCubeWithCameraSwitch: UISwitch!
  @IBOutlet var fixedCubeDistanceSwitch: UISwitch!

  @IBOutlet var appStatusMessageLabel: UILabel!
  @IBOutlet var appStatusMessageBgView: UIView!
  @IBOutlet var scanButton: UIButton!
  @IBOutlet var resetButton: UIButton!
  @IBOutlet var doneButton: UIButton!
  @IBOutlet var trackingLostLabel: UILabel!
  @IBOutlet var infoLabel: UILabel!
  @IBOutlet var exportImageView: UIImageView!
  @IBOutlet var distanceGuideImageView: UIImageView!
  @IBOutlet var distanceGuideLabel: UILabel!
  @IBOutlet var subscriptionStateButton: UIButton!
  @IBOutlet var poweredByStructureButton: UIButton!
  @IBOutlet var startStopBtn: UIButton!

  // MARK: fields
  var _captureSession: STCaptureSession!
  var _slamState: SlamData!
  var _scene: STScene!
   var _mesh: STMesh? = nil
  // Visualization
  var _metalData: MetalData!
  // ViewController
  var _appStatus: AppStatus = .init()
  var _meshViewController: MeshViewController!
  var _naiveColorizeTask: STBackgroundTask?
  var _holeFillingTask: STBackgroundTask?
  var _enhancedColorizeTask: STBackgroundTask?
  var _timeTagOnOcc: String?
  var showingMemoryWarning = false
  var _helpOverlay: HelpOverlay?
  var footType: String?
  var scanType: String?
  var orderId:Int?
  var folderId:Int?
  var orderStatus: String?

  // IMU handling.
  var _lastGravity: vector_float3 = .init(0, 0, 0) // For storing gravity vector from IMU.

  // settings
  var _options = Options()
  var _settingsPopupView: SettingsPopupView!
  var _initialBoxDistance: Float = 0.3
  var _initialVolumeSizeInMeters: vector_float3 = .init(0, 0, 0) // For temporary storing the volume during trasnformation
  var _volumeScale: PinchScaleState = .init() // Scale of the scanning volume.

  // sounds
  let slamStateChangeSound = Sound(filename: "Scan", fileExtension: "mp3")
  let distanceGuideSound = Sound(filename: "Distance", fileExtension: "mp3")
  let trackingLostSound = Sound(filename: "Warning", fileExtension: "mp3")
  private var notificationSequenceNumbers = Set<Int>()

  private var cancellable = Set<AnyCancellable>()
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  deinit {
    EAGLContext.setCurrent(nil)
  }
    
  override func viewDidLoad() {
    super.viewDidLoad()
      
      print("footType",footType,scanType,orderId,folderId,orderStatus)
    DispatchQueue(label: "license.validation", qos: .userInitiated).async {
      // TODO: complete this code with your license token
      let status = STLicenseManager.unlock(withKey:"sdk-fF75XEFcma68Em-Ur2sdmWfESTjZholpmW28gTuwCJg", shouldRefresh: false)
        if status != .valid {
        print("Error: No license!")
      }else{
          print("Valid license!")
          //self.updateAppStatusMessage()
      }
    }

    guard AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) != nil else {
      return
    }

    if #available(iOS 15, *) {
     // setupStoreKit()
        self.exportImageView.isHidden = true
    }
      
      if isTrueDepthCameraAvailable() {
          print("✅ TrueDepth Camera is available!")
      } else {
          print("❌ TrueDepth Camera is not available on this device.")
      }
      setupMetal()
      setupUserInterface()
      setupGestures()
      initializeDynamicOptions()
      
  }
    
    func isTrueDepthCameraAvailable() -> Bool {
    
        if let frontCamera = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) {
            return true
        } else {
            return false
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
      return .portrait
    }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    guard AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) != nil else {
      showAppStatusMessage(msg: "This application requires True Depth camera")
      return
    }

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(appDidBecomeActive),
                                           name: UIApplication.didBecomeActiveNotification,
                                           object: nil)

    setupVolumeButtonClickListener(action: #selector(volumeChanged))
    setupCaptureSession()
    resetSLAM()
    enterCubePlacementState()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    updateAppStatusMessage()
  }

  override func viewDidDisappear(_ animated: Bool) {
    NotificationCenter.default.removeObserver(self)
    _captureSession = nil
    removeVolumeButtonClickListener()
  }

  @objc func appDidBecomeActive() {
      print("appDidBecomeActive")
    guard AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) != nil else {
      showAppStatusMessage(msg: "This application requires True Depth camera")
      return
    }
    // enable streaming
    _captureSession.streamingEnabled = true
    let m =  _captureSession.sensorName
      let n =  _captureSession.sensorMode
      let ooo =  _captureSession.userInstructions
      
    // Abort the current scan if we were still scanning before going into background since we
    // are not likely to recover well.
    if _slamState.scannerState == ScannerState.scanning {
      resetButtonPressed(self)
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    respondToMemoryWarning()
  }

  func showHelpDialog() {
    if _helpOverlay == nil {
      _helpOverlay = HelpOverlay(parent: view)
    } else {
      _helpOverlay?.isHidden = false
    }
  }

  @available(iOS 15, *)
  func setupStoreKit() {
    let storeService = StoreKitService.shared
    storeService.$currentSubscription.receive(on: DispatchQueue.main).sink { [weak self] storeSubscription in
      self?.exportImageView.isHidden = storeSubscription == nil
    }.store(in: &cancellable)
  }

  func setupUserInterface() {
    // Make sure the status bar is hidden.
    navigationController?.isNavigationBarHidden = true

    // Fully transparent message label, initially.
    appStatusMessageBgView.alpha = 0
    appStatusMessageLabel.alpha = 0

    // Make sure the label is on top of everything else.
    appStatusMessageBgView.layer.zPosition = 99
    appStatusMessageLabel.layer.zPosition = 100

    // unlimited number of lines
    infoLabel.numberOfLines = 0
    fixedCubeDistanceSwitch.isOn = _options.fixedCubePosition
    fixedCubeDistanceSwitch.isHidden = false
    alignCubeWithCameraSwitch.isOn = !_options.alignCubeWithCamera

//    var attributeString = NSMutableAttributedString(
//      string: "Terms of Use",
//      attributes: linkButtonAttributes)
   // termsOfUseButton.setAttributedTitle(attributeString, for: .normal)

//    attributeString = NSMutableAttributedString(
//      string: "Privacy Policy",
//      attributes: linkButtonAttributes)
   // privacyPolicyButton.setAttributedTitle(attributeString, for: .normal)
  }

  // Make sure the status bar is disabled (iOS 7+)
  override var prefersStatusBarHidden: Bool { return true }

  func setupGestures() {
    // Register pinch gesture for volume scale adjustment.
    let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchGesture(_:)))
    view.addGestureRecognizer(pinchGesture)

    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
    view.addGestureRecognizer(panGesture)

    // Double Tap
    let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapGesture(_:)))
    //doubleTap.numberOfTapsRequired = 2
    view.addGestureRecognizer(doubleTap)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "ShowMeshViewSegue" {
      let navCont = segue.destination as? UINavigationController
      _meshViewController = navCont?.topViewController as? MeshViewController
      weak var this: ViewController? = self
      _meshViewController.delegate = this
      prepareForViewingState()
    }
  }

  func calcBBox(_ mesh: STMesh) -> (vector_float3, vector_float3)? {
    guard mesh.meshVertices(0) != nil else {
      showAlert(title: "Error!!!", message: "Empty Mesh found while calculating Boundary Box")
      return nil
    }
    var minPoint = vector_float3(mesh.meshVertices(0)[0])
    var maxPoint = vector_float3(minPoint)

    for i in 0..<mesh.numberOfMeshes() {
      let numVertices = Int(mesh.number(ofMeshVertices: i))
      if let vertex = mesh.meshVertices(Int32(i)) {
        for j in 0..<numVertices {
          let v = vertex[Int(j)]
          minPoint.x = min(minPoint.x, v.x)
          minPoint.y = min(minPoint.y, v.y)
          minPoint.z = min(minPoint.z, v.z)
          maxPoint.x = max(maxPoint.x, v.x)
          maxPoint.y = max(maxPoint.y, v.y)
          maxPoint.z = max(maxPoint.z, v.z)
        }
      }
    }
    return (minPoint, maxPoint)
  }

  func presentMeshViewer(_ mesh: STMesh) {
    guard _meshViewController != nil else {
      showAlert(title: "Internal Error", message: "_meshViewController is nill")
      return
    }
    _meshViewController.colorEnabled = _options.useColorCamera
    _meshViewController._mesh = mesh
    _meshViewController.setCameraProjectionMatrix(_metalData.depthCameraGLProjectionMatrix)
    _meshViewController.scanType = scanType
      _meshViewController.footType = footType
      _meshViewController.folderId = folderId
      _meshViewController.orderId = orderId
      _meshViewController.orderStatus = orderStatus
      print("presentMeshViewer")
    // Sample a few points to estimate the volume center
    var totalNumVertices: Int32 = 0
    for i in 0..<mesh.numberOfMeshes() {
      totalNumVertices += mesh.number(ofMeshVertices: i)
    }

    guard let (min, max) = calcBBox(mesh) else {
      return
    }
    let volumeCenter = (min + max) / 2
    let size = max - min

    if let timeTagOnOcc = _timeTagOnOcc,
       let meshToSend = _meshViewController.mesh
    {
      // Request a zipped OBJ file, potentially with embedded MTL and texture.
      let options: [String: Any] = [
        kSTMeshWriteOptionFileFormatKey: STMeshWriteOptionFileFormat.plyFile.rawValue,
        kSTMeshWriteOptionUseXRightYUpConventionKey: true
      ]

      _timeTagOnOcc = nil
    }

    _meshViewController.resetMeshCenter(volumeCenter, size)
  }

  func enterCubePlacementState() {
    // Switch to the Scan button.
    scanButton.isHidden = true
    doneButton.isHidden = true
    resetButton.isHidden = true

    // We'll enable the button only after we get some initial pose.
    scanButton.isEnabled = false

    // Cannot be lost in cube placement mode.
    trackingLostLabel.isHidden = true

    // Make labels and buttons visible
    fixedCubeDistanceSwitch.isHidden = false
    fixedCubeDistanceLabel.isHidden = fixedCubeDistanceSwitch.isHidden
    alignCubeWithCameraSwitch.isHidden = false
    alignCubeWithCameraLabel.isHidden = alignCubeWithCameraSwitch.isHidden
    boxSizeLabel.isHidden = false
    distanceGuideImageView.isHidden = false
    distanceGuideLabel.isHidden = false

    boxDistanceLabel.isHidden = !_options.fixedCubePosition
    boxDistanceLabel.text = String.localizedStringWithFormat("Distance %1.2f m", _options.cubeDistanceValue)

    alignCubeWithCameraSwitch.isHidden = false
    boxSizeLabel.text = String.localizedStringWithFormat("Size %1.2f m", Float(_options.volumeSizeInMeters.x) * Float(_volumeScale.currentScale))

    _slamState.scannerState = .cubePlacement
      if _captureSession == nil {
          return
     }
      
    let m =  _captureSession.sensorBatteryLevel
    let n =  _captureSession.sensorMode
      let selectedSensorType = UserDefaults.standard.string(forKey: "selectedSensorType") ?? "Apple"
      if selectedSensorType == "Structure", m == 0 {
          showToast(message: "Please, change default sensor preference in settings.",textColor: .white,backgroundColor: Colors.primary.uiColor)
      }
      
    _captureSession.streamingEnabled = true
    _captureSession.properties = STCaptureSessionPropertiesSetColorCameraAutoExposureISOAndWhiteBalance()
     startStopBtn.layer.cornerRadius = startStopBtn.frame.height / 2
      startStopBtn.layer.borderWidth = 2
      startStopBtn.layer.borderColor = UIColor.white.cgColor

    UIApplication.shared.isIdleTimerDisabled = false
    infoLabel.text = ""

    renderingSettingsDidChange()
  }

  func enterScanningState() {
      
    // This can happen if the UI did not get updated quickly enough.
    guard let cameraPose = _slamState.getCameraPose() else {
      NSLog("Warning: not accepting to enter into scanning state since the initial pose is not valid.")
      return
    }

    // Hide box editing elements
    fixedCubeDistanceSwitch.isHidden = true
    boxDistanceLabel.isHidden = true
    boxSizeLabel.isHidden = true
      alignCubeWithCameraSwitch.isHidden = false
    fixedCubeDistanceLabel.isHidden = fixedCubeDistanceSwitch.isHidden
    alignCubeWithCameraLabel.isHidden = alignCubeWithCameraSwitch.isHidden
    distanceGuideImageView.isHidden = true
    distanceGuideLabel.isHidden = true

    // Switch to the Done button.
    scanButton.isHidden = true
    doneButton.isHidden = true
    resetButton.isHidden = false

    _slamState.tracker.initialCameraPose = cameraPose.toGLK()

    // Turn Off the Idle Timer as phone screen shouldn't Turn off during Scan
    UIApplication.shared.isIdleTimerDisabled = true
    // We will lock exposure during scanning to ensure better coloring.
    _captureSession.properties = STCaptureSessionPropertiesLockAllColorCameraPropertiesToCurrent()
    _slamState.scannerState = .scanning
    renderingSettingsDidChange()
    // play sound
    slamStateChangeSound?.play()
  }

  func enterViewingState() {
    // Cannot be lost in view mode.
    hideTrackingErrorMessage()
    _appStatus.statusMessageDisabled = true
    updateAppStatusMessage()

    // Hide the Scan/Done/Reset button.
    scanButton.isHidden = true
    doneButton.isHidden = true
    resetButton.isHidden = true

    _captureSession.streamingEnabled = false
    _slamState.mapper.finalizeTriangleMesh()

    if let mesh = _scene.lockAndGetMesh() {
      guard mesh.meshVertices(0) != nil else {
        showAlert(title: "ERROR!!!", message: "Capturing stopped before a valid mesh is captured. Taking you back to Cube Placement State.")
        _scene.unlockMesh()
        resetButtonPressed(self)
        return
      }
      presentMeshViewer(mesh)
    }

    _scene.unlockMesh()
    _slamState.scannerState = .viewing
    renderingSettingsDidChange()
    // play sound
    slamStateChangeSound?.play()
  }

  // MARK: IMU

  func processDeviceMotion(_ motion: CMDeviceMotion, with error: NSError?) {
    guard _slamState != nil else { return }

    if _slamState.scannerState == .cubePlacement {
      if _options.alignCubeWithCamera {
        // no gravity in cube. {-1,0,0} for landscape orientation, {0,-1,0} for portrait
        _lastGravity = vector_float3(0.0, -1.0, 0.0)
      } else {
        // Update our gravity vector, it will be used by the cube placement initializer.
        _lastGravity = vector_float3(Float(motion.gravity.x), Float(motion.gravity.y), Float(motion.gravity.z))
      }
    }

    if _slamState.scannerState == .cubePlacement || _slamState.scannerState == .scanning {
      // The tracker is more robust to fast moves if we feed it with motion data.
      _slamState.tracker.updateCameraPose(with: motion)
    }
  }

  func triggerScan() {
    // Start the scan on double tap if the scanner is in cubePlacement state
    if _slamState.scannerState == .cubePlacement {
      if _options.recordOcc {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let date = NSDate()
        _timeTagOnOcc = formatter.string(from: date as Date)

        var occString: String = "[AppDocuments]/"
        occString.append(_timeTagOnOcc!)
        occString.append(".occ")

        let success = _captureSession.occWriter.startWriting(occString, appendDateAndExtension: false)
        if !success {
          NSLog("Could not properly start OCC writer.")
        }
      }
      enterScanningState()
      startStopBtn.setImage(UIImage(named: "Done"), for: .normal)

    } else if _slamState.scannerState == .scanning {
      // Stop the scan on double tap if the scanner is in scanning state
        startStopBtn.setImage(UIImage(named: "Start-1x"), for: .normal)
      performSegue(withIdentifier: "ShowMeshViewSegue", sender: nil)
    }
  }

  // MARK: Physical Button Callbacks

  // Notification on iOS 15 will be called twice even if you volume button is pressed once,
  // but their SequenceNumber is equal so we can use Set to handle notification just once.
  @objc func volumeChanged(notification: Notification) {
    if let userInfo = notification.userInfo {
      if let volumeChangeType = userInfo["Reason"] as? String,
         volumeChangeType == "ExplicitVolumeChange", let sequenceNumber = userInfo["SequenceNumber"] as? Int
      {
        DispatchQueue.main.async {
          if !self.notificationSequenceNumbers.contains(sequenceNumber) {
            self.notificationSequenceNumbers.insert(sequenceNumber)
            // handle volume change
            self.triggerScan()
          }
        }
      }
    }
  }

  // MARK: UI Callbacks
  func onSLAMOptionsChanged() {
    // A full reset to force a creation of a new tracker.
    resetSLAM()
    enterCubePlacementState()
  }

  func adjustVolumeSize(volumeSize: vector_float3) {
      print("adjustVolumeSize")
    // Make sure the volume size remains between 10 centimeters and 3 meters.
    var volumeSize: vector_float3 = volumeSize
    volumeSize.x = keepInRange(volumeSize.x, min: 0.1, max: 3.0)
    volumeSize.y = keepInRange(volumeSize.y, min: 0.1, max: 3.0)
    volumeSize.z = keepInRange(volumeSize.z, min: 0.1, max: 3.0)
    _options.volumeSizeInMeters = volumeSize

    boxSizeLabel.text = String.localizedStringWithFormat("Size %1.2f m", volumeSize.x)
    _slamState.cameraPoseInitializer.volumeSizeInMeters = volumeSize.toGLK()
  }

  @IBAction func alignCubeWithCameraDidChange(_ sender: UISwitch) {
    _options.alignCubeWithCamera = !sender.isOn
    if !_options.alignCubeWithCamera {
      adjustVolumeSize(volumeSize: vector_float3(0.4, 0.4, 0.4))
    } else {
      adjustVolumeSize(volumeSize: vector_float3(0.2, 0.3, 0.3))
    }
    onSLAMOptionsChanged()
  }

  @IBAction func fixedCubePositionDidChange(_ sender: UISwitch) {
    _options.fixedCubePosition = sender.isOn
    boxDistanceLabel.isHidden = !_options.fixedCubePosition
    onSLAMOptionsChanged()
  }

  @IBAction func subscriptionInfoPressed(_ sender: UIButton) {
    guard #available(iOS 15, *) else {
      return
    }

    Task {
      if let subscription = await StoreKitService.shared.activeSubscription() {
        self.showSubscriptionInfoDialog(subscription: subscription)
      }
    }
  }

  @IBAction func openDeveloperPortal(_ sender: UIButton) {
    if let url = URL(string: "https://structure.io/developers") {
      UIApplication.shared.open(url)
    }
  }

  @MainActor func showSubscriptionInfoDialog(subscription: StoreSubscription) {
    if let expiration = subscription.expiration {
      let df = DateFormatter()
      df.dateStyle = .medium
      df.timeStyle = .none
      let formatterDate = df.string(from: expiration)

      let optionMenu = UIAlertController(title: "Subscription info",
                                         message: "Vaild until: \(formatterDate)\n" +
                                           "\(subscription.displayName) \(subscription.displayPrice)",
                                         preferredStyle: .actionSheet)

      if let popoverController = optionMenu.popoverPresentationController {
        popoverController.sourceView = exportImageView
      }

      let closeAction = UIAlertAction(title: "OK", style: .default, handler: nil)
      optionMenu.addAction(closeAction)
      present(optionMenu, animated: true, completion: nil)
    }
  }

  @IBAction func resetButtonPressed(_ sender: AnyObject) {
    resetSLAM()
    enterCubePlacementState()
  }
    
  @IBAction func closeButton(_ sender: AnyObject) {
      print("closeButton")
      dismiss(animated: true, completion: nil)
  }

  func prepareForViewingState() {
    if _captureSession.occWriter.isWriting {
      let success: Bool = _captureSession.occWriter.stopWriting()
      if !success {
        showAlert(title: "Scanner", message: "Could not properly stop OCC writer.")
        assertionFailure()
      }
    }
    enterViewingState()
  }

  // Manages whether we can let the application sleep.
  func showTrackingMessage(message: String) {
    trackingLostLabel.text = message
    trackingLostLabel.isHidden = false
  }

  func hideTrackingErrorMessage() {
    trackingLostLabel.isHidden = true
  }

  func showAppStatusMessage(msg: String) {
    _appStatus.needsDisplayOfStatusMessage = true

    view.layer.removeAllAnimations()
    appStatusMessageLabel.text = msg
    appStatusMessageLabel.isHidden = false
    appStatusMessageBgView.isHidden = false

    mtkView.isUserInteractionEnabled = false
    UIView.animate(withDuration: 0.5, animations: { [self] in
      appStatusMessageLabel.alpha = 1.0
      appStatusMessageBgView.alpha = 1.0
    })
  }

  func hideAppStatusMessage() {
    view.layer.removeAllAnimations()
    UIView.animate(withDuration: 0.5, animations: { [self] in
      appStatusMessageLabel.alpha = 0
      appStatusMessageBgView.alpha = 0
    }, completion: { [self] _ in
      // If nobody called showAppStatusMessage before the end of the animation, do not hide it.
      if !_appStatus.needsDisplayOfStatusMessage {
        // Could be nil if the self is released before the callback happens.
        if mtkView != nil {
          appStatusMessageLabel.isHidden = true
          appStatusMessageBgView.isHidden = true
        }
      }
    })
  }

    override var shouldAutorotate: Bool {
        return false
    }

  func updateAppStatusMessage() {
    guard _captureSession != nil else { return }
    let userInstructions = _captureSession.userInstructions.rawValue
    let needToAuthorizeColorCamera = (userInstructions & STCaptureSessionUserInstruction.needToAuthorizeColorCamera.rawValue) != 0

    let needLicense = STLicenseManager.status != .valid
      let status = STLicenseManager.status

      print("License Status:",needLicense, status.rawValue)
    if needLicense {
      showAppStatusMessage(msg: _appStatus.needLicense)
      return
    }
     print("2")
    // If you don't want to display the overlay message when an approximate calibration
    // is available use `_captureSession.calibrationType >= STCalibrationTypeApproximate`
    let needToRunCalibrator = (userInstructions & STCaptureSessionUserInstruction.needToRunCalibrator.rawValue) != 0
    if needToRunCalibrator {
      showAlert(title: "Error", message: "calibration required")
      assertionFailure()
    }
      print("3")
    // Color camera permission issues.
    if needToAuthorizeColorCamera {
      showAppStatusMessage(msg: _appStatus.needColorCameraAccessMessage)
      return
    }
    // If we reach this point, no status to show.
    hideAppStatusMessage()
  }

  @IBAction func panGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
    guard !_settingsPopupView!.isShown else { return }

    if _slamState.scannerState == .cubePlacement {
      if gestureRecognizer.state == .began {
        _initialBoxDistance = _options.cubeDistanceValue
      } else if gestureRecognizer.state == .changed {
        let minDist: Float = 0.1
        let maxDist: Float = 1.5
        let translation: Float = -Float(gestureRecognizer.translation(in: view).y / view.frame.size.height) * (maxDist - minDist)
        _options.cubeDistanceValue = keepInRange(_initialBoxDistance + translation, min: minDist, max: maxDist)
        boxDistanceLabel.text = String.localizedStringWithFormat("Distance %1.2f m", _options.cubeDistanceValue)
      }
    }
  }

  @IBAction func pinchGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
    guard !_settingsPopupView!.isShown else { return }

    if gestureRecognizer.state == .began {
      if _slamState.scannerState == .cubePlacement {
        _volumeScale.initialPinchScale = _volumeScale.currentScale / gestureRecognizer.scale
      }
      _initialVolumeSizeInMeters = _options.volumeSizeInMeters
    } else if gestureRecognizer.state == .changed {
      if _slamState.scannerState == .cubePlacement {
        // In some special conditions the gesture recognizer can send a zero initial scale.
        if !_volumeScale.initialPinchScale.isNaN {
          _volumeScale.currentScale = gestureRecognizer.scale * _volumeScale.initialPinchScale

          // Don't let our scale multiplier become absurd
          _volumeScale.currentScale = CGFloat(keepInRange(Float(_volumeScale.currentScale), min: 0.01, max: 1000))

          let newVolumeSize: vector_float3 = _initialVolumeSizeInMeters * Float(_volumeScale.currentScale)

          adjustVolumeSize(volumeSize: newVolumeSize)
        }
      }
    } else if gestureRecognizer.state == .ended && _slamState.scannerState == .cubePlacement {
      onSLAMOptionsChanged()
    }
  }

  @IBAction func doubleTapGesture(_ gestureRecognizer: UIPinchGestureRecognizer) {
      print("doubleTapGesture")
    //triggerScan()
  }
    
    @IBAction func startStopBtn(_ sender: UIButton) {
        print("startStopBtn pressed")
        triggerScan()
    }

  func respondToMemoryWarning() {
    switch _slamState.scannerState {
    case .viewing:
      // If we are running a colorizing task, abort it
      if _enhancedColorizeTask != nil && !showingMemoryWarning {
        showingMemoryWarning = true
        // stop the task
        _enhancedColorizeTask!.cancel()
        _enhancedColorizeTask = nil

        // hide progress bar
        _meshViewController!.hideMeshViewerMessage()

        let alertCtrl = UIAlertController(
          title: "Memory Low",
          message: "Colorizing was canceled.",
          preferredStyle: .alert)

        let okAction = UIAlertAction(
          title: "OK",
          style: .default,
          handler: { [weak self] _ in
            self?.showingMemoryWarning = false
          })

        alertCtrl.addAction(okAction)

        // show the alert in the meshViewController
        _meshViewController!.present(alertCtrl, animated: true, completion: nil)
      }

    case .scanning:
      if !showingMemoryWarning {
        showingMemoryWarning = true
        let alertCtrl = UIAlertController(
          title: "Memory Low",
          message: "Scanning will be stopped to avoid loss.",
          preferredStyle: .alert)

        let okAction = UIAlertAction(
          title: "OK", style: .default,
          handler: { [weak self] _ in
            self?.showingMemoryWarning = false
            self?.performSegue(withIdentifier: "ShowMeshViewSegue", sender: nil)
          })
        alertCtrl.addAction(okAction)

        // show the alert
        present(alertCtrl, animated: true, completion: nil)
      }

    default: // not much we can do here
      return
    }
  }
}

// MARK: - MeshViewDelegate

extension ViewController: MeshViewDelegate {
  func meshViewWillDismiss() {
    // If we are running colorize work, we should cancel it.
    _holeFillingTask?.cancel()
    _holeFillingTask = nil

    _naiveColorizeTask?.cancel()
    _naiveColorizeTask = nil

    _enhancedColorizeTask?.cancel()
    _enhancedColorizeTask = nil

    _meshViewController!.hideMeshViewerMessage()
  }

  func meshViewDidDismiss() {
    _appStatus.statusMessageDisabled = false
    updateAppStatusMessage()

    // Reset the tracker, mapper, etc.
    resetSLAM()
    enterCubePlacementState()
  }

  func fillHolesTask(mesh: STMesh, onCompletion: @escaping (_: STMesh) -> Void) -> STBackgroundTask? {
    _holeFillingTask = nil
    let algoType = optionsSet.integer(forKey: .holeFillingAlgo) // "No", "Poisson", "Liepa"
    if algoType != 0 {
      let algorithm = STMeshFillHoleAlgorithm(rawValue: algoType - 1)!
      let options: [AnyHashable: Any] = [
        kSTMeshFillHoleMaxPatchAreaKey: 0.01,
        kSTMeshFillHolePoissonStrategyKey: STMeshFillHolePoissonStrategy.closedHull.rawValue
      ]
      _holeFillingTask = STMesh.newFillHolesTask(with: mesh, algorithm: algorithm, options: options) { [weak self] (resMesh: STMesh?, error: Error?) in
        defer { self?._holeFillingTask = nil }
        if self?._holeFillingTask?.isCancelled ?? true {
          return
        } else if error != nil {
          NSLog("Error during hole filling: \(String(describing: error!.localizedDescription))")
        } else {
          DispatchQueue.main.async { onCompletion(resMesh!) }
        }
      }
      weak var this: ViewController? = self
      _holeFillingTask!.delegate = this
    }
    return _holeFillingTask
  }

  func colorizeSimpleTask(mesh: STMesh, onCompletion: @escaping (_: STMesh) -> Void) -> STBackgroundTask {
    _naiveColorizeTask = try! STColorizer.newColorizeTask(with: mesh,
                                                          scene: _scene,
                                                          keyframes: _slamState.keyFrameManager.getKeyFrames(),
                                                          completionHandler: { [weak self] error in
                                                            defer { self?._naiveColorizeTask = nil }
                                                            if self?._naiveColorizeTask?.isCancelled ?? true {
                                                              return
                                                            } else if error != nil {
                                                              NSLog("Error during colorizing: \(String(describing: error!.localizedDescription))")
                                                            } else {
                                                              DispatchQueue.main.async { onCompletion(mesh) }
                                                            }
                                                          },
                                                          options: [kSTColorizerTypeKey: STColorizerType.perVertex.rawValue,
                                                                    kSTColorizerPrioritizeFirstFrameColorKey: _options.prioritizeFirstFrameColor])
    weak var this: ViewController? = self
    _naiveColorizeTask!.delegate = this
    return _naiveColorizeTask!
  }

  func colorizeEnhancedTask(mesh: STMesh, onCompletion: @escaping (_: STMesh) -> Void) -> STBackgroundTask {
    let type: STColorizerType = optionsSet.integer(forKey: .texturingAlgo, default: 0) == 0 ? .textureMapForObject : .textureMapGeneral
    _enhancedColorizeTask = try! STColorizer.newColorizeTask(
      with: mesh,
      scene: _scene,
      keyframes: _slamState.keyFrameManager.getKeyFrames(),
      completionHandler: { [weak self] error in
        defer { self?._enhancedColorizeTask = nil }
        if self?._enhancedColorizeTask?.isCancelled ?? true {
          return
        } else if error != nil {
          NSLog("Error during enhanced colorizing: \(String(describing: error!.localizedDescription))")
        } else {
          DispatchQueue.main.async { onCompletion(mesh) }
        }
      },
      options: [kSTColorizerTypeKey: type.rawValue,
                kSTColorizerPrioritizeFirstFrameColorKey: _options.prioritizeFirstFrameColor,
                kSTColorizerQualityKey: _options.colorizerQuality.rawValue,
                kSTColorizerTargetNumberOfFacesKey: _options.colorizerTargetNumFaces])
    weak var this: ViewController? = self
    _enhancedColorizeTask!.delegate = this
    return _enhancedColorizeTask!
  }

  func meshViewDidRequestColorizing(
    mesh: STMesh,
    previewCompletionHandler: @escaping () -> Void,
    enhancedCompletionHandler: @escaping () -> Void) -> Bool
  {
    if _holeFillingTask != nil && !_holeFillingTask!.isCancelled
      || _naiveColorizeTask != nil && !_naiveColorizeTask!.isCancelled
      || _enhancedColorizeTask != nil && !_enhancedColorizeTask!.isCancelled
    { // already one running?
      NSLog("Already one task running!")
      return false
    }

    // postprocess mesh
    let holeFillingTask = fillHolesTask(mesh: mesh) { [weak self] mesh in
      guard let this = self else { return }
      let simpleColorizeTask = this.colorizeSimpleTask(mesh: mesh) { [weak self] mesh in
        guard let this = self else { return }

        this._meshViewController!.mesh = mesh
        previewCompletionHandler()

        let enhancedColorizeTask = this.colorizeEnhancedTask(mesh: mesh) { [weak self] mesh in
          guard let this = self else { return }
          this._meshViewController!.mesh = mesh
          enhancedCompletionHandler()
        }
        enhancedColorizeTask.start()
      }
      simpleColorizeTask.start()
    }

    _slamState.mapper.reset()
    _slamState.tracker.reset()

    if holeFillingTask != nil {
      holeFillingTask!.start()
    } else {
      let simpleColorizeTask = colorizeSimpleTask(mesh: mesh) { [weak self] mesh in
        guard let this = self else { return }

        this._meshViewController!.mesh = mesh
        previewCompletionHandler()

        let enhancedColorizeTask = this.colorizeEnhancedTask(mesh: mesh) { [weak self] mesh in
          guard let this = self else { return }
          this._meshViewController!.mesh = mesh
          enhancedCompletionHandler()
        }
        enhancedColorizeTask.start()
      }
      simpleColorizeTask.start()
    }
    return true
  }
}

// MARK: - STBackgroundTaskDelegate
extension ViewController: STBackgroundTaskDelegate {
  func backgroundTask(_ sender: STBackgroundTask!, didUpdateProgress progress: Double) {
    if sender == _naiveColorizeTask {
      DispatchQueue.main.async { [weak self] in
        self?._meshViewController!.showMeshViewerMessage(String(format: "Processing: % 3d%%", Int(progress * 20)))
      }
    } else if sender == _enhancedColorizeTask {
      DispatchQueue.main.async { [weak self] in
        self?._meshViewController!.showMeshViewerMessage(String(format: "Processing: % 3d%%", Int(progress * 80) + 20))
      }
    }
  }
}

// MARK: options

extension ViewController {
  var optionsSet: OptionsSet { return _settingsPopupView!.optionsSet }

  func initializeDynamicOptions() {
    _settingsPopupView = SettingsPopupView(options: makeOptionsSet())
    view.addSubview(_settingsPopupView)
    NSLayoutConstraint.activate([
      _settingsPopupView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20.0), // Pin to top of view, with offset
      _settingsPopupView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 30.0) // Pin to left of view, with offset
    ])
  }

  func makeOptionsSet() -> OptionsSet {
    let optSet = OptionsSet()

    let groupStreaming = OptionsGroup(id: .streamingGroup)
      .addBool(id: .recordOcc, val: _options.recordOcc, onChange: { [weak self] _, val in
        self?._options.recordOcc = val
      })
      .addBool(id: .arKit, val: _options.useARKit, onChange: { [weak self] _, val in
        self?._options.useARKit = val
        self?.streamingSettingsDidChange()
      })
    optSet.groups.append(groupStreaming)

      
//    let groupTracker = OptionsGroup(id: .trackerGroup)
//      .addEnum(id: .trackerType, map: ["Color + Depth", "Depth Only"], val: 0, onChange: { [weak self] (_: OptionId, _: [String], val: Int) in
//        self?._options.depthAndColorTrackerIsOn = val == 1
//        self?.onSLAMOptionsChanged()
//      })
      let savedTrackerType = UserDefaults.standard.string(forKey: "selectedTrackerType") ?? "Depth Only"
    
      let initialTrackerVal = (savedTrackerType == "Color + Depth") ? 0 : 1

      let groupTracker = OptionsGroup(id: .trackerGroup)
        .addEnum(id: .trackerType, map: ["Color + Depth", "Depth Only"], val: initialTrackerVal, onChange: { [weak self] (_: OptionId, options: [String], val: Int) in
          let selectedTracker = options[val]
          UserDefaults.standard.set(selectedTracker, forKey: "selectedTrackerType")
          self?._options.depthAndColorTrackerIsOn = (selectedTracker == "Color + Depth")
          self?.onSLAMOptionsChanged()
      })

      .addEnum(id: .trackingMode, map: ["Object", "Turntable"], val: _options.isTurntableTracker ? 1 : 0, onChange: { [weak self] (_: OptionId, _: [String], _: Int) in
        self?.onSLAMOptionsChanged()
      })
    optSet.groups.append(groupTracker)

    let groupPostprocessing = OptionsGroup(id: .postprocessGroup)
      .addEnum(id: .holeFillingAlgo, map: ["No", "Poisson", "Liepa"], val: 1, onChange: { _, _, _ in })
    optSet.groups.append(groupPostprocessing)

    let groupSlam = OptionsGroup(id: .slamGroup)
      .addFloat(id: .maxRotation,
                val: 20,
                min: 10,
                max: 90,
                minText: "10deg",
                maxText: "90deg",
                style: .slider,
                onChange: { [weak self] _, val in
                  self?._options.maxKeyFrameRotation = CGFloat(Double(val) * (Double.pi / 180)) // 20 degrees
                  self?.onSLAMOptionsChanged()
                })
    optSet.groups.append(groupSlam)

    let calcVoxelSize = { [weak self] in
      guard let this = self else { return }
      let isAdaptive: Bool = this.optionsSet.integer(forKey: .voxelSizeType) == 0
      let highResolutionVolumeBounds: Float = 200
      let voxelSizes: [Float] = [0.001, 0.0015, 0.002, 0.003, 0.004] // in meters
      var voxelSize = voxelSizes[this.optionsSet.integer(forKey: .voxelSize)]
      if isAdaptive {
        voxelSize = keepInRange(this._options.volumeSizeInMeters.x / highResolutionVolumeBounds, min: voxelSize, max: 0.2)
      }
      this._options.voxelSize = voxelSize
      this.onSLAMOptionsChanged()
    }

//    let groupMapper = OptionsGroup(id: .mapperGroup)
//      .addBool(id: .highResolutionMesh, val: true, onChange: { [weak self] (_: OptionId, val: Bool) in
//        self?._options.highResMapping = val
//        self?.onSLAMOptionsChanged()
//      })
      let highResolutionDefault = UserDefaults.standard.object(forKey: "highResolutionMesh") as? Bool ?? true
      let groupMapper = OptionsGroup(id: .mapperGroup)
        .addBool(id: .highResolutionMesh, val: highResolutionDefault, onChange: { [weak self] (_: OptionId, val: Bool) in
          self?._options.highResMapping = val
          UserDefaults.standard.set(val, forKey: "highResolutionMesh") // Save updated value
          self?.onSLAMOptionsChanged()
        })

      .addBool(id: .improvedMapper, val: true, onChange: { [weak self] (_: OptionId, val: Bool) in
        self?._options.improvedMapperIsOn = val
        self?.onSLAMOptionsChanged()
      })
      .addEnum(id: .voxelSizeType, map: ["Adaptive", "Fixed"], val: 1, onChange: { _, _, _ in calcVoxelSize() })
      .addEnum(id: .voxelSize, map: ["1", "1.5", "2", "3", "4"], val: 3, onChange: { _, _, _ in calcVoxelSize() })
    optSet.groups.append(groupMapper)

    let groupApp = OptionsGroup(id: .applicationGroup)
      .addBool(id: .cubeOcclusion, val: _options.drawCubeWithOccluson, onChange: { [weak self] (_: OptionId, val: Bool) in self?._options.drawCubeWithOccluson = val })
      .addBool(id: .showInfo, val: _options.isShowInfo, onChange: { [weak self] (_: OptionId, val: Bool) in self?._options.isShowInfo = val })
    optSet.groups.append(groupApp)

    let handleScanTypeChange: (_ val: Int) -> Void = { [weak self] val in
      guard let this = self else { return }
      if !this._options.alignCubeWithCamera {
        this.showAlert(title: "Error!!!", message: "Turn Off Align Gravity to customize bounding box")
      } else {
        let currentBoxSize = this._options.volumeSizeInMeters
        let (boxDepth, boxDistance) = Scantype.values[val].dimensions
        this.adjustVolumeSize(volumeSize: vector_float3(currentBoxSize.x, currentBoxSize.y, boxDepth))
        this._options.cubeDistanceValue = boxDistance
        this.boxDistanceLabel.text = String.localizedStringWithFormat("Distance %1.2f m", this._options.cubeDistanceValue)
      }
    }
    let handleFootSizeChange: (_ val: Int) -> Void = { [weak self] val in
      guard let this = self else { return }
      if !this._options.alignCubeWithCamera {
        this.showAlert(title: "Error!!!", message: "Turn Off Align Gravity to customize bounding box")
      } else {
        let currentBoxSize = this._options.volumeSizeInMeters
        let (boxWidth, boxLength) = FootSize.values[val].dimensions
        this.adjustVolumeSize(volumeSize: vector_float3(boxWidth, boxLength, currentBoxSize.z))
      }
    }

    let groupBoundingBox = OptionsGroup(id: .boundingBoxGroup)
      .addEnum(id: .scanType, map: ["Foot", "Foot + Ankle"], val: 0, onChange: { _, _, val in handleScanTypeChange(val) })
      .addEnum(id: .footSize, map: ["Small", "Medium", "Large"], val: 1, onChange: { _, _, val in handleFootSizeChange(val) })
    optSet.groups.append(groupBoundingBox)

    return optSet
  }

  func streamingSettingsDidChange() {
    // restart streaming
    setupCaptureSession()
    onSLAMOptionsChanged()
    _captureSession.streamingEnabled = true
  }

  func renderingSettingsDidChange() {
    switch _slamState.scannerState {
    case .cubePlacement:
      _metalData.renderingOption = .cubePlacement
    case .scanning:
      _metalData.renderingOption = .scanning
    case .viewing:
      _metalData.renderingOption = .viewing
    }
  }
}
