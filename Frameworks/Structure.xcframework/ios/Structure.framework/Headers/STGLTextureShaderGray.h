/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Structure/StructureBase.h>
#import <Structure/STGLTextureShader+Types.h>

#pragma mark - STGLTextureShaderGray API

/// STGLTextureShaderGray instances can render OpenGL ES 2D textures in single-channel luminance format.
ST_GLES_DEPRECATED
@interface STGLTextureShaderGray : NSObject

/// Enable the underlying shader program.
- (void)useShaderProgram;

/** Render the texture on a fullscreen quad using the given GL_TEXTUREX unit.

- Parameter lumaTextureUnit: A given native OpenGL texture unit to render.
*/
- (void)renderWithLumaTexture:(GLint)lumaTextureUnit;

/** Render the texture on a fullscreen quad using the given GL_TEXTUREX unit.

- Parameter lumaTextureUnit: A given native OpenGL luminance texture unit to render.
- Parameter alpha: The texture transparency.
- Parameter orientation: The texture orientation mode.
*/
- (void)renderWithLumaTexture:(GLint)lumaTextureUnit
                        alpha:(GLfloat)alpha
           textureOrientation:(STQuadTextureOrientation)orientation;

@end
