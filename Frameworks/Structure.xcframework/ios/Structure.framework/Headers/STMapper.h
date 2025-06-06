/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Structure/StructureBase.h>
#import <Structure/STDepthFrame.h>
#import <Structure/STScene.h>

#pragma mark - STMapper Base
// Dictionary keys for ``STMapper/initWithScene: options:``.
extern NSString* _Nonnull const kSTMapperDepthIntegrationFarThresholdKey;
extern NSString* _Nonnull const kSTMapperVolumeCutBelowSupportPlaneKey;
extern NSString* _Nonnull const kSTMapperVolumeHasSupportPlaneKey;
extern NSString* _Nonnull const kSTMapperEnableLiveWireFrameKey;
extern NSString* _Nonnull const kSTMapperVolumeResolutionKey;
extern NSString* _Nonnull const kSTMapperVolumeBoundsKey;
extern NSString* _Nonnull const kSTMapperLegacyKey;

extern NSString* _Nonnull const kSTMapperEnableDepthFilteringKey;

#pragma mark - STMapper API

/** A STMapper instance integrates sensor data to reconstruct a 3D model of a scene.

It will update the scene mesh progressively as new depth frames are integrated.
It runs in a background thread, which means that it may update the scene object at any time.

It works over a fixed cuboid defining the volume of interest in the scene.
This volume can be initialized interactively using STCameraPoseInitializer.

The volume is defined by its size in the real world, in meters, and is discretized into voxels.
The volume resolution specifies the size of each voxel in meters. As a consequence, the higher the resolution, the more
voxels the mapper will need to compute.
*/
@interface STMapper : NSObject

/// The STScene model which will be updated.
@property(nonatomic, retain) STScene* _Nonnull scene;

/**
Initialize with a given scene and volume resolution.

- Parameter scene: The STScene context.
- Parameter options: Dictionary of options. The valid keys are:

- `kSTMapperVolumeResolutionKey`:
  - Specifies the volume resolution as the size of each voxel in meters.
  - `NSNumber` floating point value.
  - Required.
- `kSTMapperVolumeBoundsKey`:
  - The extents of the bounding volume in number of voxels along each dimension.
  - `NSArray` of 3 `NSNumber` integral values.
  - Defaults to `@[ @(128), @(128), @(128) ]`.
  - To maintain good performance, we recommend to keep the boundaries under 290x290x290.
- `kSTMapperVolumeHasSupportPlaneKey`:
  - Specifies whether the volume cuboid has been initialized on top of a support plane.
  - `NSNumber` boolean value.
  - Defaults to `@NO`.
  - If the mapper is aware that the volume is on top of a support plane, it will adapt the pipeline to be more robust,
and scan only the object if `kSTMapperVolumeHasSupportPlaneKey` is set to YES.
  - This value is typically set from `STCameraPoseInitializer.hasSupportPlane`.
- `kSTMapperVolumeCutBelowSupportPlaneKey`:
  - Specified whether the support plane should be kept out of the scan.
  - `NSNumber` boolean value.
  - Defaults to `@YES`.
- `kSTMapperEnableLiveWireFrameKey`:
  - Specifies whether the mapper should automatically build a wireframe mesh in the background when new depth frames are
provided.
  - `NSNumber` boolean value.
  - Defaults to `@NO`.
- `kSTMapperDepthIntegrationFarThresholdKey`:
  - Specifies the depth integration far threshold.
  - Individual depth values beyond the far threshold will be ignored by the mapper.
  - `NSNumber` floating point value.
  - The value is in meters, and must be in the [0.5, 8.0] range.
  - Defaults to `@(4.0)`.
- `kSTMapperLegacyKey`:
  - Specifies whether the pre-0.5 mapping technique should be used.
  - `NSNumber` boolean value.
  - Defaults to `@NO`.
- `kSTMapperEnableDepthFilteringKey`
  - Specifies whether the mapper should ignore less acurate depth data.
  - Defaults to `@NO`.
*/
- (instancetype _Nonnull)initWithScene:(STScene* _Nonnull)scene options:(NSDictionary* _Nonnull)options;

/// Reset the mapper state. This will also stop any background processing.
- (void)reset;

/** Integrate a new depth frame to the model.

The processing will be performed in a background queue, so this method is non-blocking.

- Parameter depthFrame: The depth frame.
- Parameter cameraPose: The viewpoint to use for mapping.
*/
- (void)integrateDepthFrame:(STDepthFrame* _Nonnull)depthFrame cameraPose:(GLKMatrix4)cameraPose;

/// Wait until ongoing processing in the background queue finishes, and build the final triangle mesh.
- (void)finalizeTriangleMesh;

@end
