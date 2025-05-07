/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/
#pragma once

#import <Structure/StructureBase.h>
#import <Structure/STDepthFrame.h>

#pragma mark - STKeyFrame API
/// STKeyFrame instances store the depth, color and camera pose information of a single frame.
@interface STKeyFrame : NSObject

/** Initialize with required frame data and pose.

- Parameter colorCameraPose: The GLKMatrix4 camera pose for this keyFrame.
- Parameter colorFrame: The STColorFrame color buffer.
- Parameter depthFrameOrNil: The STDepthFrame depth frame image. Can be `nil` if the depth information is not needed.

- Note: Only `kCVPixelFormatType_420YpCbCr8BiPlanarFullRange` is supported for sampleBuffer format.
*/
- (instancetype)initWithColorCameraPose:(GLKMatrix4)colorCameraPose
                             colorFrame:(STColorFrame*)colorFrame
                             depthFrame:(STDepthFrame*)depthFrameOrNil;

@end
