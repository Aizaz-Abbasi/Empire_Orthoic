/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once


/// Different types of quad texture orientation for rendering
typedef NS_ENUM(NSInteger, STQuadTextureOrientation) {
    /// Default texture orientation.
    STQuadTextureOrientationDefault = 0,

    /// Rotated by 90 degrees clockwise
    STQuadTextureOrientationRotated90 = 1,

    /// Rotated by 180 degrees clockwise
    STQuadTextureOrientationRotated180 = 2,

    /// Rotated by 270 degrees clockwise
    STQuadTextureOrientationRotated270 = 3,

    /// Flipped X axis
    STQuadTextureOrientationFlippedX = 4,

    /// Flipped Y axis
    STQuadTextureOrientationFlippedY = 5,
};
