/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Structure/StructureBase.h>

#pragma mark - STMesh Types

// Dictionary keys for ``STMesh/writeToFile:options:error:``.
extern NSString* const kSTMeshWriteOptionFileFormatKey;
extern NSString* const kSTMeshWriteOptionUseXRightYUpConventionKey;
extern NSString* const kSTMeshWriteOptionUseScaleKey;

// Dictionary keys for ``STMesh/newFillHolesTaskWithMesh:algorithm:options:completionHandler:``.
extern NSString* const kSTMeshFillHoleMaxPatchAreaKey;
extern NSString* const kSTMeshFillHolePoissonStrategyKey;

/** Constants specifying a file format for storing an STMesh on disk.

## See Also
 - ``STMesh/writeToFile:options:error:``
*/
typedef NS_ENUM(NSInteger, STMeshWriteOptionFileFormat) {
    /** Wavefront OBJ format.

    If the mesh has a texture, an MTL file will also be generated, and the texture saved to a JPEG file.
    Filenames with spaces are not supported by OBJ and will return an error.
    */
    STMeshWriteOptionFileFormatObjFile = 0,

    /** Wavefront OBJ format, compressed into a ZIP file.

    The archive will also embed the MTL and JPEG file if the mesh has a texture.
    */
    STMeshWriteOptionFileFormatObjFileZip = 1,

    /** Polygon File format or the Stanford Triangle format.

    The output mesh will be in binary form.
    */
    STMeshWriteOptionFileFormatPlyFile = 2,

    /** STL format.
     The output mesh will be in binary form.
    */
    STMeshWriteOptionFileFormatBinarySTLFile = 4,
};

/** Constants specifying a hole-filling algorithm.

## See Also
 - ``STMesh/newFillHolesTaskWithMesh:algorithm:options:completionHandler:``
*/
typedef NS_ENUM(NSInteger, STMeshFillHoleAlgorithm) {
    /// The Poisson algorithm
    STMeshFillHoleAlgorithmPoisson = 0,
    /// The Liepa algorithm
    STMeshFillHoleAlgorithmLiepa = 1,
};

/** Constants specifying a hole-filling strategy for the poisson algorithm.

## See Also
 - ``STMesh/newFillHolesTaskWithMesh:algorithm:options:completionHandler:``
*/
typedef NS_ENUM(NSInteger, STMeshFillHolePoissonStrategy) {
    STMeshFillHolePoissonStrategyClosedHull = 0,

    STMeshFillHolePoissonStrategyWatertight = 1,
};
