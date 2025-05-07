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

#pragma mark - STSLAMManager API

/** An STSLAMManager instance maps and tracks the 3D position and data of the Structure Sensor.

Using STSLAMManager does not require the use of an STMapper object.

*/
ST_SLAMMANAGER_DEPRECATED
@interface STSLAMManager : NSObject

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

/** STSLAMManager initialization.

 Cannot be used until an ``STScene`` has been provided.

 Sample usage:
```objc
NSDictionary* trackerOptions = @{
    kSTMapperVolumeResolutionKey: @(0.003),
    kSTMapperVolumeBoundsKey: @[
            @(_slamState.volumeSizeInMeters.x),
            @(_slamState.volumeSizeInMeters.y),
            @(_slamState.volumeSizeInMeters.z)
    ],
};
STSLAMManager* manager = [[STSLAMManager alloc] initWithScene:myScene options:options];
 ```

- Parameter scene: The ``STScene`` context.
- Parameter options: Dictionary of options. The valid keys are:

 - `kSTMapperVolumeResolutionKey`:
  - Specifies the volume resolution as the size of each voxel in meters.
  - `NSNumber` floating point value.
  - Required.
 - `kSTMapperVolumeBoundsKey`:
  - The extents of the bounding volume in meters along each dimension.
  - `NSArray` of 3 floating point values.
  - Defaults to `@[ @(0.0), @(0.0), @(0.0) ]`.
*/
- (instancetype _Nonnull)initWithScene:(STScene* _Nonnull)scene options:(NSDictionary* _Nonnull)options;

/// Reset the tracker and mapper state. This will also stop any background processing.
- (void)reset;

/** Update the camera pose estimate and integrate data into the model using the given depth frame.

- Parameter depthFrame: The STDepthFrame depth frame.
- Parameter colorFrame: The STColorFrame color frame from iOS.
- Parameter error: On return, if it fails, points to an NSError describing the failure.

- Returns: TRUE if success, FALSE otherwise, filling error with the explanation.
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

/// Wait until ongoing processing in the background queue finishes, and build the final triangle mesh.
- (void)finalizeTriangleMesh;

/// Merges all bundles together (slow), but less accurate than the final mesh
- (STMesh* _Nonnull)currentMesh;

/// Mesh from the single current bundle, works significantly faster than access to the whole merged mesh.
- (STMesh* _Nonnull)currentBundleMesh;

@end
