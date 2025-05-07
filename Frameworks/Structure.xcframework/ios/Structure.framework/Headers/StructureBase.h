/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import <stdlib.h>

#ifdef ST_GLES_SILENCE_DEPRECATION
    #define ST_GLES_DEPRECATED
#else
    #define ST_GLES_DEPRECATED \
        __attribute__((deprecated( \
            "Visualization based on OpenGLES API is deprecated and will be removed in the future releases. " \
            "Please use Metal-based visualization. (Define ST_GLES_SILENCE_DEPRECATION to silence these warnings)")))
#endif

#ifdef ST_SLAMMANAGER_SILENCE_DEPRECATION
    #define ST_SLAMMANAGER_DEPRECATED
#else
    #define ST_SLAMMANAGER_DEPRECATED \
        __attribute__((deprecated("STLAMManager is deprecated and will be removed in future releases. Please use " \
                                  "STMapper. (Define ST_SLAMMANAGER_SILENCE_DEPRECATION to silence these warnings)")))
#endif

#pragma mark - ST Frames Base

/// Intrinsics data
typedef struct
{
    int width, height;
    float fx, fy, cx, cy, k1, k2;
} STIntrinsics;

/// Extrinsics data
typedef struct
{
    float tx, ty, tz, qx, qy, qz, qw;
} STExtrinsics;

/** Capture metadata for color frame
## See also:
- ``STColorFrame``
*/
typedef struct
{
    STIntrinsics intrinsics;

    double isoSpeed;
    double exposure;
    double focusPosition;
    double whiteBalanceRedGain;
    double whiteBalanceGreenGain;
    double whiteBalanceBlueGain;
} STColorFrameCaptureMetadata;

//------------------------------------------------------------------------------
#pragma mark - STErrorCodes

/// String constant to identify the Structure Framework error domain.
extern NSString* const StructureSDKErrorDomain;

/** Error codes that specify an error.

These may appear in NSError objects returned by various Structure Framework methods.

`NSString* const StructureSDKErrorDomain;` is the constant to identify the Structure Framework error domain.
*/
typedef NS_ENUM(NSInteger, STErrorCode) {
    /// The operation could not be completed because parameters passed to the SDK method contains non-valid values.
    STErrorInvalidValue = 10,

    /// The operation could not be completed because a licensed feature is now available.
    STErrorNoLicense = 15,

    /// STCameraPoseInitializer tried to initialize a camera pose using without a depth frame.
    STErrorCameraPoseInitializerDepthFrameMissing = 20,

    /// The operation could not be completed because file output path is invalid.
    STErrorFileWriteInvalidFileName = 31,

    /// `STTracker` is not initialized yet.
    STErrorTrackerNotInitialized = 41,

    /// `STTracker` detected the color sample buffer exposure has changed.
    STErrorTrackerColorExposureTimeChanged = 44,

    /// `STTracker` doesn't have device motion and cannot continue tracking.
    STErrorTrackerDeviceMotionMissing = 45,

    /// The STMesh operation could not be completed because it contains an empty mesh.
    STErrorMeshEmpty = 60,

    /// The STMesh operation could not be completed because it was cancelled.
    STErrorMeshTaskCancelled = 61,

    /// The STMesh operation could not be completed because it contains an invalid texture format.
    STErrorMeshInvalidTextureFormat = 62,

    /// The colorize operation could not be completed because `STColorizer` doesn't have keyframes.
    STErrorColorizerNoKeyframes = 80,

    /// The colorize operation could not be completed because `STColorizer` doesn't have a mesh.
    STErrorColorizerEmptyMesh = 81,
};
