/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

#import <Structure/StructureBase.h>

@class STBackgroundTask;

#pragma mark - STBackgroundTask API

/** STBackgroundTaskDelegate is a delegate protocol that your class can implement in order to receive STBackgroundTask
callbacks.

## See Also

- ``STBackgroundTask/delegate``
*/
@protocol STBackgroundTaskDelegate <NSObject>
@optional

/** Report progress in the background task.

- Parameter sender: The STBackgroundTask that reports the progress.
- Parameter progress: is a floating-point value from 0.0 (Not Started) to 1.0 (Completed).
*/
- (void)backgroundTask:(STBackgroundTask*)sender didUpdateProgress:(double)progress;

@end

/** STBackgroundTask instances enable control of tasks running asynchronously in a background queue.

## See Also

- ``STMesh/newDecimateTaskWithMesh:numFaces:completionHandler:``
- ``STMesh/newFillHolesTaskWithMesh:completionHandler:``
- ``STColorizer/newColorizeTaskWithMesh:scene:keyframes:completionHandler:options:error:``
- ``STBackgroundTaskDelegate``
*/
@interface STBackgroundTask : NSObject

/// Start the execution of the task asynchronously, in a background queue.
- (void)start;

/** Cancel the background task if possible.

- Note: If the operation is already near completion, the completion handler may still be called successfully.
*/
- (void)cancel;

/// Synchronously wait until the task finishes its execution.
- (void)waitUntilCompletion;

/// Whether the task was canceled. You can check this in the completion handler to make sure the task was not canceled
/// right after it finished.
@property(atomic, readonly) BOOL isCancelled;

/// By setting a STBackgroundTaskDelegate delegate to an STBackgroundTask, you can receive progress updates.
@property(atomic, assign) id<STBackgroundTaskDelegate> delegate;

@end
