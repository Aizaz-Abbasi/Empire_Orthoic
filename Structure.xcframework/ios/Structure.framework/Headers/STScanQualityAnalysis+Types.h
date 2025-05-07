/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Structure/StructureBase.h>

#pragma mark - STScanQualityAnalysis Types

/// Enum for mesh quality score
typedef NS_ENUM(NSInteger, STScanQualityScore) {
    /// Indicates a good quality mesh
    STScanQualityGood = 1,

    /// There are holes in important regions of the mesh
    STScanQualityFaulty = 2,

    /// Mesh is not completely scanned(Used only in evaluating foot scans)
    STScanQualityIncomplete = 3,

    /// Mesh is scanned poorly
    STScanQualityPoor = 4,

    /// Unknown
    STScanQualityUnknown = 5
};

/// Enum for type of mesh
typedef NS_ENUM(NSInteger, STScanQualityMeshType) {
    /// Input mesh is a foot that is being scanned from plantar surface
    STScanQualityMeshTypeFootInPlantarMode = 1,

    /// Input mesh can be any generic object
    STScanQualityMeshTypeGenericObject = 2
};
