/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Structure/StructureBase.h>
#import <Structure/STMesh.h>
#import <Structure/STScanQualityAnalysis+Types.h>

#import <Foundation/Foundation.h>

#pragma mark - STScanQualityAnalysis API

/** Provides scan quality score of ``STMesh`` file

 Calculates quality score of a given mesh file. There are separate functions to provide quality score of foot mesh and
 other objects.
*/
@interface STScanQualityAnalysis : NSObject

/** Creates an instance of STScanQualityAnalaysis with given mesh type.

- Parameter meshType: A ``STScanQualityMeshType`` enum which represnts the mesh type on which scan quality will be
calculated.

 If meshType is not provided at initialization then default value  is set to `STScanQualityMeshTypeGenericObject`.

*/
- (instancetype _Nonnull)initWithMeshType:(STScanQualityMeshType)meshType;


/** Calculates the scan quality of the given foot mesh

- Parameter mesh: Mesh to which the sqi will be calculated.

 Returns a ``STScanQualityScore`` enum.

*/
- (STScanQualityScore)calcQualityOfMesh:(STMesh* _Nonnull)mesh;

/// Number of holes in mesh.
- (int)numberOfHoles;

/** Pointer to a contiguous chunk of `numberOfVerticesInHole:holeIndex` `GLKVector3` values representing (x, y, z)
vertex coordinates.

- Parameter holeIndex: Index to the hole in mesh.
*/
- (GLKVector3* _Nullable)holeVertices:(int)holeIndex;

/** Number of vertices in hole .

 - Parameter holeIndex: Index to the hole in mesh.
 */
- (int)numberOfVerticesInHole:(int)holeIndex;

@end
