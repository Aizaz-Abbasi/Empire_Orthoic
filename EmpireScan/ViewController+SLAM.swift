/*
 Copyright © 2022 XRPro, LLC. All rights reserved.
 http://structure.io
 */

import simd
import Structure
func calcDeltaRotation(_ previousPose: float4x4, newPose: float4x4) -> Float {
  // Transpose is equivalent to inverse since we will only use the rotation part.
  let deltaPose: float4x4 = newPose * previousPose.transpose

  // Get the rotation component of the delta pose
  let deltaRotationAsQuaternion = simd_quatf(deltaPose)

  // Get the angle of the rotation
  let angleInDegree = deltaRotationAsQuaternion.angle / Float.pi * 180
  return angleInDegree
}

func computeTrackerMessage(_ hints: STTrackerHints) -> String? {
  if hints.trackerIsLost { return "Tracking Lost! Please Realign or Press Restart." }
  if hints.modelOutOfView { return "Please put the model back in view." }
  if hints.sceneIsTooClose { return "Too close to the scene! Please step back." }
  return nil
}

// SLAM-related members.
class SlamData {
  var tracker: STTracker
  var mapper: STMapper
  var cameraPoseInitializer: STCameraPoseInitializer
  var keyFrameManager: STKeyFrameManager
  var scannerState: ScannerState = .cubePlacement
  private var initialDepthCameraPose: float4x4 = float4x4.identity()
  private var initialColorCameraPose: float4x4 = float4x4.identity()
  private var cameraPose: float4x4 = float4x4.identity()
  var keyframeStatus: Bool = true
  var arkitToWorld: simd_float4x4 { simd_float4x4(SCNMatrix4MakeTranslation(_options.volumeSizeInMeters.x / 2, _options.volumeSizeInMeters.y / 2, _options.volumeSizeInMeters.z / 2)) }

  private var prevFrameTimeStamp: TimeInterval = -1
  private var _options: Options

  var currentRotation: Float {
    if scannerState != .scanning {
      return 0
    }

    let initial: GLKMatrix4 = tracker.initialCameraPose     // initial transformation from camera to world (mesh) space
    let current: GLKMatrix4 = tracker.lastFrameCameraPose() // current transformation from camera to world (mesh) space

    // initial direction 'up'
    let x1 = matrix_float4x4(initial) * vector_float4(1, 0, 0, 0)

    // initial direction 'front'
    let z1 = matrix_float4x4(initial) * vector_float4(0, 0, 1, 0)

    // current direction 'front'
    let z2 = matrix_float4x4(current) * vector_float4(0, 0, 1, 0)

    // remove vertical component from the axes
    let proj = x1
    let axis1 = simd_normalize(z1 - proj * dot(z1, proj))
    let axis2 = simd_normalize(z2 - proj * dot(z2, proj))

    // calc angle between the axes
    let cos = simd_clamp(dot(axis1, axis2), -1.0, 1.0)
    let angle = GLKMathRadiansToDegrees(acos(cos))
    return angle
  }

  init(
    scene: STScene,
    options: Options
  ) {
    // Initialize the scene.
    _options = options

    // Initialize the camera pose tracker.
    let trackerOptions: [AnyHashable: Any] = [
      kSTTrackerTypeKey: options.depthAndColorTrackerIsOn ? STTrackerType.depthAndColorBased.rawValue : STTrackerType.depthBased.rawValue,
      kSTTrackerTrackAgainstModelKey: true, // tracking against the model is much better for close range scanning.
      kSTTrackerQualityKey: STTrackerQuality.accurate.rawValue,
      kSTTrackerBackgroundProcessingEnabledKey: true,
      kSTTrackerSceneTypeKey: options.isTurntableTracker ? STTrackerSceneType.objectOnTurntable.rawValue : STTrackerSceneType.object.rawValue,
      kSTTrackerLegacyKey: false, // use "improved tracker"
      kSTTrackerMinimumDepthForICPKey: 0.1 // min distance 0.1m
    ]
    // Initialize the camera pose tracker.
    tracker = STTracker(scene: scene, options: trackerOptions)

    // The mapper will be initialized when we start scanning.
    if !options.fixedCubePosition {   // Setup the cube placement initializer.
      cameraPoseInitializer = STCameraPoseInitializer(volumeSizeInMeters: options.volumeSizeInMeters.toGLK(), options: [kSTCameraPoseInitializerStrategyKey: STCameraPoseInitializerStrategy.tableTopCube.rawValue])
    } else {   // Setup the cube placement initializer.
      cameraPoseInitializer = STCameraPoseInitializer(volumeSizeInMeters: options.volumeSizeInMeters.toGLK(), options: [kSTCameraPoseInitializerStrategyKey: STCameraPoseInitializerStrategy.gravityAlignedAtVolumeCenter.rawValue])
    }

    let keyframeManagerOptions: [AnyHashable: Any] = [
      kSTKeyFrameManagerMaxSizeKey: options.maxNumKeyFrames,
      kSTKeyFrameManagerMaxDeltaTranslationKey: options.maxKeyFrameTranslation,
      kSTKeyFrameManagerMaxDeltaRotationKey: options.maxKeyFrameRotation]

    keyFrameManager = STKeyFrameManager(options: keyframeManagerOptions)

    // MARK: Setup mapper
    let voxelSize = options.voxelSize

    // Compute the volume bounds in voxels, as a multiple of the volume resolution.
    let volumeBounds = GLKVector3(v: (roundf(options.volumeSizeInMeters.x / voxelSize),
      roundf(options.volumeSizeInMeters.y / voxelSize),
      roundf(options.volumeSizeInMeters.z / voxelSize)
    ))

    NSLog("[Mapper] volumeSize (m): %f %f %f volumeBounds: %.0f %.0f %.0f (resolution=%f m)",
      options.volumeSizeInMeters.x, options.volumeSizeInMeters.y, options.volumeSizeInMeters.z,
      volumeBounds.x, volumeBounds.y, volumeBounds.z,
      voxelSize)

    let mapperOptions: [AnyHashable: Any] =
      [kSTMapperLegacyKey: !options.improvedMapperIsOn,
       kSTMapperVolumeResolutionKey: voxelSize,
       kSTMapperVolumeBoundsKey: [volumeBounds.x, volumeBounds.y, volumeBounds.z],
       kSTMapperVolumeHasSupportPlaneKey: cameraPoseInitializer.lastOutput.hasSupportPlane.boolValue,
       kSTMapperEnableLiveWireFrameKey: false,
       kSTMapperEnableDepthFilteringKey: options.useDepthFiltering
      ]

    mapper = STMapper(scene: scene, options: mapperOptions)
  }

  deinit {
    // It is important to reset the SLAM algorithms before deallocating them
    tracker.reset()
    mapper.reset()
  }

  func hasValidPose() -> Bool {
    return cameraPoseInitializer.lastOutput.hasValidPose.boolValue
  }

  func updatePose(depth registeredDepthFrame: STDepthFrame, color colorFrame: STColorFrame, gravity gravityVector: vector_float3) {
    // Estimate the new scanning volume position.
    let iOSColorFromDepthExtrinsics: float4x4 = float4x4(registeredDepthFrame.iOSColorFromDepthExtrinsics())
    if length(gravityVector) > 1e-5 {
      do {
        try cameraPoseInitializer.updateCameraPose(withGravity: gravityVector.toGLK(), depthFrame: registeredDepthFrame)
        // Since we potentially detected the cube in a registered depth frame, also save the pose
        // in the original depth sensor coordinate system since this is what we'll use for SLAM
        // to get the best accuracy.
        initialDepthCameraPose = float4x4(cameraPoseInitializer.lastOutput.cameraPose) * iOSColorFromDepthExtrinsics
        if _options.fixedCubePosition {
          initialDepthCameraPose = initialDepthCameraPose.translate(0, 0, -_options.cubeDistanceValue)
        }
      } catch {
        NSLog("Camera pose initializer error.")
      }

      initialColorCameraPose = initialDepthCameraPose
    }
  }

  func getCameraPose() -> float4x4? {
    if scannerState == .cubePlacement {
      if cameraPoseInitializer.lastOutput.hasValidPose.boolValue
           || _options.useARKit && _options.useARKitTracking {
        return initialColorCameraPose
      } else {
        return nil
      }
    } else { //  if scannerState == .scanning
      return cameraPose
    }
  }

  func processFrames(depth depthFrame: STDepthFrame, color colorFrame: STColorFrame?) {
    guard scannerState == .scanning else {
      return
    }

    // First try to estimate the 3D pose of the new frame.
    var depthCameraPoseBeforeTracking: float4x4
    do {
      depthCameraPoseBeforeTracking = float4x4(tracker.lastFrameCameraPose())
      try tracker.updateCameraPose(with: depthFrame, colorFrame: colorFrame)
    } catch let trackingError as NSError {
      NSLog("[Structure] STTracker Error: %@.", trackingError.localizedDescription)
    }

    cameraPose = float4x4(tracker.lastFrameCameraPose())
    if _options.useColorCamera {
      cameraPose = cameraPose * float4x4(depthFrame.iOSColorFromDepthExtrinsics()).inverse
    }

    // If the tracker accuracy is high, use this frame for mapper update and maybe as a keyframe too.
    if tracker.poseAccuracy.rawValue >= STTrackerPoseAccuracy.high.rawValue {
      mapper.integrateDepthFrame(depthFrame, cameraPose: tracker.lastFrameCameraPose())
    }

    // Only consider adding a new keyframe if the accuracy is high enough.
    if let colorFrame = colorFrame, tracker.poseAccuracy.rawValue >= STTrackerPoseAccuracy.approximate.rawValue {
      keyframeStatus = tryAddKeyframeWithDepthFrame(depthFrame, colorFrame: colorFrame, depthCameraPoseBeforeTracking: depthCameraPoseBeforeTracking)
    }
    prevFrameTimeStamp = depthFrame.timestamp
  }

  private func tryAddKeyframeWithDepthFrame(_ depthFrame: STDepthFrame, colorFrame: STColorFrame, depthCameraPoseBeforeTracking: float4x4) -> Bool {
    // Make sure the pose is in color camera coordinates in case we are not using registered depth.
    let iOSColorFromDepthExtrinsics = float4x4(depthFrame.iOSColorFromDepthExtrinsics())
    let depthCameraPoseAfterTracking = float4x4(tracker.lastFrameCameraPose())
    let colorCameraPoseAfterTracking = (depthCameraPoseAfterTracking * iOSColorFromDepthExtrinsics.inverse).toGLK()

    // Check if the viewpoint has moved enough to add a new keyframe
    // OR if we don't have a keyframe yet
    if keyFrameManager.wouldBeNewKeyframe(withColorCameraPose: colorCameraPoseAfterTracking) {
      let isFirstFrame = prevFrameTimeStamp < 0
      let seconds = Float(depthFrame.timestamp - prevFrameTimeStamp)
      let maxSpeed = Float(_options.maxKeyframeRotationSpeedInDegreesPerSecond)
      let angularSpeed = calcDeltaRotation(depthCameraPoseBeforeTracking, newPose: depthCameraPoseAfterTracking) / seconds
      let canAddKeyframe = isFirstFrame || angularSpeed < maxSpeed

      if canAddKeyframe {
        keyFrameManager.processKeyFrameCandidate(
          withColorCameraPose: colorCameraPoseAfterTracking,
          colorFrame: colorFrame,
          depthFrame: nil) // Spare the depth frame memory, since we do not need it in keyframes.
      } else {
        return false
      }
    }
    return true
  }

}

// MARK: - SLAM
extension ViewController {

  func resetSLAM() {
    _slamState = nil
    _scene.clear()
    _slamState = SlamData(scene: _scene, options: _options)

    // Set up the initial volume size.
    adjustVolumeSize(volumeSize: _options.volumeSizeInMeters)
  }

  func updateMeshAlphaForPoseAccuracy(_ poseAccuracy: STTrackerPoseAccuracy) {
    switch poseAccuracy {
    case .high, .approximate:
      _metalData.meshRenderingAlpha = 0.8
    case .low:
      _metalData.meshRenderingAlpha = 0.4
    case .veryLow, .notAvailable:
      _metalData.meshRenderingAlpha = 0.1
    @unknown default:
      NSLog("STTracker unknown pose accuracy.")
      _metalData.meshRenderingAlpha = 0.1
    }
  }

  func calcAverageDepthInMiddle(frame depthFrame: STDepthFrame) -> Float {
    // calculate average depth of the middle square 20x20 pixels
    let window = 10
    let makeRange = { (size: Int) in (Int(size / 2) - window)...(Int(size / 2) + window) }

    var nPixel = 0
    var midDepth: Float = 0
    for i in makeRange(Int(depthFrame.height)) {
      for j in makeRange(Int(depthFrame.width)) {
        let depth: Float = depthFrame.depthInMillimeters[i * Int(depthFrame.width) + j]
        if !depth.isNaN {
          midDepth += depth
          nPixel += 1
        }
      }
    }

    midDepth /= Float(nPixel)
    return midDepth
  }
}
