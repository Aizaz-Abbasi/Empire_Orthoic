/*
 Copyright © 2022 XRPro, LLC. All rights reserved.
 http://structure.io
 */

import Foundation
import MetalKit
import GLKit
import Metal
import QuartzCore
import simd

import StructureKit
import Structure 

typealias Float3 = SIMD3<Float>

extension STMesh {
  func bbox() -> (Float3, Float3) {
    var minPoint = Float3(Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude)
    var maxPoint = -Float3(Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude, Float.greatestFiniteMagnitude)

    let vertices = self.meshVertices(0)!
    for vItr in 0..<Int(self.number(ofMeshVertices: 0)) {

      minPoint.x = min(vertices[vItr].x, minPoint.x)
      minPoint.y = min(vertices[vItr].y, minPoint.y)
      minPoint.z = min(vertices[vItr].z, minPoint.z)

      maxPoint.x = max(vertices[vItr].x, maxPoint.x)
      maxPoint.y = max(vertices[vItr].y, maxPoint.y)
      maxPoint.z = max(vertices[vItr].z, maxPoint.z)
    }
    return (minPoint, maxPoint)
  }
}

class RendererMeshMetal: NSObject, MTKViewDelegate {
  enum Modes {
    case lightedGrey
    case xray
    case vertexColor
    case texture
  }

  var viewpointController: ViewpointController!
  var mode: Modes = .lightedGrey

  private var mtkView: MTKView
  private var device: MTLDevice
  private var commandQueue: MTLCommandQueue

  private var mesh: STKMeshBuffers
  private var viewportSize: CGSize = CGSize()

  private var solid: STKMeshRendererSolid
  private var wirefrane: STKMeshRendererWireframe
  private var vertexColor: STKMeshRendererColor
  private var textureShader: STKMeshRendererTexture

  init(view: MTKView, device: MTLDevice, mesh: STMesh, size: CGSize) {
    viewportSize = size
    mtkView = view
    self.device = device
    self.mesh = STKMeshBuffers(device)
    self.mesh.updateMesh(mesh)

    // Create the command queue
    commandQueue = device.makeCommandQueue()!

    solid = STKMeshRendererSolid(view: view, device: device)
    wirefrane = STKMeshRendererWireframe(view: view, device: device)
    vertexColor = STKMeshRendererColor(view: view, device: device)
    textureShader = STKMeshRendererTexture(view: view, device: device)
    super.init()
  }

  func updateMesh(mesh: STMesh) { self.mesh.updateMesh(mesh) }

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) { viewportSize = size }

  /// Called whenever the view needs to render a frame.
  func draw(in view: MTKView) {
    guard let drawable = view.currentDrawable, !view.isHidden else { return }

    let worldModelMatrix = viewpointController.currentGLModelViewMatrix()
    let projectionMatrix = viewpointController.currentGLProjectionMatrix()

    let commandBuffer = commandQueue.makeCommandBuffer()!
    let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: mtkView.currentRenderPassDescriptor!)!

    switch mode {
    case .lightedGrey:
      solid.render(commandEncoder, node: mesh, worldModelMatrix: worldModelMatrix, projectionMatrix: projectionMatrix)
    case .xray:
      wirefrane.render(commandEncoder, node: mesh, worldModelMatrix: worldModelMatrix, projectionMatrix: projectionMatrix)
    case .vertexColor:
      vertexColor.render(commandEncoder, node: mesh, worldModelMatrix: worldModelMatrix, projectionMatrix: projectionMatrix)
    case .texture:
      textureShader.render(commandEncoder, node: mesh, worldModelMatrix: worldModelMatrix, projectionMatrix: projectionMatrix)
    }

    commandEncoder.endEncoding()
    commandBuffer.present(drawable)
    commandBuffer.commit()

  }
}
