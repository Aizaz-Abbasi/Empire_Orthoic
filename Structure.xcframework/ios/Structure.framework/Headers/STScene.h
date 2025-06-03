/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Structure/StructureBase.h>
#import <Structure/STMesh.h>

#import <GLKit/GLKMatrix4.h>

#pragma mark - STScene API

/** Common data shared and updated by the SLAM pipeline.

An STScene object contains information about the sensor and the reconstructed mesh.
Special care should be taken when accessing STScene members if an STTracker or STMapper is still active, as they could
be accessing the STScene from background threads. In particular, STMesh objects should be properly locked.
*/
@interface STScene : NSObject

/** Initializer for STScene.
 */
- (instancetype)init;

/** Initializer for STScene. Use this only together with deprecated OpenGL-based visualization primitives.

- Parameter glContext: a valid EAGLContext.
*/
- (instancetype)initWithContext:(EAGLContext*)glContext ST_GLES_DEPRECATED;

/** Reference to the current scene mesh.

This mesh may be modified by a background thread if an instance of STMapper is running, so proper locking is necessary.
*/
- (STMesh*)lockAndGetSceneMesh;

/** Queries the copy of the the scene mesh (thread-safe)
 */
- (STMesh*)getMesh;

/// Unlocks the mesh previously locked with `lockAndGetSceneMesh`.
- (void)unlockSceneMesh;

/** Resets the scene mesh.
- Parameter sceneMesh: the new mesh
*/
- (BOOL)setSceneMesh:(STMesh*)sceneMesh;

/** Render the scene mesh from the given viewpoint.

A virtual camera with the given projection and pose matrices will be used to render the mesh using OpenGL. This method
is generally faster than using sceneMeshRef and manually rendering it, since in most cases STScene can reuse mesh data
previously uploaded to the GPU.

- Parameter cameraPose: A GLKMatrix4 camera position used for rendering.
- Parameter glProjection: Projection matrix used during rendering. See also ``STDepthFrame/glProjectionMatrix`` and
``STColorFrame/glProjectionMatrix``.
- Parameter alpha: A float value for transparency between 0 (fully transparent) and 1 (fully opaque)
- Parameter highlightOutOfRangeDepth: Whether the areas of the mesh which are below Structure Sensor minimal depth range
should be highlighted in red.
- Parameter wireframe: Whether to render a wireframe of the mesh or filled polygons. When enabled, STMapper needs to be
initialized with the `kSTMapperEnableLiveWireFrameKey` option set to `@YES`.

- Returns: TRUE on success, FALSE if there is no STMapper attached to the same STScene with the corresponding (wireframe
or triangles) live mode enabled.
*/
- (BOOL)renderMeshFromViewpoint:(GLKMatrix4)cameraPose
             cameraGLProjection:(GLKMatrix4)glProjection
                          alpha:(float)alpha
       highlightOutOfRangeDepth:(BOOL)highlightOutOfRangeDepth
                      wireframe:(BOOL)wireframe ST_GLES_DEPRECATED;

/** Render the scene mesh from the given viewpoint.

A virtual camera with the given projection and pose matrices will be used to render the mesh using OpenGL. This method
is generally faster than using sceneMeshRef and manually rendering it, since in most cases STScene can reuse mesh data
previously uploaded to the GPU.

- Parameter cameraModelView: A GLKMatrix4 camera position used for rendering.
- Parameter glProjection: Projection matrix used during rendering. See also ``STDepthFrame/glProjectionMatrix`` and
``STColorFrame/glProjectionMatrix``.
- Parameter alpha: A float value for transparency between 0 (fully transparent) and 1 (fully opaque)
- Parameter highlightOutOfRangeDepth: Whether the areas of the mesh which are below Structure Sensor minimal depth range
should be highlighted in red.
- Parameter minDepthToHighlightInMeters: Specifies minimal depth range to be highlighted in red.
- Parameter wireframe: Whether to render a wireframe of the mesh or filled polygons. When enabled, STMapper needs to be
initialized with the `kSTMapperEnableLiveWireFrameKey` option set to `@YES`.

- Returns: TRUE on success, FALSE if there is no STMapper attached to the same STScene with the corresponding (wireframe
or triangles) live mode enabled.
*/
- (BOOL)renderMeshFromViewpoint:(GLKMatrix4)cameraModelView
             cameraGLProjection:(GLKMatrix4)glProjection
                          alpha:(float)alpha
       highlightOutOfRangeDepth:(BOOL)highlightOutOfRangeDepth
            minDepthToHighlight:(float)minDepthToHighlightInMeters
                      wireframe:(BOOL)wireframe;

/// Clear the scene mesh and state.
- (void)clear;

@end
