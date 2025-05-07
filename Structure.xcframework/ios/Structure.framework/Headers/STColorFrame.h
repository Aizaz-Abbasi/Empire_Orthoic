/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Structure/StructureBase.h>

#import <GLKit/GLKMatrix4.h>

#pragma mark - STColorFrame API
/** Color Frame.

STColorFrame represents a frame from a color camera, captured from the device which Structure Sensor is attached to.

- Warning:: The only supported color resolutions are  640x480, 2048x1536, 2592x1936, 3264x2448 and 4032x3024. Other
color resolutions are not supported and will throw an exception.
*/
@interface STColorFrame : NSObject <NSCopying>

/// The buffer that AVFoundation created to store the raw image data.
@property(readonly, nonatomic) CMSampleBufferRef sampleBuffer;

/// Frame width.
@property(readwrite, nonatomic) int width;

/// Frame height.
@property(readwrite, nonatomic) int height;

/** Capture timestamp in seconds since the iOS device boot (same clock as CoreMotion and AVCapture). */
@property(readwrite, nonatomic) NSTimeInterval timestamp;

/** Return a version of the color frame downsampled once. */
@property(readonly, nonatomic) STColorFrame* halfResolutionColorFrame;

/** OpenGL projection matrix representing an iOS virtual color camera.

 This matrix can be used to render a scene by simulating the same camera properties as the iOS color camera.

- Returns: A projection matrix.
 */
- (GLKMatrix4)glProjectionMatrix;

/** Intrinsic camera parameters.

 This struct can be used to get the intrinsic parameters of the current ColorFrame.

- Returns: A set of STIntrinsics intrinsic parameters.
*/
- (STIntrinsics)intrinsics;

@end
