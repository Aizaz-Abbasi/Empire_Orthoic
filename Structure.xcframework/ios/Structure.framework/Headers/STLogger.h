/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once
#import <Structure/StructureBase.h>
#import <Foundation/Foundation.h>

#pragma mark - STLogger API

/// Indicates the severity of the log message
typedef NS_ENUM(NSInteger, STLogLevel) {
    STLogLevelNone,
    STLogLevelTrace,
    STLogLevelDebug,
    STLogLevelInfo,
    STLogLevelWarn,
    STLogLevelError,
    STLogLevelFatal,
};

/// Indicates the type of the event
typedef NS_ENUM(NSInteger, STLogEventType) {
    STLogEventTypeNone,
    STLogEventTypeMessage
};

/// Meta information of the log event
struct STLogEvent
{
    enum STLogLevel logLevel;
    enum STLogEventType type;

    // Seconds since 1970
    NSTimeInterval timestamp;
    size_t threadId;
};

@protocol STLoggerDelegate <NSObject>
- (void)didReceiveEvent:(struct STLogEvent)event with:(NSString* _Nonnull)message from:(NSString* _Nonnull)logger;
@end

/** A STLogger instance*/
@interface STLogger : NSObject

+ (instancetype _Nonnull)instance;

@property(nonatomic, assign) id<STLoggerDelegate> _Nullable delegate;

@property(nonatomic, assign) enum STLogLevel logLevel;

@end
