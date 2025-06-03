import Foundation

protocol StreamingConfig {
  var dict: [AnyHashable: Any] { get }
}


func getBestColorResolution(_ device: AVCaptureDevice.DeviceType, position: AVCaptureDevice.Position = .back)->STCaptureSessionColorResolution {
  guard let videoDevice = AVCaptureDevice.default(device, for: .video, position: position) else {
    return .resolution640x480
  }

  var resolution: STCaptureSessionColorResolution = .resolution640x480
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

  return resolution
}

struct LidarConfig : StreamingConfig {
  var planeDetection = false
  var ARKitMeshing = true
  var useARSCNView = true
  var useARKit = false
  var avColorResolution: STCaptureSessionColorResolution = getBestColorResolution(.builtInLiDARDepthCamera)
  var avDepthResolution: STCaptureSessionLiDARFrameResolution = .resolution320x240

  var dict: [AnyHashable: Any] {

    var sensorConfig: [AnyHashable: Any] = [
      kSTCaptureSessionOptionColorMaxFPSKey: 30.0,
      kSTCaptureSessionOptionIOSCameraKey: STCaptureSessionIOSCamera.backAndLiDAR.rawValue,
      kSTCaptureSessionOptionDepthSensorEnabledKey: false,
      kSTCaptureSessionOptionUseAppleCoreMotionKey: true,
      kSTCaptureSessionOptionSimulateRealtimePlaybackKey: true,
    ]

    if useARKit {
      let arkitConfig = ARWorldTrackingConfiguration()
      if #available(iOS 11.3, *) {
        var targetFormat: ARConfiguration.VideoFormat? = nil
        let targetFps = 60;
        let targetWidth = 1920;
        let targetHeight = 1440;
        for format in ARWorldTrackingConfiguration.supportedVideoFormats {
          if targetFps == format.framesPerSecond && targetWidth == Int(format.imageResolution.width) &&
               targetHeight == Int(format.imageResolution.height) {
            targetFormat = format
          }
        }
        // Set desired video format. By default the first one from the list will be selected,
        // and it should be the best suited for tracking in according to ARKit documentation.
        if (targetFormat != nil) {
          arkitConfig.videoFormat = targetFormat!
        }

        if #available(iOS 14, *) {
          let semantics: ARConfiguration.FrameSemantics = ARConfiguration.FrameSemantics(rawValue: arkitConfig.frameSemantics.rawValue | ARConfiguration.FrameSemantics.sceneDepth.rawValue)
          if ARWorldTrackingConfiguration.supportsFrameSemantics(semantics) {
            arkitConfig.frameSemantics = semantics
          }
        }
      }

      sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = arkitConfig
    } else {
      sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = NSObject()
      sensorConfig[kSTCaptureSessionOptionColorResolutionKey] = avColorResolution.rawValue
      sensorConfig[kSTCaptureSessionOptionLiDARFrameResolutionKey] = avDepthResolution.rawValue
    }
    return sensorConfig
  }
}

struct TrueDepthConfig: StreamingConfig {
  var useARKit = false
  var avColorResolution: STCaptureSessionColorResolution = getBestColorResolution(.builtInTrueDepthCamera)
  var avDepthResolution: STCaptureSessionTrueDepthFrameResolution = .resolution640x480
  var fps: Float = 30.0
  var disparityDepthFormat = false

  var arkitConfig: ARConfiguration? {
    if !useARKit {
      return nil
    }

    let arkitConfig = ARFaceTrackingConfiguration()
    if #available(iOS 13, *) {
      arkitConfig.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
    }
    arkitConfig.isLightEstimationEnabled = true
    return arkitConfig
  }

  var dict: [AnyHashable: Any] {
    var sensorConfig: [AnyHashable: Any] = [
      kSTCaptureSessionOptionDepthSensorEnabledKey: false,
      kSTCaptureSessionOptionIOSCameraKey: STCaptureSessionIOSCamera.frontAndTrueDepth.rawValue,
      kSTCaptureSessionOptionUseAppleCoreMotionKey: true,
      kSTCaptureSessionOptionColorResolutionKey: avColorResolution.rawValue,
      kSTCaptureSessionOptionTrueDepthFrameResolutionKey: avDepthResolution.rawValue,
      kSTCaptureSessionOptionColorMaxFPSKey: fps,
    ]
 
    if let conf = arkitConfig {
      sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = conf
    } else {
      sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = NSObject() // set default option
    }

    return sensorConfig
  }

}

struct StructureSensorConfig: StreamingConfig {
  var windowWidth: Int = 15
  var windowHeight: Int = 11
  var colorResolution: STCaptureSessionColorResolution = getBestColorResolution(.builtInWideAngleCamera)
  var depthResolution: STCaptureSessionDepthFrameResolution = .resolution640x480
  var irResolution: STCaptureSessionIrFrameResolution = .resolution640x488
  var irEnabled = false
  var depthEnabled = true
  var preset: STCaptureSessionPreset = .default
  var useDefaults = false

  var dict: [AnyHashable: Any] {
    var sensorConfig: [AnyHashable: Any] = [

      kSTCaptureSessionOptionIOSCameraKey: STCaptureSessionIOSCamera.back.rawValue,
      kSTCaptureSessionOptionColorMaxFPSKey: 30.0,
      kSTCaptureSessionOptionDepthSensorEnabledKey: true,
      kSTCaptureSessionOptionUseAppleCoreMotionKey: true,
      kSTCaptureSessionOptionDepthStreamPresetKey: preset.rawValue,
      // kSTCaptureSessionOptionSimulateRealtimePlaybackKey: true,
    ]

    if !useDefaults {
      sensorConfig[kSTCaptureSessionOptionDepthSearchWindowKey] = [
        NSNumber(value: windowWidth),
        NSNumber(value: windowHeight)
      ]
      sensorConfig[kSTCaptureSessionOptionColorResolutionKey] = colorResolution.rawValue
      sensorConfig[kSTCaptureSessionOptionDepthFrameResolutionKey] = depthResolution.rawValue
      sensorConfig[kSTCaptureSessionOptionIrFrameResolutionKey] = irResolution.rawValue
      sensorConfig[kSTCaptureSessionOptionInfraredSensorEnabledKey] = irEnabled
      sensorConfig[kSTCaptureSessionOptionDepthSensorEnabledKey] = depthEnabled
    }

    sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = NSObject() // set default option

    return sensorConfig
  }

}

struct BackCameraConfig : StreamingConfig {
  var colorResolution: STCaptureSessionColorResolution = getBestColorResolution(.builtInWideAngleCamera)
  
  var dict: [AnyHashable: Any] {
    var sensorConfig: [AnyHashable: Any] = [
      kSTCaptureSessionOptionColorResolutionKey: colorResolution.rawValue,
      kSTCaptureSessionOptionColorMaxFPSKey: 30.0,
      kSTCaptureSessionOptionIOSCameraKey: STCaptureSessionIOSCamera.back.rawValue,
      kSTCaptureSessionOptionDepthSensorEnabledKey: false,
      kSTCaptureSessionOptionUseAppleCoreMotionKey: true,
      kSTCaptureSessionOptionSimulateRealtimePlaybackKey: true,
    ]

    sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = NSObject()
    return sensorConfig
  }
}

struct FrontCameraConfig : StreamingConfig {
  var colorResolution: STCaptureSessionColorResolution = getBestColorResolution(.builtInWideAngleCamera, position: .front)
  
  var dict: [AnyHashable: Any] {
    var sensorConfig: [AnyHashable: Any] = [
      kSTCaptureSessionOptionColorResolutionKey: colorResolution.rawValue,
      kSTCaptureSessionOptionColorMaxFPSKey: 30.0,
      kSTCaptureSessionOptionIOSCameraKey: STCaptureSessionIOSCamera.front.rawValue,
      kSTCaptureSessionOptionDepthSensorEnabledKey: false,
      kSTCaptureSessionOptionUseAppleCoreMotionKey: true,
      kSTCaptureSessionOptionSimulateRealtimePlaybackKey: true,
    ]

    sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = NSObject()
    return sensorConfig
  }
}
