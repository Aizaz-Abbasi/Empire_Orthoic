/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Structure/StructureBase.h>
#import <GLKit/GLKMatrix4.h>

#pragma mark - STOccFileWriter
/** Interface definition for writing OCC files
## See also: ``STOccFileWriter``
*/
@protocol STOccFileWriterProtocol

/// Property specifying the file path of the OCC file that is to be written.
/// This is only set after `startWriting` is called.
@property(nonatomic, readonly) NSString* occFilePath;

/// Property specifying whether the OCC is already in the process of writing a file or if
/// it is not (i.e. doing nothing).
@property(nonatomic, readonly) BOOL isWriting;

/// The number of frames remaining in the queue to be written to the OCC file.
@property(nonatomic, readonly) int numFramesEnqueuedForWriting;

/// The number of frames dropped by the OCC writer.
@property(nonatomic, readonly) int numFramesDropped;

/// The load factor of the write-buffer.
@property(nonatomic, readonly) float bufferLoadFactor;

/// How many frames-per-second are being written to the OCC file on average.
@property(nonatomic, readonly) float fps;

/** Starts writing events to the OCC file at the specified file path property.

If the file path is set to nil or the empty string, writes the OCC to a default
file path in the app's AppDocuments directory following the format:

    [AppDocuments]/STSession_yyyy-MM-dd_hh-mm-ss.occ

*/
- (BOOL)startWriting:(NSString*)occFilePathToWriteOrNil appendDateAndExtension:(BOOL)appendDateAndExtension;

/// Finalizes writing any events to the OCC file, and closes the file.
- (BOOL)stopWriting;

/// Stops writing any events to the OCC file, closes the file, and deletes the path.
- (BOOL)cancelWriting;

/// Writes a camera pose
- (void)writeCameraPose:(GLKMatrix4)cameraPose;

@end


/** The OCC writer class is the central class that manages writing incoming sensor data from a capture session to an OCC
file.

This class will be automatically created and managed by the STCaptureSession,
however the following interface is exposed when calling `captureSession.occWriter`.
*/
@interface STOccFileWriter : NSObject <STOccFileWriterProtocol>

/// Property specifying the file path of the OCC file that is to be written.
/// This is only set after `startWriting` is called.
@property(nonatomic, readonly) NSString* occFilePath;

/// Property specifying whether the OCC is already in the process of writing a file or if
/// it is not (i.e. doing nothing).
@property(nonatomic, readonly) BOOL isWriting;

/// The number of frames remaining in the queue to be written to the OCC file.
@property(nonatomic, readonly) int numFramesEnqueuedForWriting;

/// The number of frames dropped by the OCC writer.
@property(nonatomic, readonly) int numFramesDropped;

/// The load factor of the write-buffer.
@property(nonatomic, readonly) float bufferLoadFactor;

/// How many frames-per-second are being written to the OCC file on average.
@property(nonatomic, readonly) float fps;

/** Starts writing events to the OCC file at the specified file path property.

If the file path is set to nil or the empty string, writes the OCC to a default
file path in the app's AppDocuments directory following the format:

    [AppDocuments]/STSession_yyyy-MM-dd_hh-mm-ss.occ

*/
- (BOOL)startWriting:(NSString*)occFilePathToWriteOrNil appendDateAndExtension:(BOOL)appendDateAndExtension;

/// Finalizes writing any events to the OCC file, and closes the file.
- (BOOL)stopWriting;

/// Stops writing any events to the OCC file, closes the file, and deletes the path.
- (BOOL)cancelWriting;

/// Writes a camera pose
- (void)writeCameraPose:(GLKMatrix4)cameraPose;

@end
