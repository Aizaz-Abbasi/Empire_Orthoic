/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Structure/StructureBase.h>

#pragma mark - STInfraredFrame API

/** Infrared Frame.
STInfraredFrame is the raw infrared frame object for frames streaming from Structure Sensor.
*/
@interface STInfraredFrame : NSObject <NSCopying>

/// Contiguous chunk of `width * height` pixels.
@property(readwrite, nonatomic) uint16_t* data;

/// Frame width.
@property(readwrite, nonatomic) int width;

/// Frame height.
@property(readwrite, nonatomic) int height;

/** Capture timestamp in seconds since the iOS device boot (same clock as CoreMotion and AVCapture). */
@property(readwrite, nonatomic) NSTimeInterval timestamp;

/** Return the extrinsics of the IR camera relatively to the reference camera.
Returns extrinsics for rectified frame, if rectification enabled.
- Warning: The rectification status is updated with a delay!
*/
@property(readonly, nonatomic) STExtrinsics extrinsics;

/** Return the per-frame exposure duration in seconds for a given frame. */
@property(readonly, nonatomic) NSTimeInterval exposure;

/** Return the per-frame brightness, which represents the amount of IR light present in the frame.
The minimum value is 0 and maximum value is approxmately 400.
*/
@property(readonly, nonatomic) unsigned short medianBrightness;

@end
