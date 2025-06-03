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

//    if useARKit {
//      let arkitConfig = ARWorldTrackingConfiguration()
//      if #available(iOS 11.3, *) {
//        var targetFormat: ARConfiguration.VideoFormat? = nil
//        let targetFps = 60;
//        let targetWidth = 1920;
//        let targetHeight = 1440;
//        for format in ARWorldTrackingConfiguration.supportedVideoFormats {
//          if targetFps == format.framesPerSecond && targetWidth == Int(format.imageResolution.width) &&
//               targetHeight == Int(format.imageResolution.height) {
//            targetFormat = format
//          }
//        }
//        // Set desired video format. By default the first one from the list will be selected,
//        // and it should be the best suited for tracking in according to ARKit documentation.
//        if (targetFormat != nil) {
//          arkitConfig.videoFormat = targetFormat!
//        }
//
//        if #available(iOS 14, *) {
//          let semantics: ARConfiguration.FrameSemantics = ARConfiguration.FrameSemantics(rawValue: arkitConfig.frameSemantics.rawValue | ARConfiguration.FrameSemantics.sceneDepth.rawValue)
//          if ARWorldTrackingConfiguration.supportsFrameSemantics(semantics) {
//            arkitConfig.frameSemantics = semantics
//          }
//        }
//      }
//
//      sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = arkitConfig
//    } else {
      //sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = NSObject()
      sensorConfig[kSTCaptureSessionOptionColorResolutionKey] = avColorResolution.rawValue
      sensorConfig[kSTCaptureSessionOptionLiDARFrameResolutionKey] = avDepthResolution.rawValue
   // }
    return sensorConfig
  }
}

struct TrueDepthConfig: StreamingConfig {
  var useARKit = false
  var avColorResolution: STCaptureSessionColorResolution = getBestColorResolution(.builtInTrueDepthCamera)
  var avDepthResolution: STCaptureSessionTrueDepthFrameResolution = .resolution640x480
  var fps: Float = 30.0
  var disparityDepthFormat = false

//  var arkitConfig: ARConfiguration? {
//    if !useARKit {
//      return nil
//    }
//
//    let arkitConfig = ARFaceTrackingConfiguration()
//    if #available(iOS 13, *) {
//      arkitConfig.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
//    }
//    arkitConfig.isLightEstimationEnabled = true
//    return arkitConfig
//  }

  var dict: [AnyHashable: Any] {
    var sensorConfig: [AnyHashable: Any] = [
      kSTCaptureSessionOptionDepthSensorEnabledKey: false,
      kSTCaptureSessionOptionIOSCameraKey: STCaptureSessionIOSCamera.frontAndTrueDepth.rawValue,
      kSTCaptureSessionOptionUseAppleCoreMotionKey: true,
      kSTCaptureSessionOptionColorResolutionKey: avColorResolution.rawValue,
      kSTCaptureSessionOptionTrueDepthFrameResolutionKey: avDepthResolution.rawValue,
      kSTCaptureSessionOptionColorMaxFPSKey: fps,
    ]
 
//    if let conf = arkitConfig {
//      sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = conf
//    } else {
//      sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = NSObject() // set default option
//    }

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
      kSTCaptureSessionOptionSimulateRealtimePlaybackKey: true,
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

    //sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = NSObject() // set default option
    return sensorConfig
  }

}

struct BackCameraConfig : StreamingConfig {
  var colorResolution: STCaptureSessionColorResolution = getBestColorResolution(.builtInWideAngleCamera)
  
  var dict: [AnyHashable: Any] {
    var sensorConfig: [AnyHashable: Any] = [
      kSTCaptureSessionOptionColorResolutionKey: colorResolution.rawValue,
      kSTCaptureSessionOptionColorMaxFPSKey: 30.0,
      kSTCaptureSessionOptionIOSCameraKey: STCaptureSessionIOSCamera.backAndLiDAR.rawValue,
      kSTCaptureSessionOptionDepthSensorEnabledKey: false,
      kSTCaptureSessionOptionUseAppleCoreMotionKey: true,
      kSTCaptureSessionOptionSimulateRealtimePlaybackKey: true,
    ]

    //sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = NSObject()
    return sensorConfig
  }
}

struct FrontCameraConfig : StreamingConfig {
    var colorResolution: STCaptureSessionColorResolution = getBestColorResolution(.builtInTrueDepthCamera, position: .front)
  
  var dict: [AnyHashable: Any] {
    var sensorConfig: [AnyHashable: Any] = [
      kSTCaptureSessionOptionColorResolutionKey: colorResolution.rawValue,
      kSTCaptureSessionOptionColorMaxFPSKey: 30.0,
      kSTCaptureSessionOptionIOSCameraKey: STCaptureSessionIOSCamera.frontAndTrueDepth.rawValue,
      kSTCaptureSessionOptionDepthSensorEnabledKey: false,
      kSTCaptureSessionOptionUseAppleCoreMotionKey: true,
      kSTCaptureSessionOptionSimulateRealtimePlaybackKey: true,
    ]
    //sensorConfig[kSTCaptureSessionOptionUseARKitConfigurationKey] = NSObject()
    return sensorConfig
  }
}

var lidarAvailable:Bool {
  return AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back) != nil
}

let isPhone = UIDevice.current.userInterfaceIdiom == .phone
var structureSensorAvailable:Bool { !isPhone }

var truedepthAvailable:Bool {
  return AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) != nil
}

let defaultSensor:DepthSensor = {
  if !lidarAvailable && !structureSensorAvailable {
    return .truedepth
  } else if lidarAvailable || !structureSensorAvailable {
    return .lidar
  } else {
    return .structure
  }
}()

struct StreamingOptions {
  var sensor: DepthSensor = defaultSensor
  var structure = StructureOptions()
  var useARKit = false
  var lockFocus = true // lock auto focus during scanning
  var highResColor = false // high res vs VGA color resolution
}

struct StructureOptions {
  var preset: STCaptureSessionPreset = .default
  var irAutoExposure = true
  var irManualExposure: Float = 0.015 // 1ms-16ms, in seconds, relevant when auto exposure is false
  var irAnalogGain: STCaptureSessionSensorAnalogGainMode = .mode2_0

  var properties: [AnyHashable: any Equatable] {
    [
      kSTCaptureSessionPropertySensorIRExposureModeKey:
      (irAutoExposure ? STCaptureSessionSensorExposureMode.auto.rawValue : STCaptureSessionSensorExposureMode.lockedToCustom.rawValue),
      kSTCaptureSessionPropertySensorIRExposureValueKey: irManualExposure,
      kSTCaptureSessionPropertySensorIRAnalogGainValueKey: irAnalogGain.rawValue
    ]
  }

  func hasEqualProperties(_ opt: StructureOptions)->Bool {
    return irAutoExposure == opt.irAutoExposure
      && irManualExposure == opt.irManualExposure
      && irAnalogGain == opt.irAnalogGain
  }
}

enum CameraType: String, Codable {
  case lidar
  case truedepth
  case structure
  case backCamera
  case frontCamera
}


enum DepthSensor: CustomStringConvertible {
  case lidar
  case truedepth
  case structure
  case backCamera
  case frontCamera

  var isAvailable: Bool {
      print("lidarAvailable===?",lidarAvailable,truedepthAvailable)
    switch self {
    case .lidar: return lidarAvailable
    case .truedepth: return truedepthAvailable
    case .structure: return structureSensorAvailable
    case .backCamera: return true
    case .frontCamera: return true
    }
  }

  var description: String {
    switch self {
    case .lidar: return "LiDAR"
    case .truedepth: return "TrueDepth"
    case .structure: return "Structure Sensor"
    case .backCamera: return "Back camera"
    case .frontCamera: return "Front camera"
    }
  }

  var videoDevice: AVCaptureDevice? {
    switch self {
    case .lidar: return AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back)
    case .truedepth: return AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front)
    case .structure: return AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back)
    case .backCamera: return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    case .frontCamera: return AVCaptureDevice.default(.builtInWideAngleCamera , for: .video, position: .front)
    }
  }
}
