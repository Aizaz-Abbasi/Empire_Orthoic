/*
 Copyright © 2022 XRPro, LLC. All rights reserved.
 http://structure.io
 */

// MARK: options
enum OptionId: String {
  case zero = ""

  case cubeGroup = "CUBE"
  case streamingGroup = "STREAMING"
  case slamGroup = "SLAM"
  case trackerGroup = "TRACKER"
  case mapperGroup = "MAPPER"
  case postprocessGroup = "POSTPROCESS"
  case applicationGroup = "APPLICATION"
  case boundingBoxGroup = "BOUNDING BOX"

  case holeFillingAlgo = "Hole Filling"
  case texturingAlgo = "Texturing"

  case depthResolution = "Depth Resolution"
  case arKit = "Use ARKit (Beta)"
  case highResolutionColor = "High Resolution Color"
  case autoExposure = "IR Auto Exposure (Mark II only)"
  case manualExposure = "IR Manual Exposure (Mark II only)"
  case analogGain = "IR Analog Gain (Mark II only)"
  case streamPreset = "Depth Stream Preset (Mark II only)"

  case colorResolution = "Color Resolution"
  case fixedBox = "Fixed Box"

  case slamType = "SLAM Option"
  case maxRotation = "Max Rotation For Keyframe"

  case trackerType = "Tracker Type"
  case trackingMode = "Mode"

  case highResolutionMesh = "High Resolution Mesh"
  case improvedMapper = "Improved Mapper"
  case voxelSize = "Voxel Size (mm)"
  case voxelSizeType = "Voxel Size Type"

  case showInfo = "Show Debug Info"
  case cubeOcclusion = "Cube Occlusion"

  case recordOcc = "Record OCC"
  case scanType = "Scan Type"
  case footSize = "Foot Size"
}

class OptionBase {
  var id: OptionId = .zero
  var name: String { return id.rawValue }
  var description: String { return id.rawValue }

  init(id: OptionId) {
    self.id = id
  }
}

class OptionBool: OptionBase {
  var callback: (OptionId, Bool) -> Void
  var val: Bool = false {
    didSet { callback(self.id, self.val) }
  }

  init(id: OptionId, val: Bool, onChange: @escaping (OptionId, Bool) -> Void) {
    self.callback = onChange
    self.val = val
    super.init(id: id)
  }
}

class OptionEnum: OptionBase {
  enum Style {
    case segmented
    case dropDown
  }
  var callback: (OptionId, [String], Int) -> Void
  var val: Int = -1 {
    didSet { callback(self.id, self.map, self.val) }
  }
  var map: [String] = []
  var style: Style

  init(id: OptionId, map: [String], val: Int, style: Style = Style.segmented, onChange: @escaping (OptionId, [String], Int) -> Void) {
    assert(val < map.count && val >= 0)
    self.callback = onChange
    self.map = map
    self.val = val
    self.style = style
    super.init(id: id)
  }
}

class OptionFloat: OptionBase {
  enum Style {
    case slider
  }
  var callback: (OptionId, Float) -> Void
  var style: Style
  var min: Float
  var max: Float
  var val: Float {
    didSet { callback(self.id, self.val) }
  }
  var minText: String
  var maxText: String

  init(id: OptionId,
       val: Float,
       min: Float = -Float.greatestFiniteMagnitude,
       max: Float = Float.greatestFiniteMagnitude,
       minText: String = "",
       maxText: String = "",
       style: Style = Style.slider, onChange: @escaping (OptionId, Float) -> Void) {
    assert(min <= val && val <= max)
    self.callback = onChange
    self.val = val
    self.style = style
    self.min = min
    self.max = max
    self.minText = minText
    self.maxText = maxText
    super.init(id: id)
  }
}

class OptionsGroup {

  var id: OptionId
  var title: String { return id.rawValue }
  var options: [OptionBase] { optionsArray }
  private var optionsMap: [OptionId: OptionBase] = [:]
  private var optionsArray: [OptionBase] = []

  init(id: OptionId = .zero) {
    self.id = id
  }

  func bool(_ id: OptionId) -> OptionBool? { return optionsMap[id] as? OptionBool }

  func enumeration(_ id: OptionId) -> OptionEnum? { return optionsMap[id] as? OptionEnum }

  func float(_ id: OptionId) -> OptionFloat? { return optionsMap[id] as? OptionFloat }

  @discardableResult
  func addBool(id: OptionId, val: Bool, onChange: @escaping (OptionId, Bool) -> Void) -> OptionsGroup {
    let opt = OptionBool(id: id, val: val, onChange: onChange)
    optionsMap[id] = opt
    optionsArray.append(opt)
    return self
  }

  @discardableResult
  func addEnum(id: OptionId, map: [String], val: Int, style: OptionEnum.Style = .segmented, onChange: @escaping (OptionId, [String], Int) -> Void) -> OptionsGroup {
    let opt = OptionEnum(id: id, map: map, val: val, style: style, onChange: onChange)
    optionsMap[id] = opt
    optionsArray.append(opt)
    return self
  }

  @discardableResult
  func addFloat(
    id: OptionId,
    val: Float,
    min: Float,
    max: Float,
    minText: String = "",
    maxText: String = "",
    style: OptionFloat.Style = .slider,
    onChange: @escaping (OptionId, Float) -> Void
  ) -> OptionsGroup {
    let opt = OptionFloat(id: id, val: val, min: min, max: max, minText: minText, maxText: maxText, style: style, onChange: onChange)
    optionsMap[id] = opt
    optionsArray.append(opt)
    return self
  }
}

class OptionsSet {
  var groups: [OptionsGroup] = []

  func group(_ id: OptionId) -> OptionsGroup? {
    return groups.first(where: { $0.id == id })
  }

  func bool(forKey id: OptionId, default def: Bool = false) -> Bool {
    for group in groups {
      if let opt = group.bool(id) {
        return opt.val
      }
    }
    return def
  }

  func float(forKey id: OptionId, default def: Float = 0.0) -> Float {
    for group in groups {
      if let opt = group.float(id) {
        return opt.val
      }
    }
    return def
  }

  func integer(forKey id: OptionId, default def: Int = 0) -> Int {
    for group in groups {
      if let opt = group.enumeration(id) {
        return opt.val
      }
    }
    return def
  }

}
