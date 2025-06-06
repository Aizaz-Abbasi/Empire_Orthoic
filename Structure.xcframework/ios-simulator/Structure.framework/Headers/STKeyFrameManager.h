/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Structure/StructureBase.h>
#import <Structure/STKeyFrame.h>


#pragma mark - STKeyFrameManager Base
/// Dictionary keys for ``STKeyFrameManager/initWithOptions:``.
extern NSString* const kSTKeyFrameManagerMaxSizeKey;
extern NSString* const kSTKeyFrameManagerMaxDeltaRotationKey;
extern NSString* const kSTKeyFrameManagerMaxDeltaTranslationKey;

#pragma mark - STKeyFrameManager API
/** STKeyFrameManager manages KeyFrame collection and manipilation

## See also:
- ``STKeyFrame``
*/
@interface STKeyFrameManager : NSObject
/** Initialize a STKeyframeManager instance with the provided options.

- Parameter options: The options dictionary. The valid keys are:

- `kSTKeyFrameManagerMaxSizeKey`:
  - Specifies the maximal number of keyframes.
  - `NSNumber` integral value.
  - Defaults to `@(48)`.
- `kSTKeyFrameManagerMaxDeltaRotationKey`:
  - Sets the maximal rotation in radians tolerated between a frame and the previous keyframes before considering that it
is a new keyframe.
  - `NSNumber` floating point value.
  - Defaults to `@(30.0 * M_PI / 180.0)` (30 degrees).
- `kSTKeyFrameManagerMaxDeltaTranslationKey`:
  - Sets the maximal translation in meters tolerated between a frame and the previous keyframes before considering that
it is a new keyframe.
  - `NSNumber` floating poing value.
  - Defaults to `@(0.3)`.
*/
- (instancetype)initWithOptions:(NSDictionary*)options;

/** Check if the given pose would be a new keyframe.

- Parameter colorCameraPose: The camera pose for this keyFrame.

- Returns: TRUE if the new pose exceeds the `kSTKeyFrameManagerMaxDeltaRotationKey` or
`kSTKeyFrameManagerMaxDeltaTranslationKey` criteria.
*/
- (BOOL)wouldBeNewKeyframeWithColorCameraPose:(GLKMatrix4)colorCameraPose;

/** Potentially add the candidate frame as a keyframe if it meets the new keyframe criteria.

- Parameter colorCameraPose: The GLKMatrix4 camera pose for this keyFrame.
- Parameter colorFrame: The STColorFrame color buffer.
- Parameter depthFrame: The STDepthFrame depth frame.

- Returns: TRUE if the frame was considered a new keyframe, FALSE otherwise.

- Note: Only `kCVPixelFormatType_420YpCbCr8BiPlanarFullRange` is supported for sampleBuffer format.
*/
- (BOOL)processKeyFrameCandidateWithColorCameraPose:(GLKMatrix4)colorCameraPose
                                         colorFrame:(STColorFrame*)colorFrame
                                         depthFrame:(STDepthFrame*)depthFrame;

/** Manually add a keyFrame.

This will bypass the criteria of the manager.

- Parameter keyFrame: The STKeyFrame to add into STKeyFrameManager.
*/
- (void)addKeyFrame:(STKeyFrame*)keyFrame;

/// Get the array of STKeyFrame instances accumulated so far.
- (NSArray*)getKeyFrames;

/// Clear the current array of keyframes.
- (void)clear;

@end
