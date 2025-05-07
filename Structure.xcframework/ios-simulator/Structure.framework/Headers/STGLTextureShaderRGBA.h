/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Structure/StructureBase.h>
#import <Structure/STGLTextureShader+Types.h>

#pragma mark - STGLTextureShaderRGBA API

/// STGLTextureShaderRGBA instances can render OpenGL ES 2D textures in RGBA format.
@interface STGLTextureShaderRGBA : NSObject

/// Enable the underlying shader program.
- (void)useShaderProgram;

/** Render the texture on a fullscreen quad using the given GL_TEXTUREX unit.

- Parameter textureUnit: A given native OpenGL texture unit to render.
*/
- (void)renderTexture:(GLint)textureUnit;

/** Render the texture on a fullscreen quad using the given GL_TEXTUREX unit.

- Parameter textureUnit: A given native OpenGL texture unit to render.
- Parameter alpha: The texture transparency.
- Parameter orientation: The texture orientation mode.
*/
- (void)renderTexture:(GLint)textureUnit alpha:(GLfloat)alpha textureOrientation:(STQuadTextureOrientation)orientation;

@end
