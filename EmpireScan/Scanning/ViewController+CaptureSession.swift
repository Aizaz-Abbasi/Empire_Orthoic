/*
 Copyright © 2022 XRPro, LLC. All rights reserved.
 http://structure.io
 */

import Foundation
import Structure
extension ViewController: STCaptureSessionDelegate {
    //Update--
    func videoDeviceSupportsHighResColor() -> Bool {
      // High Resolution Color format is width 2592, height 1936.
      // Most recent devices support this format at 30 FPS.
      // However, older devices may only support this format at a lower framerate.
      // In your Structure Sensor is on firmware 2.0+, it supports depth capture at FPS of 24.

        let testVideoDevice = AVCaptureDevice.default(for: .video)
        if testVideoDevice == nil
        {
    #if targetEnvironment(simulator)
            return false;
    #else
            fatalError("No video device")
    #endif
        }

      for format in testVideoDevice?.formats ?? [] {
        let firstFrameRateRange = format.videoSupportedFrameRateRanges[0]

        let formatMinFps = firstFrameRateRange.minFrameRate
        let formatMaxFps = firstFrameRateRange.maxFrameRate

        if (formatMaxFps < 15) /* Max framerate too low. */ || (formatMinFps > 30) /* Min framerate too high. */ || (formatMaxFps == 24 && formatMinFps > 15) /* We can neither do the 24 FPS max framerate, nor fall back to 15. */ {
          continue
        }

        let videoFormatDesc = format.formatDescription
        let fourCharCode = CMFormatDescriptionGetMediaSubType(videoFormatDesc)

        let formatDims = CMVideoFormatDescriptionGetDimensions(videoFormatDesc)

        if formatDims.width != 2592 {
          continue
        }

        if formatDims.height != 1936 {
          continue
        }

        if format.isVideoBinned {
          continue
        }

        // we only support full range YCbCr for now
        if fourCharCode != 875704422 {
          continue
        }

        // All requirements met.
        return true
      }

      // No acceptable high-res format was found.
      return false
    }
    func captureSession(_ captureSession: STCaptureSession!, sensorDidEnter mode: STCaptureSessionSensorMode) {
        if(STCaptureSessionSensorMode.notConnected==mode){
            
        }else{
            
        }
        
    }
    
    func loadSelectedCameraFromDefaults() -> CameraType {
        if let rawValue = UserDefaults.standard.string(forKey: "selectedSensorType"),
           let camera = CameraType(rawValue: rawValue) {
            return camera
        }
        return .frontCamera // default fallback
    }
    
    func isStructureConnected() -> Bool {
        return _captureSession.sensorMode.rawValue > STCaptureSessionSensorMode.notConnected.rawValue
     }
    
    func setupCaptureSession1() {
        // Clear / reset the capture session if it already exists
        if _captureSession == nil {
            _captureSession = STCaptureSession.new()
        } else {
            _captureSession.streamingEnabled = false
        }
        
        let depthResolution: STCaptureSessionTrueDepthFrameResolution = .resolution640x480
        
        var resolution: STCaptureSessionColorResolution = .resolution640x480
        
        if #available(iOS 11.1, *) {
            guard let videoDevice = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) else {
                return
            }
            let filtered = videoDevice.formats.filter({
                CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            })
            let selectedFormat = filtered.max(by: { first, second in
                CMVideoFormatDescriptionGetDimensions(first.formatDescription).width < CMVideoFormatDescriptionGetDimensions(second.formatDescription).width
            })!
            
            let bestWidth = CMVideoFormatDescriptionGetDimensions(selectedFormat.formatDescription).width
            if bestWidth == 4032 {
                resolution = .resolution4032x3024
            } else if bestWidth == 3264 {
                resolution = .resolution3264x2448 // iPhone X ? 7mp
            }
        }
        
        var sensorConfig: [AnyHashable: Any] = [
            kSTCaptureSessionOptionIOSCameraKey: STCaptureSessionIOSCamera.frontAndTrueDepth.rawValue,
            kSTCaptureSessionOptionColorResolutionKey: resolution.rawValue,
            kSTCaptureSessionOptionTrueDepthFrameResolutionKey: depthResolution.rawValue,
            kSTCaptureSessionOptionColorMaxFPSKey: 30.0,
            kSTCaptureSessionOptionDepthSensorEnabledKey: !_options.isTrueDepthPreferred,
            kSTCaptureSessionOptionUseAppleCoreMotionKey: true,
            kSTCaptureSessionOptionDepthStreamPresetKey: STCaptureSessionPreset.default.rawValue,
            kSTCaptureSessionOptionSimulateRealtimePlaybackKey: true
        ]
        
        if _options.useARKit {
            let arkitConfig = ARFaceTrackingConfiguration()
            if #available(iOS 13, *) {
                arkitConfig.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
            }
            arkitConfig.isLightEstimationEnabled = true
            sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = arkitConfig
        }
        
        // Set the lens detector off, and default lens state as "non-WVL" mode
        _captureSession.lens = STLens.normal
        _captureSession.lensDetection = STLensDetectorState.off
        print("sensorConfig",sensorConfig)
        // Set ourself as the delegate to receive sensor data.
        weak var this: ViewController? = self
        _captureSession.delegate = this
        _captureSession.startMonitoring(options: sensorConfig)
    }
    
    func setupCaptureSession() {
        //let selectedCamera = loadSelectedCameraFromDefaults()
        let sensorType = UserDefaults.standard.string(forKey: "selectedSensorType")
        if _captureSession == nil {
            if(sensorType == "Structure"){
                _captureSession = STCaptureSession.newCaptureSessionWithIOSCameraDisabled()
            }else{
                _captureSession = STCaptureSession.new()//newCaptureSessionWithFrontCameraAndTrueDepth()
            }
//            if(sensorType == "Apple"){
//                _captureSession = STCaptureSession.new()//newCaptureSessionWithFrontCameraAndTrueDepth()
//            }else if(sensorType == "Structure"){
//                _captureSession = STCaptureSession.newCaptureSessionWithIOSCameraDisabled()
//            }
        } else {
            _captureSession.streamingEnabled = false
        }
        
        var iosCamera: STCaptureSessionIOSCamera = STCaptureSessionIOSCamera.frontAndTrueDepth
        var colorResolution: STCaptureSessionColorResolution = .resolution640x480
        let depthResolution: STCaptureSessionTrueDepthFrameResolution = .resolution640x480
        
        var config: StreamingConfig = FrontCameraConfig(colorResolution:_options.highResColoring ? getBestColorResolution(.builtInTrueDepthCamera, position: .front) : .resolution640x480)
        
        if(sensorType == "Apple"){
            
        }else if(sensorType == "Structure"){
            print("Structure")
            config = StructureSensorConfig(colorResolution: _options.highResColoring ? getBestColorResolution(.builtInWideAngleCamera) : .resolution640x480,
                                                       preset: _options.structure.preset)
        }
        
        //var properties: [AnyHashable: Any] = [:]
//        switch selectedCamera {
//        case .lidar: config = LidarConfig(useARKit: _options.useARKit,
//                                          avColorResolution: _options.highResColoring ? getBestColorResolution(.builtInLiDARDepthCamera) : .resolution640x480)
//        case .truedepth: config = TrueDepthConfig(useARKit: _options.useARKit,
//                                                  avColorResolution: _options.highResColoring ? getBestColorResolution(.builtInTrueDepthCamera) : .resolution640x480)
//        case .structure:
//            config = StructureSensorConfig(colorResolution: _options.highResColoring ? getBestColorResolution(.builtInWideAngleCamera) : .resolution640x480,
//                                           preset: _options.structure.preset)
//            properties = _options.structure.properties
//        case .backCamera: config = BackCameraConfig(colorResolution:_options.highResColoring ? getBestColorResolution(.builtInWideAngleCamera) : .resolution640x480)
//        case .frontCamera: config = FrontCameraConfig(colorResolution:_options.highResColoring ? getBestColorResolution(.builtInWideAngleCamera, position: .front) : .resolution640x480)
//            
//        }
        
//        var sensorConfig: [AnyHashable: Any] = [
//            kSTCaptureSessionOptionIOSCameraKey: iosCamera.rawValue,
//            kSTCaptureSessionOptionColorResolutionKey: colorResolution.rawValue,
//            kSTCaptureSessionOptionTrueDepthFrameResolutionKey: depthResolution.rawValue,
//            kSTCaptureSessionOptionColorMaxFPSKey: 30.0,
//            kSTCaptureSessionOptionDepthSensorEnabledKey: (selectedCamera != .truedepth),
//            kSTCaptureSessionOptionUseAppleCoreMotionKey: true,
//            kSTCaptureSessionOptionDepthStreamPresetKey: STCaptureSessionPreset.default.rawValue,
//            kSTCaptureSessionOptionSimulateRealtimePlaybackKey: true
//        ]
        
//        if _options.useARKit && selectedCamera == .truedepth {
//            let arkitConfig = ARFaceTrackingConfiguration()
//            if #available(iOS 13.0, *) {
//                arkitConfig.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
//            }
//            arkitConfig.isLightEstimationEnabled = true
//            sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = arkitConfig
//        }
        print("config.dict",config.dict)
        _captureSession.lens = STLens.normal
        _captureSession.lensDetection = STLensDetectorState.off
        weak var this: ViewController? = self
        _captureSession.delegate = this
        _captureSession.startMonitoring(options: config.dict)
    }
    
    
    // MARK: STCaptureSession delegate methods
    func captureSession(_ captureSession: STCaptureSession!, colorCameraDidEnter mode: STCaptureSessionColorCameraMode) {
        switch mode {
        case STCaptureSessionColorCameraMode.permissionDenied,
            STCaptureSessionColorCameraMode.ready:
            return
            // case STCaptureSessionColorCameraMode.unknown:
        default:
            showAlert(title: "Camera Mode Exception", message: "The color camera has entered an unknown state.")
            assert(false)
        }
        updateAppStatusMessage()
    }
    
    func captureSession(_ captureSession: STCaptureSession!, didStart avCaptureSession: AVCaptureSession) {
        // Initialize our default video device properties once the AVCaptureSession has been started.
        _captureSession.properties = STCaptureSessionPropertiesSetColorCameraAutoExposureISOAndWhiteBalance()
        
        let props: [AnyHashable: Any] = [
            kSTCaptureSessionPropertyIOSCameraFocusModeKey: STCaptureSessionIOSCameraFocusMode.lockedToCustom.rawValue,
            kSTCaptureSessionPropertyIOSCameraFocusValueKey: 0.4
        ]
        _captureSession.properties = props
        
    }
    
    func captureSession(_ captureSession: STCaptureSession!, didStop avCaptureSession: AVCaptureSession) {
        print("didStop avCaptureSession")
    }
    
    func captureSession(_ captureSession: STCaptureSession!, didOutputSample sample: [AnyHashable: Any]?, type: STCaptureSessionSampleType) {
        guard let sample = sample, _slamState != nil else {
            return
        }
        
        var depthFrame: STDepthFrame?
        var colorFrame: STColorFrame?
        switch type {
        case STCaptureSessionSampleType.sensorDepthFrame:
            depthFrame = sample[kSTCaptureSessionSampleEntryDepthFrame] as? STDepthFrame
            
        case STCaptureSessionSampleType.iosColorFrame:
            colorFrame = sample[kSTCaptureSessionSampleEntryIOSColorFrame] as? STColorFrame
            
        case STCaptureSessionSampleType.synchronizedFrames:
            depthFrame = sample[kSTCaptureSessionSampleEntryDepthFrame] as? STDepthFrame
            colorFrame = sample[kSTCaptureSessionSampleEntryIOSColorFrame] as? STColorFrame
            
        case STCaptureSessionSampleType.deviceMotionData:
            let deviceMotion: CMDeviceMotion = sample[kSTCaptureSessionSampleEntryDeviceMotionData] as! CMDeviceMotion
            processDeviceMotion(deviceMotion, with: nil)
            
        case STCaptureSessionSampleType.unknown:
            showAlert(title: "Scanner", message: "Unknown STCaptureSessionSampleType!")
            assert(false)
            
        default:
            showAlert(title: "Scanner", message: "Unknown STCaptureSessionSampleType!")
            assert(false)
        }
        
        if let depthFrame = depthFrame, let colorFrame = colorFrame {
            processDepthFrame(depthFrame, colorFrame: colorFrame)
            if let p = _slamState.getCameraPose() {
                _metalData.update(cameraPose: p)
            }
        }
    }
    
    func processDepthFrame(_ depthFrame: STDepthFrame, colorFrame: STColorFrame?) {
        // Upload the new color image for next rendering.
        if let colorFrame = colorFrame {
            _metalData.update(colorFrame: colorFrame)
        }
        _metalData.update(depthFrame: depthFrame)
        
        switch _slamState.scannerState {
        case .cubePlacement:
            if let colorFrame = colorFrame {
                // If we are using color images but not using registered depth, then use a registered
                // version to detect the cube, otherwise the cube won't be centered on the color image,
                // but on the depth image, and thus appear shifted.
                let registeredDepthFrame = depthFrame.registered(to: colorFrame)!
                _slamState.updatePose(depth: registeredDepthFrame, color: colorFrame, gravity: _lastGravity)
                
                // Enable the scan button if the pose initializer could estimate a pose.
                scanButton.isEnabled = _slamState.hasValidPose()
            }
            
            // calculate if the foot is at the right distance
            let midDepth = calcAverageDepthInMiddle(frame: depthFrame)
            updateDistanceGuides(with: midDepth)
            
        case .scanning:
            _slamState.processFrames(depth: depthFrame, color: colorFrame)
            _metalData.update(mesh: _scene.lockAndGetMesh())
            _scene.unlockMesh()
            
            // Set the mesh transparency depending on the current accuracy.
            updateMeshAlphaForPoseAccuracy(_slamState.tracker.poseAccuracy)
            
            // Update the tracking message.
            let trackingMessage: String? = computeTrackerMessage(_slamState.tracker.trackerHints)
            if let trackingMessage = trackingMessage {
                showTrackingMessage(message: trackingMessage)
            } else if !_slamState.keyframeStatus {
                showTrackingMessage(message: "Please hold still so we can capture a keyframe...")
            } else {
                hideTrackingErrorMessage()
            }
            
            if _options.isShowInfo {
                // show current head rotation to left/right
                infoLabel.text = String(format: "angle is %.1f", _slamState.currentRotation)
            }
            
            // generate feedback if tracking is lost(Sound in iPad and vibration in iPhone)
            //      if _slamState.tracker.trackerHints.trackerIsLost {
            if _slamState.tracker.poseAccuracy.rawValue <= STTrackerPoseAccuracy.low.rawValue {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
                } else {
                    trackingLostSound?.play()
                }
            }
            
        case .viewing:
            break
            // Do nothing, the MeshViewController will take care of this.
        case .numStates:
            break
        }
    }
    
    func updateDistanceGuides(with distance: Float) {
        if !distance.isNaN {
            let minDepthForFootScanning: Float = 220 // in mm
            let maxDepthForFootScanning: Float = 340
            let isDepthOk = distance < maxDepthForFootScanning && distance > minDepthForFootScanning
            let redTargetImage = UIImage(named: "Target_Red")
            let greenTargetImage = UIImage(named: "Target_Green")
            distanceGuideImageView.image = isDepthOk ? greenTargetImage : redTargetImage
            distanceGuideLabel.isHidden = isDepthOk
            if distance > maxDepthForFootScanning {
                distanceGuideLabel.text = "Move Closer"
            } else if distance < minDepthForFootScanning {
                distanceGuideLabel.text = "Step Back"
            }
            // play sound if distance is optimnal
            if isDepthOk {
                distanceGuideSound?.play()
            }
        }
    }
    //
    
}
