/*
 Copyright © 2022 XRPro, LLC. All rights reserved.
 http://structure.io
 */

import CoreVideo
import Accelerate
import MetalKit
import Structure 
import StructureKit

struct RenderingOptions: OptionSet {
  let rawValue: Int
  static let colorFrame = RenderingOptions(rawValue: 1 << 0)
  static let depthOverlay = RenderingOptions(rawValue: 1 << 1)
  static let mesh = RenderingOptions(rawValue: 1 << 2)
  static let cube = RenderingOptions(rawValue: 1 << 3)
  static let anchor = RenderingOptions(rawValue: 1 << 4)
  static let arkitGeom = RenderingOptions(rawValue: 1 << 5)
  static let depthFrame = RenderingOptions(rawValue: 1 << 6)

  static let cubePlacement: RenderingOptions = [.colorFrame, .depthOverlay, .cube]
  static let scanning: RenderingOptions = [.colorFrame, .depthOverlay, .mesh, .cube]
  static let viewing: RenderingOptions = []
}

// Display related members.
//class MetalData: NSObject, MTKViewDelegate {
//  var renderingOption: RenderingOptions = RenderingOptions.cubePlacement
//  var arkitToWorld: simd_float4x4 = simd_float4x4.identity() {
//    didSet {
//      _imp.setARKitTransformation(arkitToWorld)
//    }
//  }
//
//  var meshRenderingAlpha: Float = 0.5
//  var depthCameraGLProjectionMatrix = float4x4.identity()
//
//  private var _cameraPosition = float4x4.identity()
//  private var _options: Options
//  private var _queue = DispatchQueue(label: "metal.visualization")
//  private var _imp: STKMetalRenderer
//
//  init(view: MTKView, device: MTLDevice, options: Options) {
//    _options = options
//    _imp = STKMetalRenderer(view: view, device: device, mesh: STMesh())
//    super.init()
//  }
//
//  func update(cameraPose: float4x4) { _queue.sync { [self] in _cameraPosition = cameraPose } }
//
//  func update(mesh: STMesh) { _queue.sync { [self] in _imp.setScanningMesh(mesh) } }
//
//  func update(colorFrame: STColorFrame) { _queue.sync { [self] in _imp.setColorFrame(colorFrame) } }
//
//  func update(depthFrame: STDepthFrame) {
//    _queue.sync { [self] in
//      _imp.setDepthFrame(depthFrame)
//      depthCameraGLProjectionMatrix = float4x4(depthFrame.glProjectionMatrix())
//    }
//  }
//
//  // MTKViewDelegate
//  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
//  }
//
//  func draw(in view: MTKView) {
//    if view.isHidden {
//      return
//    }
//    _queue.sync {
//      drawImp(in: view)
//    }
//  }
//
//  // transformation matrices
//  private var flip: Float { _options.useARKit ? 1 : -1 }
//  private var textureOrientation: float4x4 { float4x4.makeScale(flip, 1, 1) * float4x4.makeRotationZ(-flip * Float.pi / 2) }
//  private var cubeOrientation: float4x4 { float4x4.makeScale(flip, 1, 1) * float4x4.makeRotationZ(-Float.pi / 2) }
//  private var meshOrientation: float4x4 { float4x4.makeScale(1, flip, 1) * float4x4.makeRotationZ(-flip * Float.pi / 2) }
//  private var arkitOrientation: float4x4 { float4x4.makeRotationZ(Float.pi / 2) }
//
//  private func drawImp(in view: MTKView) {
//    _imp.adjustCubeSize(simd_float3(_options.volumeSizeInMeters))
//
//    _imp.startRendering()
//    if renderingOption.contains(.colorFrame) {
//      _imp.renderColorFrame(orientation: textureOrientation)
//    }
//
//    if renderingOption.contains(.depthFrame) {
//      let maxDistMM: Float = (_cameraPosition * simd_float4(0, 0, 0, 1)).z * 1000
//      let minDistMM: Float = max(0, maxDistMM - _options.volumeSizeInMeters.z * 1000)
//      _imp.renderDepthFrame(orientation: textureOrientation, range: simd_float2(minDistMM, maxDistMM))
//    }
//
//    if renderingOption.contains(.cube) {
//      _imp.renderCubeOutline(cameraPose: _cameraPosition, occlusionTest: _options.drawCubeWithOccluson, orientation: cubeOrientation, drawTriad: false)
//    }
//
//    if renderingOption.contains(.mesh) {
//      _imp.renderScanningMesh(cameraPose: _cameraPosition, meshOrientation: meshOrientation, color: vector_float4(1, 1, 1, meshRenderingAlpha), style: .solid)
//    }
//
//    if renderingOption.contains(.depthOverlay) {
//      if renderingOption == .cubePlacement {
//        _imp.renderHighlightedDepth(cameraPose: _cameraPosition, alpha: 0.5, textureOrientation: textureOrientation)
//      }
//    }
//
//    if _options.useARKit && _options.useARKitTracking && renderingOption.contains(.arkitGeom) {
//      _imp.renderARKitMesh(cameraPose: _cameraPosition, orientation: arkitOrientation)
//    }
//
//    _imp.presentDrawable()
//  }
//}

extension ViewController {
  func setupMetal() {

    let device = MTLCreateSystemDefaultDevice()!
    mtkView.device = device
    mtkView.colorPixelFormat = .bgra8Unorm
    mtkView.depthStencilPixelFormat = .depth32Float
    _metalData = MetalData(view: mtkView, device: device, options: _options)

    mtkView.delegate = _metalData

    _scene = STScene()
  }
}
