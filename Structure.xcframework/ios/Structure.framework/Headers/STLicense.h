/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once
#import <Structure/StructureBase.h>
#import <Foundation/Foundation.h>

#pragma mark - STLicense API

/// Indicates the severity of the log message
typedef NS_ENUM(NSInteger, LicenseStatus) {
    /// The license is valid, Structure SDK is unlocked
    LicenseStatusValid,

    /// The Structure SDK has not been unlocked
    LicenseStatusNone,

    /// Your cached Structure SDK license is expired and should be refreshed
    LicenseStatusExpired,

    /// Structure SDK could not connect to the server, you should check the internet connection
    LicenseStatusConnectionError,

    /// The pair of your license token and bundle id is not registered on the server
    LicenseStatusInvalidToken,

    /// Other server error, look at the log for more details
    LicenseStatusServerError,

    /// Other internal error
    LicenseStatusOther
};

/** A STLicenseManager instance*/
@interface STLicenseManager : NSObject

/** Unlock Structure SDK
- Parameter key: your license token.
- Parameter refresh: specifies whether cached license should be refreshed, normally you should pass false here.
- Returns: the license status.
*/
+ (enum LicenseStatus)unlockWithKey:(NSString* _Nonnull)key shouldRefresh:(bool)refresh;

/// Return the license status of Structure SDK.
@property(class, nonatomic, readonly) enum LicenseStatus status;

/// Return the available features of Structure SDK.
@property(class, nonatomic, readonly) NSArray<NSString*>* _Nonnull availableFeatures;

/// Return the license expiration time. After this time the SDK will require an internet connection to acquire a new
/// license.
@property(class, nonatomic, readonly) NSTimeInterval expirationTime;

@end
