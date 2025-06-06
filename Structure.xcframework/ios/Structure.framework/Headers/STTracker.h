/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Structure/StructureBase.h>
#import <Structure/STDepthFrame.h>
#import <Structure/STTracker+Types.h>
#import <Structure/STScene.h>

#import <CoreMotion/CoreMotion.h>

#pragma mark - STTracker API

/** A STTracker instance tracks the 3D position of the Structure Sensor.

It uses sensor information and optionally IMU data to estimate how the camera is being moved over time, in real-time.

## See Also
 - ``STTrackerType``
*/
@interface STTracker : NSObject

/// STScene object storing common SLAM information.
@property(nonatomic, retain) STScene* _Nonnull scene;

/// The initial camera pose. Tracking will use this as the first frame pose.
@property(nonatomic) GLKMatrix4 initialCameraPose;

/** The current tracker hints.

## See Also
- ``STTrackerHints``
- ``STTracker/poseAccuracy``
*/
@property(nonatomic, readonly) STTrackerHints trackerHints;

/** The current tracker pose accuracy.

## See Also
- ``STTrackerPoseAccuracy``
- ``STTracker/trackerHints``
*/
@property(nonatomic, readonly) STTrackerPoseAccuracy poseAccuracy;

/** STTracker initialization.

 STTracker cannot be used until an STScene has been provided.

 Sample usage:
```objc
NSDictionary* options = @{
    kSTTrackerTypeKey                       = @(STTrackerDepthBased),
    kSTTrackerQualityKey                    = @(STTrackerQualityAccurate),
    kSTTrackerTrackAgainstModelKey          = @YES,
    kSTTrackerAcceptVaryingColorExposureKey = @NO,
    kSTTrackerBackgroundProcessingEnabledKey= @YES,
    kSTTrackerLegacyKey                     = @NO,
    kSTTrackerSceneTypeKey                  = @(STTrackerSceneTypeObject)
};
STTracker* tracker = [[STTracker alloc] initWithScene:myScene options:options];
```

- Parameter scene: The STScene context.
- Parameter options: Dictionary of options. The valid keys are:

 - `kSTTrackerTypeKey`:
  - Specifies the tracking algorithm.
  - NSNumber integral value equal to one the STTrackerType constants.
  - Required.
 - `kSTTrackerQualityKey`:
  - Specifies a tracking quality hint.
  - NSNumber integral value equal to one the STTrackerQuality constants.
  - Defaults to `STTrackerQualityAccurate`.
 - `kSTTrackerTrackAgainstModelKey`:
  - Specifies whether to enable tracking against the model.
  - NSNumber boolean value.
  - Defaults to `@NO`.
  - If enabled, the tracker will attempt to match the current image with the current state of the reconstructed model.
 This can drastically reduce the pose estimation drift.
  - __Note:__ this option requires an STMapper to be attached to the scene.
 - `kSTTrackerAvoidPitchRollDriftKey`:
  - Specifies whether to enable pitch and roll drift cancellation using IMU.
  - NSNumber boolean value.
  - Defaults to `@NO`.
  - This can eliminate drift along these rotation axis, but can also result in lower short term accuracy.
  - Recommended for unbounded tracking.
 - `kSTTrackerAvoidHeightDriftKey`:
  - Specifies whether to enable height drift cancellation using ground plane detection.
  - NSNumber boolean value.
  - Defaults to `@NO`.
  - This can eliminate vertical drift, but can also result in lower short term accuracy.
  - Recommended for unbounded tracking.
 - `kSTTrackerBackgroundProcessingEnabledKey`:
  - Specifies whether to enable background processing.
  - NSNumber boolean value.
  - Defaults to `@NO`.
  - This can significantly reduce the time spent in the tracker before getting a new pose, but the tracker may keep
 using CPU/GPU resources between frames.
 - `kSTTrackerAcceptVaryingColorExposureKey`:
  - Specifies whether to accept varying exposures for the iOS camera.
  - NSNumber boolean value.
  - Defaults to `@NO`.
  - To ensure the optimal robustness, it is recommended to lock the iOS color camera exposure during tracking if the
 `STTrackerDepthAndColorBased` tracker type is being used.
  - By default, the tracker will return an error if it detects a change in the exposure settings, but it can be forced
 to accept it by enabling this option.
 - `kSTTrackerLegacyKey`:
  - As of SDK 0.8, improved tracking is enabled by default. Set this to @YES if you want to enable the pre-0.8 tracking
 behaviour.
  - NSNumber boolean value.
  - Defaults to `@NO`.
  - This setting affects all tracker types, i.e. both STTrackerDepthBased and STTrackerDepthAndColorBased
 - `kSTTrackerSceneTypeKey`
  - Specifies a general "<span>scene</span> type" to account for tracker-specific presets.
  - NSNumber integral value equal to one of the STTrackerSceneType constants.
  - Defaults to STTrackerSceneTypeObject.
  - You will get better tracking if this matches the scene you are tracking against.
  - STTrackerSceneTypeObject assumes the target is to scan objects or people (e.g. Scanner).
  - STTrackerSceneTypeObjectOnTurntable assumes the target is an object or person on a moving platform and that the
 device (iOS device + Sensor) are not moving.
  - STTrackerSceneTypeRoom assumes the target is to scan a room (e.g. RoomCapture).
 - `kSTTrackerMinimumDepthForICPKey`:
  - Specifies the minimum tracking distance in meters.
  - NSNumber floating point value.
  - Defaults to `@0.4f`.
*/
- (instancetype _Nonnull)initWithScene:(STScene* _Nonnull)scene options:(NSDictionary* _Nonnull)options;

/// Reset the tracker to its initial state.
- (void)reset;

/** Update the camera pose estimate using the given depth frame.

- Parameter depthFrame: The STDepthFrame depth frame.
- Parameter colorFrame: The STColorFrame color buffer.
- Parameter error: On return, if it fails, points to an NSError describing the failure.

- Returns: TRUE if success, FALSE otherwise, filling error with the explanation.

- Note: colorFrame can be nil if the tracker type is `STTrackerDepthBased`. For tracker type
`STTrackerDepthAndColorBased`, only `kCVPixelFormatType_420YpCbCr8BiPlanarFullRange` is supported for sampleBuffer
format.
*/
- (BOOL)updateCameraPoseWithDepthFrame:(STDepthFrame* _Nullable)depthFrame
                            colorFrame:(STColorFrame* _Nullable)colorFrame
                                 error:(NSError* _Nullable __autoreleasing* _Nullable)error;

/** Update the current pose estimates using the provided motion data.

- Parameter motionData: Provided motion data.
*/
- (void)updateCameraPoseWithMotion:(CMDeviceMotion* _Nonnull)motionData;

/** Update the current pose estimates with the raw gyroscope data.

- Parameter motionData: Provided raw gyroscope data.
*/
- (void)updateCameraPoseWithGyro:(CMGyroData* _Nonnull)motionData;

/** Update the current pose estimates with the raw accelerometer data.

- Parameter motionData: Provided raw accelerometer data.
*/
- (void)updateCameraPoseWithAccel:(CMAccelerometerData* _Nonnull)motionData;

/// Return the most recent camera pose estimate.
- (GLKMatrix4)lastFrameCameraPose;

/** Dynamically adjust the tracker options.

Currently, only `kSTTrackerQualityKey` and `kSTTrackerBackgroundProcessingEnabledKey` can be changed after
initialization. Other options will remain unchanged.

- Parameter options: Dictionary of options. The valid keys are:

- `kSTTrackerQualityKey`:
  - Specifies a tracking quality hint.
  - NSNumber integral value equal to one the STTrackerQuality constants.
  - Defaults to `STTrackerQualityAccurate`.
- `kSTTrackerBackgroundProcessingEnabledKey`:
  - Specifies whether to enable background processing.
  - NSNumber boolean value.
  - Defaults to `@NO`.
  - This can significantly reduce the time spent in the tracker before getting a new pose, but the tracker may keep
using CPU/GPU resources between frames.
*/
- (void)setOptions:(NSDictionary* _Nonnull)options;

@end
