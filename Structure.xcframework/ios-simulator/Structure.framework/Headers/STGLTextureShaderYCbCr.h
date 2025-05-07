/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Structure/StructureBase.h>
#import <Structure/STGLTextureShader+Types.h>

#pragma mark - STGLTextureShaderYCbCr API

/// STGLTextureShaderYCbCr instances can render OpenGL ES 2D textures in YCbCr format.
ST_GLES_DEPRECATED
@interface STGLTextureShaderYCbCr : NSObject

/// Enable the underlying shader program.
- (void)useShaderProgram;

/// Enable the underlying shader program and undistort the YCbCr texture.
- (void)useShaderProgramWithUndistortion:(STIntrinsics*)stIntrinsics;

/** Render the texture on a fullscreen quad using the given GL_TEXTUREX unit.

- Parameter lumaTextureUnit: A given native OpenGL luminance texture unit to render.
- Parameter chromaTextureUnit: A given native OpenGL chroma texture unit to render.
*/
- (void)renderWithLumaTexture:(GLint)lumaTextureUnit chromaTexture:(GLint)chromaTextureUnit;

/** Render the texture on a fullscreen quad using the given GL_TEXTUREX unit.

- Parameter lumaTextureUnit: A given native OpenGL luminance texture unit to render.
- Parameter chromaTextureUnit: A given native OpenGL chroma texture unit to render.
- Parameter alpha: The texture transparency.
*/
- (void)renderWithLumaTexture:(GLint)lumaTextureUnit chromaTexture:(GLint)chromaTextureUnit alpha:(GLfloat)alpha;

/** Render the texture on a fullscreen quad using the given GL_TEXTUREX unit.

- Parameter lumaTextureUnit: A given native OpenGL luminance texture unit to render.
- Parameter chromaTextureUnit: A given native OpenGL chroma texture unit to render.
- Parameter alpha: The texture transparency.
- Parameter orientation: The texture orientation mode.
*/
- (void)renderWithLumaTexture:(GLint)lumaTextureUnit
                chromaTexture:(GLint)chromaTextureUnit
                        alpha:(GLfloat)alpha
           textureOrientation:(STQuadTextureOrientation)orientation;
@end
