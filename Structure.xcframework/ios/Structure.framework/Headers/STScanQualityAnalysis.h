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

@end
