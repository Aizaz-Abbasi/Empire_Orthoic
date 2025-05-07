/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Structure/StructureBase.h>
#import <Structure/STColorFrame.h>

#import <GLKit/GLKit.h>

/// Indicates the source sensor of the depth frame
typedef NS_ENUM(NSInteger, STDepthFrameSource) {
    STDepthFrameSourceStructureSensor = 1,
    STDepthFrameSourceAppleTrueDepth = 2,
    STDepthFrameSourceAppleLidar = 3
};

#pragma mark - STDepthFrame API

/** Depth Frame.
STDepthFrame is the raw depth frame object for frames streaming from Structure Sensor.
*/
@interface STDepthFrame : NSObject <NSCopying>

/// Frame width.
@property(readonly, nonatomic) int width;

/// Frame height.
@property(readonly, nonatomic) int height;

/// Contiguous chunk of `width * height` 16bit shift values.
@property(readonly, nonatomic) uint16_t* shiftData;

/// Contiguous chunk of `width * height` float depth values in millimeters.
@property(readonly, nonatomic) float* depthInMillimeters;

/// Return a version of the depth frame downsampled once.
@property(readonly, nonatomic) STDepthFrame* halfResolutionDepthFrame;

/// Capture timestamp in seconds since the iOS device boot (same clock as CoreMotion and AVCapture).
@property(readonly, nonatomic) NSTimeInterval timestamp;

/** Return a version of the depth frame aligned to the color camera viewpoint.

- Parameter colorFrame: By providing an STColorFrame a corresponding STDepthFrame will be returned
- Warning: Do not use the returned image after the original image has been released.
 */
- (STDepthFrame*)registeredToColorFrame:(STColorFrame*)colorFrame;

/** OpenGL projection matrix representing Structure Sensor virtual camera.

 This matrix can be used to render a scene by simulating the same camera properties as the Structure Sensor depth
 camera.

- Returns: A projection matrix.
 */
- (GLKMatrix4)glProjectionMatrix;

/** Intrinsic camera parameters.

 This struct can be used to get the intrinsic parameters of the current DepthFrame.

- Returns: A set of STIntrinsics intrinsic parameters.
 */
- (STIntrinsics)intrinsics;

/** Test if valid extrinsics exist

 This method will tell you if valid extrinsics for a bracket calibration currently exist for a given frame.

 This can be used to tell whether it's possible to register this frame to another iOS color frame.
 */
- (BOOL)hasValidExtrinsics;

/**
 Get the extrinsics relating the iOS camera to the depth sensor.

 The transformation matrix returned here is in the reference frame of the iOS camera. The coordinate frame is right
 handed: X right, Y down, Z out. This matrix can transform a 3D isometry expressed in the Structure Sensor depth stream
 coordinate system to the iOS camera coordinate system using the following operation:

 `3DIsometryInIOSFrame = iOSColorFromDepthExtrinsics * 3DIsometryInDepthFrame`  for row-major matrices
 (pre-multiplication), and `3DIsometryInIOSFrame = 3DIsometryInDepthFrame * iOSColorFromDepthExtrinsics`  for col-major
 matrices (post-multiplication).

- Returns: a 4x4 GLKMatrix in _column_ major order, with the correct extrinsics for the current sensor and lens
 configuration. This value does not change when streaming registered depth, as it reports the mechanical transform
 between the depth stream and the iOS camera. Will return a matrix of the form [identity rotation | default translation]
 with an approximate calibration. Will return a matrix of the form [nan | nan] with no calibration.
 */
- (GLKMatrix4)iOSColorFromDepthExtrinsics;

/** Improve the accuracy of the depth data. Recommended for long-range data.

 This function has a significant runtime cost. For instance, on iPad Air 2 it can take up to 5 milliseconds to complete.

- Returns: FALSE if the correction could not be applied. This can happen when using hardware registered depth or a
sensor with an old firmware.
 */
- (BOOL)applyExpensiveCorrection;

- (void)applyDepthRefinement;

- (STDepthFrameSource)source;
@end
