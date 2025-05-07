/*
 Copyright © 2022 XRPro, LLC. All rights reserved.
 http://structure.io
 */

import MetalKit
import Structure 

enum DepthResolution: Int {
  case qvga = 0
  case vga = 1
  case full = 2
}

enum FootSize {
  case small
  case medium
  case large

  var dimensions: (width: Float, length: Float) {
    switch self {
    case .small:
      return (0.15, 0.20)
    case .medium:
      return (0.2, 0.3)
    case .large:
      return (0.28, 0.38)
    }
  }
  static let values = [small, medium, large]
}

enum Scantype {
  case foot
  case footPlusAnkle

  var dimensions: (depth: Float, distance: Float) {
    switch self {
    case .foot:
      return (0.3, 0.25)
    case .footPlusAnkle:
      return (0.6, 0.35)
    }
  }
  static let values = [foot, footPlusAnkle]
}

// Volume resolution in meters
class Options {
  // The initial scanning volume size will be 0.2 x 0.3 x 0.3 meters
  // (X is left-right, Y is up-down, Z is forward-back)
  var volumeSizeInMeters = vector_float3(0.2, 0.3, 0.3) // For Medium Size Foot Scan

  // The maximum number of keyframes saved in keyFrameManager
  var maxNumKeyFrames: Int = 48

  // Colorizer quality
  var colorizerQuality: STColorizerQuality = STColorizerQuality.normalQuality

  // Take a new keyframe in the rotation difference is higher than 20 degrees.
  var maxKeyFrameRotation: CGFloat = CGFloat(20 * (Double.pi / 180)) // 20 degrees in radians

  // Take a new keyframe if the translation difference is higher than 30 cm.
  var maxKeyFrameTranslation: CGFloat = 0.3 // 30cm

  // Threshold to consider that the rotation motion was small enough for a frame to be accepted
  // as a keyframe. This avoids capturing keyframes with strong motion blur / rolling shutter.
  var maxKeyframeRotationSpeedInDegreesPerSecond: CGFloat = 3

  // Whether the colorizer should try harder to preserve appearance of the first keyframe.
  // Recommended for face scans.
  var prioritizeFirstFrameColor: Bool = true

  // Target number of faces of the final textured mesh.
  var colorizerTargetNumFaces: Int = 50000

  // Focus position for the color camera (between 0 and 1). Must remain fixed one depth streaming
  // has started when using hardware registered depth.
  let lensPosition: CGFloat = 0.75

  let useColorCamera = true

  let isTrueDepthPreferred = true

  // dynamic options:
  var alignCubeWithCamera: Bool = true
  var fixedCubePosition: Bool = true

  // Initial distance to the scanning volume cube
  var cubeDistanceValue: Float = 0.25 // in meters
  var depthAndColorTrackerIsOn: Bool = false
  var highResColoring: Bool = true
  var improvedMapperIsOn: Bool = true
  var highResMapping: Bool = true
  // var depthResolution: DepthResolution = .vga
  var drawCubeWithOccluson: Bool = true
  var useARKit: Bool = false
  var useARKitTracking: Bool = true
  var alignFinalMesh: Bool = false
  var isTurntableTracker: Bool = true
  var voxelSize: Float = 0.003 // 3mm
  var isShowInfo: Bool = false
  var recordOcc: Bool = false
  var useDepthFiltering: Bool = false
}

enum ScannerState: Int {
  case cubePlacement = 0    // Defining the volume to scan
  case scanning            // Scanning
  case viewing            // Visualizing the mesh
}

// Utility struct to manage a gesture-based scale.
struct PinchScaleState {

  var currentScale: CGFloat = 1
  var initialPinchScale: CGFloat = 1
}

func keepInRange(_ value: Float, min minValue: Float, max maxValue: Float) -> Float {
  if value.isNaN {
    return minValue
  }
  if value > maxValue {
    return maxValue
  }
  if value < minValue {
    return minValue
  }
  return value
}

struct AppStatus {
  let needColorCameraAccessMessage = "This app requires camera access to capture color.\nAllow access by going to Settings → Privacy → Camera."
  let finalizingMeshMessage = "Finalizing model..."
  let needLicense = "Something went wrong please try again" //" This app requires Structure SDK license."

  // Whether there is currently a message to show.
  var needsDisplayOfStatusMessage = false

  // Flag to disable entirely status message display.
  var statusMessageDisabled = false
}

extension UIViewController {
  func showAlert(title: String, message: String) {
    let alert = UIAlertController(title: title,
      message: message,
      preferredStyle: .alert)

    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(defaultAction)
    present(alert, animated: true, completion: nil)
  }
}

class CircleView: UIView {
  private var _color: UIColor = UIColor.red

  var lineWidth: CGFloat = 3.0
  var color: UIColor {
    get { return _color }
    set {
      if newValue != _color {
        _color = newValue
        self.setNeedsDisplay()
      }
    }
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    backgroundColor = UIColor.clear
    isUserInteractionEnabled = false
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  override func draw(_ rect: CGRect) {
    // Get the Graphics Context
    if let context = UIGraphicsGetCurrentContext() {

      // Set the circle outerline-width
      context.setLineWidth(lineWidth)

      // Set the circle outerline-colour
      color.set()

      let ellipseRect = CGRect(
        x: rect.minX + lineWidth / 2,
        y: rect.minY + lineWidth / 2,
        width: rect.width - lineWidth,
        height: rect.height - lineWidth)
      context.addEllipse(in: ellipseRect)

      // Draw
      context.strokePath()
    }
  }
}
