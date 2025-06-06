/*
    This file is part of the Structure SDK.
    Copyright © 2022 XRPro, LLC. All rights reserved.
    http://structure.io
*/
#pragma once
#import <Structure/StructureBase.h>

#pragma mark - STCaptureSession Base

@class STCaptureSession;

// Dictionary keys for ``STCaptureSession/startMonitoringWithOptions:options``;
extern NSString* const kSTCaptureSessionOptionDepthSensorEnabledKey;
extern NSString* const kSTCaptureSessionOptionInfraredSensorEnabledKey;
extern NSString* const kSTCaptureSessionOptionDepthSensorVGAEnabledIfAvailableKey;
extern NSString* const kSTCaptureSessionOptionSensorAndIOSCameraSyncEnabledKey;
extern NSString* const kSTCaptureSessionOptionIOSCameraKey;
extern NSString* const kSTCaptureSessionOptionColorResolutionKey;
extern NSString* const kSTCaptureSessionOptionColorBinningKey;
extern NSString* const kSTCaptureSessionOptionDepthFrameResolutionKey;
extern NSString* const kSTCaptureSessionOptionIrFrameResolutionKey;
extern NSString* const kSTCaptureSessionOptionTrueDepthFrameResolutionKey;
extern NSString* const kSTCaptureSessionOptionLiDARFrameResolutionKey;
extern NSString* const kSTCaptureSessionOptionColorMaxFPSKey;
extern NSString* const kSTCaptureSessionOptionUseAppleCoreMotionKey;
extern NSString* const kSTCaptureSessionOptionToggleDepthSensorAutomaticallyKey;
extern NSString* const kSTCaptureSessionOptionStartOCCAfterSecondsKey;
extern NSString* const kSTCaptureSessionOptionSimulateRealtimePlaybackKey;
extern NSString* const kSTCaptureSessionOptionUseARKitConfigurationKey;
extern NSString* const kSTCaptureSessionOptionST01CompatibilityKey;

// Dictionary keys for iOS colour camera modes.
// Can be set via _captureSession.properties
extern NSString* const kSTCaptureSessionPropertyIOSCameraFocusModeKey;
extern NSString* const kSTCaptureSessionPropertyIOSCameraExposureModeKey;
extern NSString* const kSTCaptureSessionPropertyIOSCameraISOModeKey;
extern NSString* const kSTCaptureSessionPropertyIOSCameraWhiteBalanceModeKey;

// Dictionary keys to specify values for given iOS colour camera modes
// Can be set via _captureSession.properties
extern NSString* const kSTCaptureSessionPropertyIOSCameraFocusValueKey;
extern NSString* const kSTCaptureSessionPropertyIOSCameraExposureValueKey;
extern NSString* const kSTCaptureSessionPropertyIOSCameraISOValueKey;
extern NSString* const kSTCaptureSessionPropertyIOSCameraWhiteBalanceRedGainValueKey;
extern NSString* const kSTCaptureSessionPropertyIOSCameraWhiteBalanceGreenGainValueKey;
extern NSString* const kSTCaptureSessionPropertyIOSCameraWhiteBalanceBlueGainValueKey;

// Keys for sensor-specific setting modes
extern NSString* const kSTCaptureSessionPropertySensorIRExposureModeKey;
extern NSString* const kSTCaptureSessionPropertySensorIRProjectorModeKey;

// Keys to specify values for sensor-specific setting modes
extern NSString* const kSTCaptureSessionPropertySensorIRExposureValueKey;
extern NSString* const kSTCaptureSessionPropertySensorIRAnalogGainValueKey;
extern NSString* const kSTCaptureSessionPropertySensorIRDigitalGainValueKey;
extern NSString* const kSTCaptureSessionPropertySensorConfidenceThresholdKey;
extern NSString* const kSTCaptureSessionPropertySensorHdrModeKey;

// Dictionary keys to get corresponding sample entry objects from the dictionary
// passed to ``STCaptureSessionDelegate/captureSession:didOutputSample:type:``
extern NSString* const kSTCaptureSessionSampleEntryIOSColorFrame;
extern NSString* const kSTCaptureSessionSampleEntryDepthFrame;
extern NSString* const kSTCaptureSessionSampleEntryInfraredFrame;
extern NSString* const kSTCaptureSessionSampleEntryCameraPose;

extern NSString* const kSTCaptureSessionSampleEntryDeviceMotionData;
extern NSString* const kSTCaptureSessionSampleEntryGyroData;
extern NSString* const kSTCaptureSessionSampleEntryAccelData;
extern NSString* const kSTCaptureSessionSampleEntryControllerGyroData;
extern NSString* const kSTCaptureSessionSampleEntryControllerAccelData;

// Structure Sensor Mark II iOS keys
extern NSString* const kSTCaptureSessionOptionDepthStreamPresetKey;
extern NSString* const kSTCaptureSessionOptionDepthSearchWindowKey;
extern NSString* const kSTCaptureSessionOptionIrRectificationKey;

#pragma mark - STCaptureSession Base Types

/// Indicates the resolution that the user wants for color camera frames.
typedef NS_ENUM(NSInteger, STCaptureSessionColorResolution) {
    // 4:3 modes
    STCaptureSessionColorResolution640x480 = 1,
    STCaptureSessionColorResolution640x480_Binned = 2,
    STCaptureSessionColorResolution1440x1080_Binned = 3,
    STCaptureSessionColorResolution2592x1936 = 4,
    STCaptureSessionColorResolution2048x1536 = 5,
    STCaptureSessionColorResolution3264x2448 = 6,
    STCaptureSessionColorResolution4032x3024 = 7,

    // 16:9 mode.
    STCaptureSessionColorResolution1280x720_Binned = 8,
};

typedef NS_ENUM(NSInteger, STCaptureSessionDepthFrameResolution) {
    // 4:3 modes
    // Lower resolution that has been available historically since ST01
    STCaptureSessionDepthFrameResolution320x240 = 1,
    STCaptureSessionDepthFrameResolution640x480 = 2,
    // Higher resolution that become available since ST02
    STCaptureSessionDepthFrameResolution1280x960 = 3
};

typedef NS_ENUM(NSInteger, STCaptureSessionTrueDepthFrameResolution) {
    // 4:3 modes
    STCaptureSessionTrueDepthFrameResolution320x240 = 1,
    STCaptureSessionTrueDepthFrameResolution640x480 = 2
};

// These resolutions are used for AVCaptureDeviceTypeBuiltInLiDARDepthCamera (since iOS 15.4)
typedef NS_ENUM(NSInteger, STCaptureSessionLiDARFrameResolution) {
    // 4:3 modes
    STCaptureSessionLiDARFrameResolution320x240 = 1,

    // 16:9 modes
    STCaptureSessionLiDARFrameResolution320x180 = 2
};

/// Indicates the resolution that the user wants for IR frames, available since ST02.
typedef NS_ENUM(NSInteger, STCaptureSessionIrFrameResolution) {
    STCaptureSessionIrFrameResolution320x244 = 1,
    STCaptureSessionIrFrameResolution640x488 = 2,
    STCaptureSessionIrFrameResolution1280x976 = 3
};

/// Indicates the modes that the Structure Sensor can enter based on connection status.
typedef NS_ENUM(NSInteger, STCaptureSessionSensorMode) {
    /// The sensor has entered an unknown state
    STCaptureSessionSensorModeUnknown = 0,

    /// The sensor is not connected to the iOS device.
    STCaptureSessionSensorModeNotConnected = 1,

    // Anything above this means the sensor is connected
    /// The sensor is in standby, waiting to be woken up.
    STCaptureSessionSensorModeStandby,

    // WARNING: can't change the order of these, some code seems to check
    // if mode is > some of these values.

    /// The sensor is attempting to leave low-power mode and enter ready state.
    STCaptureSessionSensorModeWakingUp,

    /// The sensor is not in low-power mode and is prepared to stream frames.
    STCaptureSessionSensorModeReady,

    /// The battery on the sensor has been depleted and frames can no longer be streamed.
    STCaptureSessionSensorModeBatteryDepleted,
};

/// Indicates the modes that the iOS color camera can enter based on connection status or permissions.
typedef NS_ENUM(NSInteger, STCaptureSessionColorCameraMode) {
    /// The color camera is in an unknown state.
    /// Will be in this mode at startup, including when waiting for permission from the user
    STCaptureSessionColorCameraModeUnknown = 0,

    /// The color camera permission has been requested by the user and denied.
    /// The camera permission is required if you wish to stream color frames from an iOS camera.
    STCaptureSessionColorCameraModePermissionDenied = 1,

    /// The color camera is connected, prepared to stream, and has received the correct iOS permissions.
    STCaptureSessionColorCameraModeReady
};

/** Indicates whether the lens detector is enabled, and what state it operates under.

## See Also

 - ``STCaptureSessionDelegate/captureSession:onLensDetectorOutput:``
*/
typedef NS_ENUM(NSInteger, STLensDetectorState) {
    /** Indicates that the lens detector is off.

    While off, the lens detector will not operate, and ``STCaptureSessionDelegate/captureSession:onLensDetectorOutput:``
    will not trigger.
    */
    STLensDetectorOff = 0,

    /** Indicates that the lens detector is on, but does not update the lens type inside the capture session.

    While warning on mismatch, the lens detector will operate, and send detected
    lens events to ``STCaptureSessionDelegate/captureSession:onLensDetectorOutput:``.

    However, internally, the capture session will not change the lens type.
    */
    STLensDetectorWarnOnMismatch,

    /** Indicates that the lens detector is on, but does not update the lens type inside the capture session.

    While warning on mismatch, the lens detector will operate, and send detected
    lens events to ``STCaptureSessionDelegate/captureSession:onLensDetectorOutput:``.

    In addition to this, the lens detector will automatically set the lens type
    to whatever it detects the lens to be, if it does not match the current lens
    type, and if the detector detects a known lens state (i.e. does not return
    STDetectedLensUnsure).
    */
    STLensDetectorOn
};

/// Indicates the current status of detecting the lens.
typedef NS_ENUM(NSInteger, STDetectedLensStatus) {
    /// Initial state, specifies that the detector is still attempting to detect it's first state.
    STDetectedLensPerformingInitialDetection = -2,

    /// Indicates that the lens detector is unsure of whether a wide vision lens is attached or not.
    STDetectedLensUnsure = -1,

    /// Indicates that a wide vision lens has been detected by the lens detector.
    STDetectedLensWideVisionLens = 0,

    /// Indicates that no lens has been detected by the lens detector.
    STDetectedLensNormal
};

/** Indicates the lens type used by the capture session when finding depth<->color calibrations.

 These values can be set manually, or can be set automatically by the lens detector within the capture session.
*/
typedef NS_ENUM(NSInteger, STLens) {
    /// Indicates that no lens module is attached to the Structure Sensor bracket.
    STLensNormal = 0,

    /// Indicates that a wide-vision lens module is attached to the Structure Sensor bracket.
    STLensWideVision
};

/// Indicates the different iOS cameras that can be used for streaming.
typedef NS_ENUM(NSInteger, STCaptureSessionIOSCamera) {
    /// Indicates the iOS camera is disabled (no color).
    STCaptureSessionIOSCameraDisabled = 0,

    /// Indicates the default rear-facing iOS camera is used.
    STCaptureSessionIOSCameraBack = 1,

    /// Indicates the front-facing, fixed-focus iOS camera is used.
    STCaptureSessionIOSCameraFront = 2,

    /// Indicates the front-facing, iOS color camera and True Depth camera (on supported devices) are used.
    STCaptureSessionIOSCameraFrontAndTrueDepth = 3,

    /// Indicates the rear-facing, iOS color camera and LiDAR camera (on supported devices) are used.
    STCaptureSessionIOSCameraBackAndLiDAR = 5
};

/// Indicates the type of sample output by the capture session and sent to <[STCaptureSessionDelegate
/// captureSession:didOutputSample:type]>
typedef NS_ENUM(NSInteger, STCaptureSessionSampleType) {
    /// Indicates that an unknown sample type has been output.
    STCaptureSessionSampleTypeUnknown = 0,

    /// Indicates that an STDepthFrame type has been output.
    STCaptureSessionSampleTypeSensorDepthFrame,

    /// Indicates that an STInfraredFrame type has been output.
    STCaptureSessionSampleTypeSensorInfraredFrame,

    /// Indicates that a visible frame type has been output.
    STCaptureSessionSampleTypeSensorVisibleFrame,

    /** Indicates that a set of synchronized depth, color, or infrared frames have been output.

     Will return all the frames that were synchronized through FrameSync.
    */
    STCaptureSessionSampleTypeSynchronizedFrames,

    /// Indicates that an STColorFrame from the iOS color camera has been output.
    STCaptureSessionSampleTypeIOSColorFrame,

    /// Indicates that Apple CoreMotion data has been output.
    STCaptureSessionSampleTypeDeviceMotionData,

    /// Indicates that raw gyroscope data has been output.
    STCaptureSessionSampleTypeGyroData,

    /// Indicates that raw accelerometer data has been output.
    STCaptureSessionSampleTypeAccelData,
};

/** Indicates a set of instructions that a user of the capture session should act upon.

 All values can be combined together into a single integer that can express an
 array of options. To separate these options, one can use the bitwise-AND
 operator (&) to check for each warning.

 bool needToConnectSensor = _captureSession.userInstructions & STCaptureSessionUserInstructionNeedToConnectSensor;
*/
typedef NS_OPTIONS(NSUInteger, STCaptureSessionUserInstruction) {
    /** Indicates that no warnings are necessary, and that everything is working properly.
    This state is also what is returned before the capture session has been properly started.
    */
    STCaptureSessionUserInstructionNone = 0,

    /// Indicates that the Structure Sensor needs to be plugged into the iOS device
    STCaptureSessionUserInstructionNeedToConnectSensor = 1 << 0,

    /// Indicates that the Structure Sensor needs to be charged.
    STCaptureSessionUserInstructionNeedToChargeSensor = 1 << 1,

    /// Indicates that a device specific calibration could not be found for the
    /// given lens configuration, and Calibrator should be run for best results.
    STCaptureSessionUserInstructionNeedToRunCalibrator = 1 << 2,

    /// Indicates that the color camera cannot be started until the iOS camera permission is authorized for the app.
    STCaptureSessionUserInstructionNeedToAuthorizeColorCamera = 1 << 3,

    /** Indicates that the Structure Sensor needs to be plugged into the iOS device (optional).

    This flag will only be used if
    `kSTCaptureSessionToggleDepthSensorAutomaticallyKey` is set in the streaming
    configuration when ``STCaptureSession/startMonitoringWithOptions:`` is
    called.
    */
    STCaptureSessionUserInstructionOptionallyConnectStructureSensor = 1 << 4,

    /// Indicates that the sensor is waking up from low-power mode.
    STCaptureSessionUserInstructionSensorWakingUp = 1 << 5,

    /// Indicates that the sensor requires a firmware update.
    STCaptureSessionUserInstructionFirmwareUpdateRequired = 1 << 6,

    /// Indicates that the sensor has available firmware update.
    STCaptureSessionUserInstructionFirmwareUpdateAvailable = 1 << 7,
};

/// Indicates whether or not a charger is plugged into the active Structure Sensor.
typedef NS_OPTIONS(NSUInteger, STCaptureSessionSensorChargerState) {
    /// Indicates a charger is connected.
    STCaptureSessionSensorChargerStateConnected = 0,

    /// Indicates that a charger is not connected.
    STCaptureSessionSensorChargerStateDisconnected = 1 << 0,

    /// Indicates that the state of the charger is unknown (e.g. the sensor is not plugged in)
    STCaptureSessionSensorChargerStateUnknown = 1 << 1,
};

/// Indicates the capture preset for configurable sensor options on the Structure Sensor Mark II
typedef NS_ENUM(NSInteger, STCaptureSessionPreset) {
    /// ST02 range: 0.6-10+m, ST03 range: 0.6-10+m
    STCaptureSessionPresetDefault = 0,

    /// ST02 range: 0.4-1m, ST03 range: 0.4-1m
    STCaptureSessionPresetBodyScanning = 1,

    /// ST02 range: default, ST03 range: 0.6-10+m
    STCaptureSessionPresetOutdoor = 2,

    /// ST02 range: default, ST03 range: 0.56m - 12m+
    STCaptureSessionPresetRoomScanning = 3,

    /// ST02 range: 0.35-0.9m, the closest distance, ST03 range: 0.35m - 0.75m
    STCaptureSessionPresetCloseRange = 4,

    /// ST02 range: extended, with reduced resolution, ST03 range: 0.6-10+m
    STCaptureSessionPresetHybridMode = 5, //

    /// ST02 range: default, ST03 range: 0.27m-5m
    STCaptureSessionPresetDarkObjectScanning = 6, //

    /// ST02 range: 0.5-3m, ST03 range: 0.6-10+m
    STCaptureSessionPresetMediumRange = 7,

    /// ST02 range: 0.4-1m, ST03 range: 0.35m - 0.75m with increased resolution
    STCaptureSessionPresetBodyDetailed = 8,

    /// ST02 range: 0.35-0.9m, ST03 range: 0.26-2m
    STCaptureSessionPresetUltraClose = 9,

    /// ST02 range: default, ST03 range: 0.27-5m
    STCaptureSessionPresetSimplified = 10,
};

/// Indicates the focus mode to be used by the iOS color camera.
typedef NS_ENUM(NSInteger, STCaptureSessionIOSCameraFocusMode) {
    /// Invalid mode, cannot be used.
    STCaptureSessionIOSCameraFocusModeInvalid = -1,

    /// Auto focus is enabled
    STCaptureSessionIOSCameraFocusModeAuto = 0,

    /// Lock the focus position to a custom value in the range [0.0 1.0]
    STCaptureSessionIOSCameraFocusModeLockedToCustom = 1,

    /// Lock the focus position to its current position.
    STCaptureSessionIOSCameraFocusModeLockedToCurrent,

    /// Lock the focus position to the position it was in during calibration.
    STCaptureSessionIOSCameraFocusModeLockedToCalibratedValue,

    /// Do not attempt to modify the focus position, for iOS cameras that have fixed-focus lenses.
    STCaptureSessionIOSCameraFocusModeFixedFocusCamera,
};

/** Indicates the ISO mode to be used by the iOS color camera.

- Warning: Setting auto-exposure with a fixed ISO (locking to current or custom) is not supported. An exception will be
 thrown if this combination of parameters is used.
*/
typedef NS_ENUM(NSInteger, STCaptureSessionIOSCameraISOMode) {
    /// Invalid mode, cannot be used.
    STCaptureSessionIOSCameraISOModeInvalid = -1,

    /// ISO will be adjusted automatically
    STCaptureSessionIOSCameraISOModeAuto = 0,

    /// Lock the ISO to a custom ISO speed within the range [minISO maxISO] for the video device.
    STCaptureSessionIOSCameraISOModeLockedToCustom,

    /// Lock the ISO to its current speed.
    STCaptureSessionIOSCameraISOModeLockedToCurrent,
};

/** Indicates the Exposure mode to be used by the iOS color camera.

- Warning: Setting auto-exposure with a fixed ISO (locking to current or custom) is not supported. An exception will be
 thrown if this combination of parameters is used.
*/
typedef NS_ENUM(NSInteger, STCaptureSessionIOSCameraExposureMode) {
    /// Invalid mode, cannot be used
    STCaptureSessionIOSCameraExposureModeInvalid = -1,

    /// Continuous auto exposure will be used. Exposure will adjust automatically to scene conditions.
    STCaptureSessionIOSCameraExposureModeAuto = 0,

    /// Exposure will be locked to custom value (in seconds).
    STCaptureSessionIOSCameraExposureModeLockedToCustom,

    /// Exposure will be locked to its current value (in seconds).
    STCaptureSessionIOSCameraExposureModeLockedToCurrent,
};

/// Indicates the White Balance mode to be used by the iOS color camera.
typedef NS_ENUM(NSInteger, STCaptureSessionIOSCameraWhiteBalanceMode) {
    /// Invalid mode, cannot be used.
    STCaptureSessionIOSCameraWhiteBalanceModeInvalid = -1,

    /// White balance gains will be automatically adjusted by the system.
    STCaptureSessionIOSCameraWhiteBalanceModeAuto = 0,

    /// Lock the white balance gains to a custom set of red, green, and blue gain values.
    STCaptureSessionIOSCameraWhiteBalanceModeLockedToCustom,

    /// Lock the white balance gains to their current red, green, and blue gain values.
    STCaptureSessionIOSCameraWhiteBalanceModeLockedToCurrent,
};

/// Indicates the exposure mode setting used by the Structure Sensor Pro.
typedef NS_ENUM(NSInteger, STCaptureSessionSensorExposureMode) {
    /// Invalid mode, cannot be used.
    STCaptureSessionSensorExposureModeInvalid = -1,

    /// Auto exposure is enabled and will continuously function.
    STCaptureSessionSensorExposureModeAuto = 0,

    /// Auto exposure is disabled, and a custom exposure will be set.
    STCaptureSessionSensorExposureModeLockedToCustom = 1,

    /// Auto exposure is disabled, and exposure is locked to the current exposure value.
    STCaptureSessionSensorExposureModeLockedToCurrent = 2,

    /// Auto exposure will run for a short period, and then lock itself once stable.
    STCaptureSessionSensorExposureModeAutoAdjustAndLock = 3,

    /// Auto exposure is disabled, and the exposure is set to a custom value defined by the depth stream preset.
    STCaptureSessionSensorExposureModeDefinedByPreset = 4,
};

typedef NS_ENUM(NSInteger, STCaptureSessionSensorProjectorMode) {
    STCaptureSessionSensorProjectorModeOff = 0,
    STCaptureSessionSensorProjectorModeNormal = 1,
    STCaptureSessionSensorProjectorModeFast = 2,
};

typedef NS_ENUM(NSInteger, STCaptureSessionSensorAnalogGainMode) {
    /// Default (no) gain applied.
    STCaptureSessionSensorAnalogGainMode1_0 = 1,

    /// Analog gain of 2x
    STCaptureSessionSensorAnalogGainMode2_0 = 2,

    /// Analog gain of 4x
    STCaptureSessionSensorAnalogGainMode4_0 = 4,

    /// Analog gain of 8x
    STCaptureSessionSensorAnalogGainMode8_0 = 8,
};

/// Constants indicating the Structure Sensor streaming configuration.
typedef NS_ENUM(NSInteger, STStreamConfig) {
    /// Invalid stream configuration.
    STStreamConfigInvalid = -1,

    /// QVGA depth at 30 FPS.
    STStreamConfigDepth320x240 = 0,

    /// QVGA depth at 30 FPS, aligned to the color camera.
    STStreamConfigRegisteredDepth320x240_Deprecated_OnlyForPre2017Devices
        __deprecated_msg("Hardware registration is deprecated and will provide worse results on newer (>= 2017) "
                         "devices. Please use STStreamConfigDepth320x240 with registeredToColorFrame instead."),

    /// QVGA depth and infrared at 30 FPS.
    STStreamConfigDepth320x240AndInfrared320x248,

    /// QVGA infrared at 30 FPS.
    STStreamConfigInfrared320x248,

    /// VGA depth at 30 FPS.
    STStreamConfigDepth640x480,

    /// VGA infrared at 30 FPS.
    STStreamConfigInfrared640x488,

    /// VGA depth and infrared at 30 FPS.
    STStreamConfigDepth640x480AndInfrared640x488,

    /// VGA depth at 30 FPS, aligned to the color camera.
    STStreamConfigRegisteredDepth640x480_Deprecated_OnlyForPre2017Devices
        __deprecated_msg("Hardware registration is deprecated and will provide worse results on newer (>= 2017) "
                         "devices. Please use STStreamConfigDepth640x480 with registeredToColorFrame instead."),

    /// QVGA depth at 60 FPS. Note: frame sync is not supported with this mode.
    STStreamConfigDepth320x240_60FPS
};

/** Sensor Calibration Type

 Calibration types indicate whether a Structure Sensor + iOS device combination has no calibration, approximate
 calibration, or a device specific calibration from Calibrator.app.
 */
typedef NS_ENUM(NSInteger, STCalibrationType) {
    /// There is no calibration for Structure Sensor + iOS device combination.
    STCalibrationTypeNone = 0,

    /// There exists an approximate calibration Structure Sensor + iOS device combination.
    STCalibrationTypeApproximate,

    /// There exists a device specific calibration from Calibrator.app of this Structure Sensor + iOS device
    /// combination.
    STCalibrationTypeDeviceSpecific,
};

/// Indicates the graphic API to use for GPU acceleration in SLAM. Does not affect visualization.
/// Metal is not compatible with STSLAMManager
/// Note: This is a beta API
typedef NS_ENUM(NSInteger, STSlamGraphicApi) {
    /// OpenGL API
    STSlamGraphicApiOpenGL = 0,

    /// Metal API
    STSlamGraphicApiMetal = 1,
};
