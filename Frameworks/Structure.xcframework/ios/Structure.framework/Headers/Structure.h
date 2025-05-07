/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/

#pragma once

/** Structure SDK Umbrella **/
#import <Structure/STBackgroundTask.h>
#import <Structure/STCameraPoseInitializer.h>
#import <Structure/STCaptureSession.h>
#import <Structure/STColorFrame.h>
#import <Structure/STColorizer.h>
#import <Structure/STCubeRenderer.h>
#import <Structure/STDepthFrame.h>
#import <Structure/STDepthToRgba.h>
#import <Structure/STGLTextureShaderGray.h>
#import <Structure/STGLTextureShaderRGBA.h>
#import <Structure/STGLTextureShaderYCbCr.h>
#import <Structure/STInfraredFrame.h>
#import <Structure/STKeyFrame.h>
#import <Structure/STKeyFrameManager.h>
#import <Structure/STLogger.h>
#import <Structure/STLicense.h>
#import <Structure/STMapper.h>
#import <Structure/STMesh.h>
#import <Structure/STMeshIntersector.h>
#import <Structure/STNormalEstimator.h>
#import <Structure/STNormalFrame.h>
#import <Structure/STOccFileWriter.h>
#import <Structure/STScanQualityAnalysis.h>
#import <Structure/STScene.h>
#import <Structure/STSLAMManager.h>
#import <Structure/STTracker.h>
#import <Structure/STWirelessLog.h>

// Make sure the deployment target is higher or equal to iOS 10.
#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && (__IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_10_0)
    #error This version of Structure SDK only supports iOS 10 or higher.
#endif

/** Structure SDK version definition
## See also:
- ``currentSDKVersion``
*/
typedef struct
{
    const int major;
    const int minor;
    const int patch;
    const char* version;
} SDKVersion;

#ifdef __cplusplus
extern "C"
{
#endif
/** Returns a string specifying the current SDK version */
SDKVersion currentSDKVersion(void);

/** Launch the Calibrator app or prompt the user to install it.

An iOS app using the Structure Sensor should present its users with an
opportunity to call this method when the following conditions are
simultaneously met:

- The sensor doesn't have a `calibrationType` with value `CalibrationTypeDeviceSpecific`.
- A registered depth stream is required by the application.
- The iOS device is supported by the Calibrator app.

- Warning: For this method to function, your app bundle's info plist must contain the following entry:

```plist
<key>LSApplicationQueriesSchemes</key>
<array>
<string>structure-sensor-calibrator</string>
</array>
 ```

- Note: See the calibration overlay sample code for more details.
*/
bool launchCalibratorAppOrGoToAppStore(void);

/** Launch the Structure app or prompt the user to install it.

An iOS app using the Structure Sensor should present its users with an
opportunity to call this method when a firmware update is required. This can
be queried by calling STCaptureSession:userInstructions.

- Warning: For this method to function, your app bundle's info plist must contain the following entry:

```plist
<key>LSApplicationQueriesSchemes</key>
<array>
<string>structure-app</string>
</array>
```

- Note: See the calibration overlay sample code for more details.
*/
bool launchStructureAppOrGoToAppStore(void);
#ifdef __cplusplus
};
#endif
